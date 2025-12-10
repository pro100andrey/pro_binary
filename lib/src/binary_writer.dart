import 'dart:convert';
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
  static const _utf8Encoder = Utf8Encoder();

  /// Internal buffer for storing binary data.
  late Uint8List _buffer;

  /// View for efficient typed data access.
  late ByteData _data;

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
    if (value < 0 || value > 255) {
      throw RangeError.range(value, 0, 255, 'value');
    }

    _ensureSize(1);
    _data.setUint8(_offset, value);
    _offset += 1;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeInt8(int value) {
    if (value < -128 || value > 127) {
      throw RangeError.range(value, -128, 127, 'value');
    }

    _ensureSize(1);
    _data.setInt8(_offset, value);
    _offset += 1;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeUint16(int value, [Endian endian = Endian.big]) {
    if (value < 0 || value > 65535) {
      throw RangeError.range(value, 0, 65535, 'value');
    }

    _ensureSize(2);
    _data.setUint16(_offset, value, endian);
    _offset += 2;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeInt16(int value, [Endian endian = Endian.big]) {
    if (value < -32768 || value > 32767) {
      throw RangeError.range(value, -32768, 32767, 'value');
    }

    _ensureSize(2);
    _data.setInt16(_offset, value, endian);
    _offset += 2;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeUint32(int value, [Endian endian = Endian.big]) {
    if (value < 0 || value > 4294967295) {
      throw RangeError.range(value, 0, 4294967295, 'value');
    }

    _ensureSize(4);
    _data.setUint32(_offset, value, endian);
    _offset += 4;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeInt32(int value, [Endian endian = Endian.big]) {
    if (value < -2147483648 || value > 2147483647) {
      throw RangeError.range(value, -2147483648, 2147483647, 'value');
    }

    _ensureSize(4);
    _data.setInt32(_offset, value, endian);
    _offset += 4;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeUint64(int value, [Endian endian = Endian.big]) {
    _ensureSize(8);
    _data.setUint64(_offset, value, endian);
    _offset += 8;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeInt64(int value, [Endian endian = Endian.big]) {
    _ensureSize(8);
    _data.setInt64(_offset, value, endian);
    _offset += 8;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeFloat32(double value, [Endian endian = Endian.big]) {
    _ensureSize(4);
    _data.setFloat32(_offset, value, endian);
    _offset += 4;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeFloat64(double value, [Endian endian = Endian.big]) {
    _ensureSize(8);
    _data.setFloat64(_offset, value, endian);
    _offset += 8;
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

  @override
  void writeString(String value) {
    if (value.isEmpty) {
      return;
    }

    final encoded = _utf8Encoder.convert(value);
    final length = encoded.length;
    _ensureSize(length);

    // Use setRange for better performance with encoded bytes
    _buffer.setRange(_offset, _offset + length, encoded);
    _offset += length;
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
  void clear() {
    _offset = 0;
    _initializeBuffer(_initialBufferSize);
  }

  /// Initializes the buffer with the specified size.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void _initializeBuffer(int size) {
    _buffer = Uint8List(size);
    _data = ByteData.view(_buffer.buffer);
    _capacity = size;
  }

  /// Ensures that the buffer has enough space to accommodate the specified
  /// [size] bytes.
  ///
  /// If the buffer is too small, it expands using a 1.5x growth strategy,
  /// which balances memory usage and reallocation frequency.
  /// Uses cached capacity for fast path optimization.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void _ensureSize(int size) {
    final requiredSize = _offset + size;
    if (requiredSize > _capacity) {
      // Sync capacity with actual buffer length if needed
      if (_capacity != _buffer.length) {
        _capacity = _buffer.length;
      }

      if (_capacity < requiredSize) {
        // Growth strategy: multiply by 1.5 (via * 3 / 2)
        var newSize = _capacity;
        do {
          newSize = (newSize * 3) >> 1;
        } while (newSize < requiredSize);

        final newBuffer = Uint8List(newSize)..setRange(0, _offset, _buffer);

        _buffer = newBuffer;
        _data = ByteData.view(_buffer.buffer);
        _capacity = newSize;
      }
    }
  }
}
