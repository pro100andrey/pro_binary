import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../binary_reader.dart';
import '../constants.dart';
import '../internal.dart';
import 'transactional_reader.dart';

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
extension type StreamBinaryReader._(_StreamReaderState _s)
    implements TransactionalReader<List<int>> {
  /// Creates a new [StreamBinaryReader].
  StreamBinaryReader() : this._(_StreamReaderState());

  /// The total number of unread bytes currently available across all chunks.
  @redeclare
  int get availableBytes => _s.availableBytes;

  /// Adds a new chunk of data to the reader.
  ///
  /// **Performance Tip:** For maximum performance, it is highly recommended to
  /// pass a [Uint8List]. If a standard `List<int>` is provided, it will be
  /// copied into a new [Uint8List] internally, which incurs a performance cost.
  ///
  /// Most streams from `dart:io` (like `File.openRead` or `Socket`) yield
  /// [Uint8List] even though they are typed as `Stream<List<int>>`.
  @redeclare
  void addChunk(List<int> bytes) => _s.addChunk(bytes);

  /// Creates a checkpoint of the current reader state.
  ///
  /// Use this before attempting to read a message that might be incomplete.
  /// If reading fails (e.g., due to [NotEnoughDataException]), you can call
  /// [rollback] to restore the state and wait for more data.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @redeclare
  void bookmark() => _s.bookmark();

  /// Restores the reader to the state of the last [bookmark].
  ///
  /// This removes the last bookmark from the stack.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @redeclare
  void rollback() => _s.rollback();

  /// Removes the last [bookmark] without restoring the state.
  ///
  /// Call this when a message has been successfully and fully parsed.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @redeclare
  void commit() => _s.commit();

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void _advanceChunk() => _s.advanceChunk();

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void _checkAvailable(int length) {
    if (_s.availableBytes < length) {
      throw NotEnoughDataException(length, _s.availableBytes);
    }
  }

  /// Reads an 8-bit unsigned integer (0-255).
  ///
  /// Throws [NotEnoughDataException] if fewer than 1 byte is available.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int readUint8() {
    _checkAvailable(1);
    // Invariant: availableBytes > 0 implies currentReader != null
    final cr = _s.currentReader!;
    final val = cr.readUint8();

    _s.availableBytes -= 1;

    if (cr.availableBytes == 0) {
      _advanceChunk();
    }

    return val;
  }

  /// Reads an 8-bit signed integer (-128 to 127).
  ///
  /// Throws [NotEnoughDataException] if fewer than 1 byte is available.
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
  ///
  /// Throws [NotEnoughDataException] if fewer than 1 byte is available.
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
  ///
  /// Throws [NotEnoughDataException] if fewer than 2 bytes are available.
  ///
  /// [endian] specifies byte order (defaults to big-endian).
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
  ///
  /// Throws [NotEnoughDataException] if fewer than 2 bytes are available.
  ///
  /// [endian] specifies byte order (defaults to big-endian).
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
  ///
  /// Throws [NotEnoughDataException] if fewer than 4 bytes are available.
  ///
  /// [endian] specifies byte order (defaults to big-endian).
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
  ///
  /// Throws [NotEnoughDataException] if fewer than 4 bytes are available.
  ///
  /// [endian] specifies byte order (defaults to big-endian).
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
  ///
  /// Throws [NotEnoughDataException] if fewer than 8 bytes are available.
  ///
  /// [endian] specifies byte order (defaults to big-endian).
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
  ///
  /// Throws [NotEnoughDataException] if fewer than 8 bytes are available.
  ///
  /// [endian] specifies byte order (defaults to big-endian).
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
  ///
  /// Throws [NotEnoughDataException] if fewer than 4 bytes are available.
  ///
  /// [endian] specifies byte order (defaults to big-endian).
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
  ///
  /// Throws [NotEnoughDataException] if fewer than 8 bytes are available.
  ///
  /// [endian] specifies byte order (defaults to big-endian).
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
    if (length <= 8) {
      final scratch = _s.scratchBuffer;
      var remaining = length;
      var scratchOffset = 0;

      while (remaining > 0) {
        final cr = _s.currentReader!;
        final chunkAvailable = cr.availableBytes;
        final readLen = chunkAvailable >= remaining
            ? remaining
            : chunkAvailable;

        if (readLen > 0) {
          final chunk = _s.currentChunk!;
          var offset = cr.offset;
          for (var i = 0; i < readLen; i++) {
            scratch[scratchOffset++] = chunk[offset++];
          }

          cr.skip(readLen);
          _s.availableBytes -= readLen;
          remaining -= readLen;
        }

        if (cr.availableBytes == 0) {
          _advanceChunk();
        }
      }

      return parser(_s.scratchData);
    }

    final bytes = readBytes(length);
    final data = ByteData.sublistView(bytes);

    return parser(data);
  }

  /// Reads an unsigned variable-length integer (VarInt format).
  ///
  /// Throws [NotEnoughDataException] if fewer than 1 byte is available.
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
      if (_s.availableBytes == 0) {
        throw const NotEnoughDataException(1, 0);
      }
      final cr = _s.currentReader!;
      final byte = _s.currentChunk![cr.offset];
      cr.skip(1);
      _s.availableBytes -= 1;
      if (cr.availableBytes == 0) {
        _advanceChunk();
      }

      result |= (byte & 0x7f) << shift;
      if ((byte & 0x80) == 0) {
        return result;
      }

      shift += 7;
    }

    throw const FormatException('VarInt is too long (more than 10 bytes)');
  }

  /// Reads a signed variable-length integer (ZigZag encoding).
  ///
  /// Throws [NotEnoughDataException] if fewer than 1 byte is available.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int readVarInt() {
    final v = readVarUint();

    return (v >>> 1) ^ -(v & 1);
  }

  /// Reads a sequence of bytes.
  ///
  /// Throws [NotEnoughDataException] if fewer than [length] bytes are
  /// available.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  Uint8List readBytes(int length) {
    if (length < 0) {
      throw RangeError.value(length, 'length', 'Length must be non-negative');
    }

    if (length == 0) {
      return emptyUintList_;
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
      final readLen = chunkAvailable >= remaining ? remaining : chunkAvailable;

      if (readLen > 0) {
        result.setRange(
          resultOffset,
          resultOffset + readLen,
          _s.currentChunk!,
          chunkReader.offset,
        );

        chunkReader.skip(readLen);
        _s.availableBytes -= readLen;

        resultOffset += readLen;
        remaining -= readLen;
      }

      if (chunkReader.availableBytes == 0) {
        _advanceChunk();
      }
    }

    return result;
  }

  /// Reads all currently available bytes across all chunks.
  ///
  /// Throws [NotEnoughDataException] if no bytes are available.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  Uint8List readRemainingBytes() => readBytes(_s.availableBytes);

  /// Reads a length-prefixed byte array.
  ///
  /// Throws [NotEnoughDataException] if fewer than 1 byte is available for the
  /// length prefix.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  Uint8List readVarBytes() {
    final length = readVarUint();

    return readBytes(length);
  }

  /// Reads a UTF-8 encoded string of the specified byte length.
  ///
  /// Throws [NotEnoughDataException] if fewer than [length] bytes are
  /// available.
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
  ///
  /// Throws [NotEnoughDataException] if fewer than 1 byte is available for the
  ///  length prefix.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  String readVarString({bool allowMalformed = false}) {
    final length = readVarUint();

    return readString(length, allowMalformed: allowMalformed);
  }

  /// Reads a UTF-8 encoded string prefixed with a fixed-width length.
  ///
  /// Throws [NotEnoughDataException] if fewer than the required bytes for the
  /// length prefix are available.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  String readStringFixed({
    LengthEncoding lengthEncoding = .u8,
    bool allowMalformed = false,
  }) {
    final length = _readLength(lengthEncoding);

    return readString(length, allowMalformed: allowMalformed);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int _readLength(LengthEncoding encoding) => switch (encoding) {
    .u8 => readUint8(),
    .u16 => readUint16(),
    .u32 => readUint32(),
    .u64 => readUint64(),
  };

  /// Advances the read position by the specified number of bytes.
  ///
  /// Throws [NotEnoughDataException] if fewer than [length] bytes are
  /// available.
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
final class _StreamReaderState extends ChunkedTransactionalState<Uint8List>
    implements TransactionalReader<List<int>> {
  _StreamReaderState()
    : bookmarkReaderOffset = Int32List(16),
      scratchBuffer = Uint8List(8),
      super() {
    scratchData = ByteData.sublistView(scratchBuffer);
  }

  BinaryReader? currentReader;
  Uint8List? currentChunk;

  /// Pre-allocated buffer for zero-allocation cross-chunk primitive reads.
  final Uint8List scratchBuffer;

  /// ByteData view for the [scratchBuffer].
  late final ByteData scratchData;

  // Zero-allocation bookmarks using parallel arrays
  Int32List bookmarkReaderOffset;

  @override
  void addChunk(List<int> bytes) {
    if (bytes.isEmpty) {
      return;
    }

    final chunk = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    super.addChunk(chunk);
  }

  @override
  int getChunkLength(Uint8List chunk) => chunk.length;

  @override
  bool get hasCurrentReader => currentReader != null;

  @override
  void onBindReader(Uint8List chunk, int offset) {
    currentChunk = chunk;
    final cr = currentReader;
    if (cr != null) {
      cr
        ..rebind(chunk)
        ..seek(offset);
    } else {
      currentReader = BinaryReader(chunk)..seek(offset);
    }
  }

  @override
  void onUnbindReader() {
    currentChunk = null;
    currentReader = null;
  }

  @override
  void onSaveBookmark(int bookmarkIndex) {
    bookmarkReaderOffset[bookmarkIndex] = currentReader?.offset ?? 0;
  }

  @override
  int onRestoreBookmark(int bookmarkIndex) =>
      bookmarkReaderOffset[bookmarkIndex];

  @pragma('vm:never-inline')
  @override
  void growBookmarks() {
    super.growBookmarks();

    final newCapacity = bookmarkAbsoluteIndex.length;
    bookmarkReaderOffset = Int32List(newCapacity)
      ..setRange(0, bookmarkCount, bookmarkReaderOffset);
  }
}
