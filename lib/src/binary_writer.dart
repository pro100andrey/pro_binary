import 'dart:typed_data';

import 'binary_writer_interface.dart';

/// A high-performance implementation of [BinaryWriterInterface] for encoding
/// data into binary format.
///
/// Features:
/// - Automatic buffer growth with 1.5x expansion strategy
/// - Cached capacity checks for minimal overhead
/// - Optimized for sequential writes
/// - UTF-8 string encoding
///
/// Example:
/// ```dart
/// final writer = BinaryWriter();
/// writer.writeUint32(42);
/// writer.writeString('Hello');
/// final bytes = writer.toBytes();
/// ```
class BinaryWriter extends BinaryWriterInterface {
  /// Creates a new [BinaryWriter] with an optional initial buffer size.
  ///
  /// The [initialBufferSize] parameter specifies the initial capacity of the
  /// internal buffer (defaults to 64 bytes). Choose a larger value if you
  /// expect to write large amounts of data to reduce reallocations.
  BinaryWriter({int initialBufferSize = 64})
    : _initialBufferSize = initialBufferSize {
    _initializeBuffer(initialBufferSize);
  }

  final int _initialBufferSize;

  /// Internal buffer for storing binary data.
  late Uint8List _buffer;

  /// Current write position in the buffer.
  int _offset = 0;

  /// Cached buffer capacity to avoid repeated length checks.
  int _capacity = 0;

  @override
  int get bytesWritten => _offset;

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeUint8(int value) {
    assert(
      value >= 0 && value <= 255,
      'Value out of range for Uint8: $value',
    );

    _ensureSize(1);
    _buffer[_offset++] = value;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeInt8(int value) {
    assert(
      value >= -128 && value <= 127,
      'Value out of range for Int8: $value',
    );

    _ensureSize(1);
    _buffer[_offset++] = value & 0xFF;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeUint16(int value, [Endian endian = Endian.big]) {
    assert(
      value >= 0 && value <= 65535,
      'Value out of range for Uint16: $value',
    );

    _ensureSize(2);

    if (endian == Endian.big) {
      _buffer[_offset++] = (value >> 8) & 0xFF;
      _buffer[_offset++] = value & 0xFF;
    } else {
      _buffer[_offset++] = value & 0xFF;
      _buffer[_offset++] = (value >> 8) & 0xFF;
    }
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeInt16(int value, [Endian endian = Endian.big]) {
    assert(
      value >= -32768 && value <= 32767,
      'Value out of range for Int16: $value',
    );

    _ensureSize(2);

    if (endian == Endian.big) {
      _buffer[_offset++] = (value >> 8) & 0xFF;
      _buffer[_offset++] = value & 0xFF;
    } else {
      _buffer[_offset++] = value & 0xFF;
      _buffer[_offset++] = (value >> 8) & 0xFF;
    }
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeUint32(int value, [Endian endian = Endian.big]) {
    assert(
      value >= 0 && value <= 4294967295,
      'Value out of range for Uint32: $value',
    );

    _ensureSize(4);

    if (endian == Endian.big) {
      _buffer[_offset++] = (value >> 24) & 0xFF;
      _buffer[_offset++] = (value >> 16) & 0xFF;
      _buffer[_offset++] = (value >> 8) & 0xFF;
      _buffer[_offset++] = value & 0xFF;
    } else {
      _buffer[_offset++] = value & 0xFF;
      _buffer[_offset++] = (value >> 8) & 0xFF;
      _buffer[_offset++] = (value >> 16) & 0xFF;
      _buffer[_offset++] = (value >> 24) & 0xFF;
    }
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeInt32(int value, [Endian endian = Endian.big]) {
    assert(
      value >= -2147483648 && value <= 2147483647,
      'Value out of range for Int32: $value',
    );

    _ensureSize(4);

    if (endian == Endian.big) {
      _buffer[_offset++] = (value >> 24) & 0xFF;
      _buffer[_offset++] = (value >> 16) & 0xFF;
      _buffer[_offset++] = (value >> 8) & 0xFF;
      _buffer[_offset++] = value & 0xFF;
    } else {
      _buffer[_offset++] = value & 0xFF;
      _buffer[_offset++] = (value >> 8) & 0xFF;
      _buffer[_offset++] = (value >> 16) & 0xFF;
      _buffer[_offset++] = (value >> 24) & 0xFF;
    }
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeUint64(int value, [Endian endian = Endian.big]) {
    assert(
      value >= 0 && value <= 9223372036854775807,
      'Value out of range for Uint64: $value',
    );

    _ensureSize(8);

    if (endian == Endian.big) {
      _buffer[_offset++] = (value >> 56) & 0xFF;
      _buffer[_offset++] = (value >> 48) & 0xFF;
      _buffer[_offset++] = (value >> 40) & 0xFF;
      _buffer[_offset++] = (value >> 32) & 0xFF;
      _buffer[_offset++] = (value >> 24) & 0xFF;
      _buffer[_offset++] = (value >> 16) & 0xFF;
      _buffer[_offset++] = (value >> 8) & 0xFF;
      _buffer[_offset++] = value & 0xFF;
    } else {
      _buffer[_offset++] = value & 0xFF;
      _buffer[_offset++] = (value >> 8) & 0xFF;
      _buffer[_offset++] = (value >> 16) & 0xFF;
      _buffer[_offset++] = (value >> 24) & 0xFF;
      _buffer[_offset++] = (value >> 32) & 0xFF;
      _buffer[_offset++] = (value >> 40) & 0xFF;
      _buffer[_offset++] = (value >> 48) & 0xFF;
      _buffer[_offset++] = (value >> 56) & 0xFF;
    }
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeInt64(int value, [Endian endian = Endian.big]) {
    assert(
      value >= -9223372036854775808 && value <= 9223372036854775807,
      'Value out of range for Int64: $value',
    );

    _ensureSize(8);

    if (endian == Endian.big) {
      _buffer[_offset++] = (value >> 56) & 0xFF;
      _buffer[_offset++] = (value >> 48) & 0xFF;
      _buffer[_offset++] = (value >> 40) & 0xFF;
      _buffer[_offset++] = (value >> 32) & 0xFF;
      _buffer[_offset++] = (value >> 24) & 0xFF;
      _buffer[_offset++] = (value >> 16) & 0xFF;
      _buffer[_offset++] = (value >> 8) & 0xFF;
      _buffer[_offset++] = value & 0xFF;
    } else {
      _buffer[_offset++] = value & 0xFF;
      _buffer[_offset++] = (value >> 8) & 0xFF;
      _buffer[_offset++] = (value >> 16) & 0xFF;
      _buffer[_offset++] = (value >> 24) & 0xFF;
      _buffer[_offset++] = (value >> 32) & 0xFF;
      _buffer[_offset++] = (value >> 40) & 0xFF;
      _buffer[_offset++] = (value >> 48) & 0xFF;
      _buffer[_offset++] = (value >> 56) & 0xFF;
    }
  }

  static final Uint8List _tempU8 = Uint8List(8);
  static final Float32List _tempF32 = Float32List.view(_tempU8.buffer);
  static final Float64List _tempF64 = Float64List.view(_tempU8.buffer);

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeFloat32(double value, [Endian endian = Endian.big]) {
    _ensureSize(4);
    _tempF32[0] = value; // Write to temp buffer
    if (endian == Endian.big) {
      _buffer[_offset++] = _tempU8[3];
      _buffer[_offset++] = _tempU8[2];
      _buffer[_offset++] = _tempU8[1];
      _buffer[_offset++] = _tempU8[0];
    } else {
      _buffer.setRange(_offset, _offset + 4, _tempU8);
      _offset += 4;
    }
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeFloat64(double value, [Endian endian = Endian.big]) {
    _ensureSize(8);
    _tempF64[0] = value;
    if (endian == Endian.big) {
      _buffer[_offset++] = _tempU8[7];
      _buffer[_offset++] = _tempU8[6];
      _buffer[_offset++] = _tempU8[5];
      _buffer[_offset++] = _tempU8[4];
      _buffer[_offset++] = _tempU8[3];
      _buffer[_offset++] = _tempU8[2];
      _buffer[_offset++] = _tempU8[1];
      _buffer[_offset++] = _tempU8[0];
    } else {
      _buffer.setRange(_offset, _offset + 8, _tempU8);
      _offset += 8;
    }
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeBytes(List<int> bytes) {
    // Early return for empty byte lists
    if (bytes.isEmpty) {
      return;
    }

    final length = bytes.length;
    _ensureSize(length);

    _buffer.setRange(_offset, _offset + length, bytes);
    _offset += length;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeString(String value) {
    final len = value.length;
    if (len == 0) {
      return;
    }

    // Over-allocate max UTF-8 size (4 bytes/char, ~3 )
    _ensureSize(len * 4);

    var bufIdx = _offset;
    for (var i = 0; i < len; i++) {
      var c = value.codeUnitAt(i);
      if (c < 128) {
        _buffer[bufIdx++] = c;
      } else if (c < 2048) {
        _buffer[bufIdx++] = 192 | (c >> 6);
        _buffer[bufIdx++] = 128 | (c & 63);
      } else if (c >= 0xD800 && c <= 0xDBFF) {
        // Surrogate pair
        if (i + 1 < len) {
          final next = value.codeUnitAt(++i);
          if (next >= 0xDC00 && next <= 0xDFFF) {
            c = 0x10000 + ((c & 0x3FF) << 10) + (next & 0x3FF);
            _buffer[bufIdx++] = 240 | (c >> 18);
            _buffer[bufIdx++] = 128 | ((c >> 12) & 63);
            _buffer[bufIdx++] = 128 | ((c >> 6) & 63);
            _buffer[bufIdx++] = 128 | (c & 63);
            continue;
          }
        }
        // Replacement char U+FFFD
        _buffer[bufIdx++] = 0xEF;
        _buffer[bufIdx++] = 0xBF;
        _buffer[bufIdx++] = 0xBD;
      } else {
        // 3 bytes
        _buffer[bufIdx++] = 224 | (c >> 12);
        _buffer[bufIdx++] = 128 | ((c >> 6) & 63);
        _buffer[bufIdx++] = 128 | (c & 63);
      }
    }

    _offset = bufIdx;
  }

  @override
  Uint8List takeBytes() {
    final result = Uint8List.sublistView(_buffer, 0, _offset);

    _offset = 0;
    _initializeBuffer(_initialBufferSize);

    return result;
  }

  @override
  Uint8List toBytes() => Uint8List.sublistView(_buffer, 0, _offset);

  @override
  void reset() {
    _offset = 0;
    _initializeBuffer(_initialBufferSize);
  }

  /// Initializes the buffer with the specified size.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void _initializeBuffer(int size) {
    _buffer = Uint8List(size);
    _capacity = size;
  }

  /// Ensures that the buffer has enough space to accommodate the specified
  /// [size] bytes.
  ///
  /// If the buffer is too small, it expands using a 1.5x growth strategy,
  /// which balances memory usage and reallocation frequency.
  /// Uses O(1) calculation instead of loop for better performance.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void _ensureSize(int size) {
    final req = _offset + size;
    if (req <= _capacity) {
      return;
    }

    var newCapacity = _capacity * 3 ~/ 2; // 1.5x
    if (newCapacity < req) {
      newCapacity = req;
    }

    final newBuffer = Uint8List(newCapacity)..setRange(0, _offset, _buffer);
    _buffer = newBuffer;
    _capacity = newCapacity;
  }
}
