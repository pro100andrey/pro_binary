import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import '../binary_reader.dart';

/// Exception thrown when [StreamBinaryReader] does not have enough data
/// to complete a read operation.
class NotEnoughDataException implements Exception {
  /// Creates a new [NotEnoughDataException].
  const NotEnoughDataException(this.required, this.available);

  /// The number of bytes required to complete the operation.
  final int required;

  /// The number of bytes currently available in the reader.
  final int available;

  @override
  String toString() =>
      'NotEnoughDataException: required $required bytes, but only '
      '$available available.';
}

/// A reader designed for asynchronous streaming data that spans multiple
/// chunks.
///
/// Unlike [BinaryReader], which requires a single contiguous [Uint8List]
/// buffer, [StreamBinaryReader] manages a queue of chunks. It optimizes reads
/// that fall entirely within a single chunk (zero-copy) and transparently
/// handles reads that cross chunk boundaries.
///
/// It supports a transactional model ([bookmark], [rollback], [commit]) which
/// is essential for stream parsing when a message might be incomplete.
extension type StreamBinaryReader._(_StreamReaderState _s) {
  /// Creates a new [StreamBinaryReader].
  StreamBinaryReader() : this._(_StreamReaderState());

  /// The total number of unread bytes currently available across all chunks.
  int get availableBytes => _s.availableBytes;

  /// Adds a new chunk of data to the reader.
  void addChunk(List<int> bytes) {
    final chunk = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    if (chunk.isEmpty) {
      return;
    }

    _s.chunks.add(chunk);
    _s.availableBytes += chunk.length;

    if (_s.currentReader == null) {
      final relativeIndex = _s.currentAbsoluteIndex - _s.queueStartIndex;
      if (relativeIndex >= 0 && relativeIndex < _s.chunks.length) {
        _s.currentReader = BinaryReader(_s.chunks.elementAt(relativeIndex));
      }
    }
  }

  /// Creates a checkpoint of the current reader state.
  ///
  /// Use this before attempting to read a message that might be incomplete.
  /// If reading fails (e.g., due to [NotEnoughDataException]), you can call
  /// [rollback] to restore the state and wait for more data.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void bookmark() {
    if (_s.bookmarkCount >= _s.bookmarkAbsoluteIndex.length) {
      _s._growBookmarks();
    }

    final count = _s.bookmarkCount;
    _s.bookmarkAbsoluteIndex[count] = _s.currentAbsoluteIndex;
    _s.bookmarkReaderOffset[count] = _s.currentReader?.offset ?? 0;
    _s.bookmarkAvailableBytes[count] = _s.availableBytes;
    _s.bookmarkCount++;
  }

  /// Restores the reader to the state of the last [bookmark].
  ///
  /// This removes the last bookmark from the stack.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void rollback() {
    if (_s.bookmarkCount == 0) {
      throw StateError('No bookmark to rollback to');
    }

    _s.bookmarkCount--;
    final count = _s.bookmarkCount;
    final absIndex = _s.bookmarkAbsoluteIndex[count];
    final readerOffset = _s.bookmarkReaderOffset[count];
    final availableBytes = _s.bookmarkAvailableBytes[count];

    _s.currentAbsoluteIndex = absIndex;
    _s.availableBytes = availableBytes;

    if (_s.chunks.isNotEmpty) {
      final relativeIndex = absIndex - _s.queueStartIndex;
      final targetChunk = _s.chunks.elementAt(relativeIndex);
      final cr = _s.currentReader;
      if (cr != null) {
        cr
          ..rebind(targetChunk)
          ..seek(readerOffset);
      } else {
        _s.currentReader = BinaryReader(targetChunk)..seek(readerOffset);
      }
    } else {
      _s.currentReader = null;
    }
  }

  /// Removes the last [bookmark] without restoring the state.
  ///
  /// Call this when a message has been successfully and fully parsed.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void commit() {
    if (_s.bookmarkCount == 0) {
      throw StateError('No bookmark to commit');
    }

    _s.bookmarkCount--;
    _prune();
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void _advanceChunk() {
    _s.currentAbsoluteIndex++;
    if (_s.bookmarkCount == 0) {
      _s.chunks.removeFirst();
      _s.queueStartIndex++;
    }

    final relativeIndex = _s.currentAbsoluteIndex - _s.queueStartIndex;
    if (relativeIndex < _s.chunks.length) {
      _s.currentReader!.rebind(_s.chunks.elementAt(relativeIndex));
    } else {
      _s.currentReader = null;
    }
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void _prune() {
    final minNeeded = _s.bookmarkCount == 0
        ? _s.currentAbsoluteIndex
        : _s.bookmarkAbsoluteIndex[0];

    while (_s.queueStartIndex < minNeeded) {
      _s.chunks.removeFirst();
      _s.queueStartIndex++;
    }
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void _checkAvailable(int length) {
    if (_s.availableBytes < length) {
      throw NotEnoughDataException(length, _s.availableBytes);
    }
  }

  /// Reads an 8-bit unsigned integer (0-255).
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int readUint8() {
    _checkAvailable(1);
    final cr = _s.currentReader!;
    final val = cr.readUint8();
    _s.availableBytes -= 1;
    if (cr.availableBytes == 0) {
      _advanceChunk();
    }
    return val;
  }

  /// Reads an 8-bit signed integer (-128 to 127).
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int readInt8() {
    _checkAvailable(1);
    final cr = _s.currentReader!;
    final val = cr.readInt8();
    _s.availableBytes -= 1;
    if (cr.availableBytes == 0) {
      _advanceChunk();
    }
    return val;
  }

  /// Reads a boolean value (1 byte).
  ///
  /// A byte value of 0 is interpreted as `false`, any non-zero value as `true`.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  bool readBool() {
    _checkAvailable(1);
    final cr = _s.currentReader!;
    final val = cr.readUint8();
    _s.availableBytes -= 1;
    if (cr.availableBytes == 0) {
      _advanceChunk();
    }

    return val != 0;
  }

  /// Reads a 16-bit unsigned integer.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int readUint16([Endian endian = Endian.big]) {
    _checkAvailable(2);
    final cr = _s.currentReader!;
    if (cr.availableBytes >= 2) {
      final val = cr.readUint16(endian);
      _s.availableBytes -= 2;
      if (cr.availableBytes == 0) {
        _advanceChunk();
      }
      return val;
    }
    return _readCrossChunk(2, (data) => data.getUint16(0, endian));
  }

  /// Reads a 16-bit signed integer.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int readInt16([Endian endian = Endian.big]) {
    _checkAvailable(2);
    final cr = _s.currentReader!;
    if (cr.availableBytes >= 2) {
      final val = cr.readInt16(endian);
      _s.availableBytes -= 2;
      if (cr.availableBytes == 0) {
        _advanceChunk();
      }
      return val;
    }
    return _readCrossChunk(2, (data) => data.getInt16(0, endian));
  }

  /// Reads a 32-bit unsigned integer.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int readUint32([Endian endian = Endian.big]) {
    _checkAvailable(4);
    final cr = _s.currentReader!;
    if (cr.availableBytes >= 4) {
      final val = cr.readUint32(endian);
      _s.availableBytes -= 4;
      if (cr.availableBytes == 0) {
        _advanceChunk();
      }
      return val;
    }
    return _readCrossChunk(4, (data) => data.getUint32(0, endian));
  }

  /// Reads a 32-bit signed integer.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int readInt32([Endian endian = Endian.big]) {
    _checkAvailable(4);
    final cr = _s.currentReader!;
    if (cr.availableBytes >= 4) {
      final val = cr.readInt32(endian);
      _s.availableBytes -= 4;
      if (cr.availableBytes == 0) {
        _advanceChunk();
      }
      return val;
    }
    return _readCrossChunk(4, (data) => data.getInt32(0, endian));
  }

  /// Reads a 64-bit unsigned integer.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int readUint64([Endian endian = Endian.big]) {
    _checkAvailable(8);
    final cr = _s.currentReader!;
    if (cr.availableBytes >= 8) {
      final val = cr.readUint64(endian);
      _s.availableBytes -= 8;
      if (cr.availableBytes == 0) {
        _advanceChunk();
      }
      return val;
    }
    return _readCrossChunk(8, (data) => data.getUint64(0, endian));
  }

  /// Reads a 64-bit signed integer.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int readInt64([Endian endian = Endian.big]) {
    _checkAvailable(8);
    final cr = _s.currentReader!;
    if (cr.availableBytes >= 8) {
      final val = cr.readInt64(endian);
      _s.availableBytes -= 8;
      if (cr.availableBytes == 0) {
        _advanceChunk();
      }
      return val;
    }
    return _readCrossChunk(8, (data) => data.getInt64(0, endian));
  }

  /// Reads a 32-bit floating-point number.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  double readFloat32([Endian endian = Endian.big]) {
    _checkAvailable(4);
    final cr = _s.currentReader!;
    if (cr.availableBytes >= 4) {
      final val = cr.readFloat32(endian);
      _s.availableBytes -= 4;
      if (cr.availableBytes == 0) {
        _advanceChunk();
      }
      return val;
    }
    return _readCrossChunk(4, (data) => data.getFloat32(0, endian));
  }

  /// Reads a 64-bit floating-point number.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  double readFloat64([Endian endian = Endian.big]) {
    _checkAvailable(8);
    final cr = _s.currentReader!;
    if (cr.availableBytes >= 8) {
      final val = cr.readFloat64(endian);
      _s.availableBytes -= 8;
      if (cr.availableBytes == 0) {
        _advanceChunk();
      }
      return val;
    }
    return _readCrossChunk(8, (data) => data.getFloat64(0, endian));
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  T _readCrossChunk<T>(int length, T Function(ByteData) parser) {
    final bytes = readBytes(length);
    final data = ByteData.sublistView(bytes);
    return parser(data);
  }

  /// Reads an unsigned variable-length integer (VarInt format).
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int readVarUint() {
    final cr = _s.currentReader;
    if (cr != null && cr.availableBytes >= 10) {
      final before = cr.availableBytes;
      final value = cr.readVarUint();
      final readLen = before - cr.availableBytes;
      _s.availableBytes -= readLen;
      if (cr.availableBytes == 0) {
        _advanceChunk();
      }
      return value;
    }

    var result = 0;
    var shift = 0;
    for (var i = 0; i < 10; i++) {
      final byte = readUint8();
      result |= (byte & 0x7f) << shift;
      if ((byte & 0x80) == 0) {
        return result;
      }
      shift += 7;
    }
    throw const FormatException('VarInt is too long (more than 10 bytes)');
  }

  /// Reads a signed variable-length integer (ZigZag encoding).
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int readVarInt() {
    final v = readVarUint();
    return (v >>> 1) ^ -(v & 1);
  }

  /// Reads a sequence of bytes.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  Uint8List readBytes(int length) {
    if (length < 0) {
      throw RangeError.value(length, 'length', 'Length must be non-negative');
    }
    if (length == 0) {
      return _emptyBytes;
    }

    _checkAvailable(length);

    final cr = _s.currentReader!;
    if (cr.availableBytes >= length) {
      final bytes = cr.readBytes(length);
      _s.availableBytes -= length;
      if (cr.availableBytes == 0) {
        _advanceChunk();
      }

      return bytes;
    }

    final result = Uint8List(length);
    var remaining = length;
    var resultOffset = 0;

    while (remaining > 0) {
      final chunkReader = _s.currentReader!;
      final chunkAvailable = chunkReader.availableBytes;

      if (chunkAvailable >= remaining) {
        final bytes = chunkReader.readBytes(remaining);
        result.setRange(resultOffset, resultOffset + remaining, bytes);
        _s.availableBytes -= remaining;
        if (chunkReader.availableBytes == 0) {
          _advanceChunk();
        }
        break;
      } else {
        if (chunkAvailable > 0) {
          final bytes = chunkReader.readBytes(chunkAvailable);
          result.setRange(resultOffset, resultOffset + chunkAvailable, bytes);
          resultOffset += chunkAvailable;
          remaining -= chunkAvailable;
          _s.availableBytes -= chunkAvailable;
        }
        _advanceChunk();
      }
    }
    return result;
  }

  /// Reads all currently available bytes across all chunks.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  Uint8List readRemainingBytes() => readBytes(_s.availableBytes);

  /// Reads a length-prefixed byte array.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  Uint8List readVarBytes() {
    final length = readVarUint();
    return readBytes(length);
  }

  /// Reads a UTF-8 encoded string of the specified byte length.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  String readString(int length, {bool allowMalformed = false}) {
    if (length < 0) {
      throw RangeError.value(length, 'length', 'Length must be non-negative');
    }
    if (length == 0) {
      return '';
    }
    _checkAvailable(length);

    final cr = _s.currentReader!;
    if (cr.availableBytes >= length) {
      final value = cr.readString(length, allowMalformed: allowMalformed);
      _s.availableBytes -= length;
      if (cr.availableBytes == 0) {
        _advanceChunk();
      }
      return value;
    }

    final bytes = readBytes(length);
    return utf8.decode(bytes, allowMalformed: allowMalformed);
  }

  /// Reads a length-prefixed UTF-8 encoded string.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  String readVarString({bool allowMalformed = false}) {
    final length = readVarUint();
    return readString(length, allowMalformed: allowMalformed);
  }

  /// Advances the read position by the specified number of bytes.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void skip(int length) {
    if (length < 0) {
      throw RangeError.value(length, 'length', 'Length must be non-negative');
    }
    _checkAvailable(length);
    var remaining = length;

    while (remaining > 0) {
      final chunkAvailable = _s.currentReader!.availableBytes;
      if (chunkAvailable >= remaining) {
        _s.currentReader!.skip(remaining);
        _s.availableBytes -= remaining;
        if (_s.currentReader!.availableBytes == 0) {
          _advanceChunk();
        }
        break;
      } else {
        remaining -= chunkAvailable;
        _s.availableBytes -= chunkAvailable;
        _advanceChunk();
      }
    }
  }

  /// Checks if there are at least [length] bytes available to read.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  bool hasBytes(int length) {
    if (length < 0) {
      throw RangeError.value(length, 'length', 'Length must be non-negative');
    }
    return _s.availableBytes >= length;
  }
}

/// Internal state holder for [StreamBinaryReader].
final class _StreamReaderState {
  _StreamReaderState()
    : availableBytes = 0,
      currentAbsoluteIndex = 0,
      queueStartIndex = 0,
      chunks = ListQueue<Uint8List>(),
      bookmarkAbsoluteIndex = Int32List(16),
      bookmarkReaderOffset = Int32List(16),
      bookmarkAvailableBytes = Int32List(16),
      bookmarkCount = 0;

  final ListQueue<Uint8List> chunks;

  int currentAbsoluteIndex;
  int queueStartIndex;
  int availableBytes;
  BinaryReader? currentReader;

  // Zero-allocation bookmarks using parallel arrays
  Int32List bookmarkAbsoluteIndex;
  Int32List bookmarkReaderOffset;
  Int32List bookmarkAvailableBytes;
  int bookmarkCount;

  @pragma('vm:never-inline')
  void _growBookmarks() {
    final newCapacity = bookmarkAbsoluteIndex.length * 2;
    final newAbsIndex = Int32List(newCapacity);
    final newOffset = Int32List(newCapacity);
    final newAvail = Int32List(newCapacity);

    newAbsIndex.setRange(0, bookmarkCount, bookmarkAbsoluteIndex);
    newOffset.setRange(0, bookmarkCount, bookmarkReaderOffset);
    newAvail.setRange(0, bookmarkCount, bookmarkAvailableBytes);

    bookmarkAbsoluteIndex = newAbsIndex;
    bookmarkReaderOffset = newOffset;
    bookmarkAvailableBytes = newAvail;
  }
}

/// Empty bytes cache
final _emptyBytes = Uint8List(0);
