import 'dart:convert';
import 'dart:typed_data';

import 'binary_writer_interface.dart';

/// The [BinaryWriter] class is an implementation of the [BinaryWriterInterface]
/// used to encode various types of data into a binary format.
class BinaryWriter extends BinaryWriterInterface {
  BinaryWriter({int initialBufferSize = 64})
      : _initialBufferSize = initialBufferSize {
    _initializeBuffer(initialBufferSize);
  }

  final int _initialBufferSize;

  late Uint8List _buffer;
  late ByteData _data;
  int _offset = 0;

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
    final length = bytes.length;
    _ensureSize(length);

    final list = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);

    _buffer.setRange(_offset, _offset + length, list);
    _offset += length;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeString(String value) {
    final length = value.length;
    _ensureSize(length);

    final encoded = utf8.encode(value);

    _buffer.setRange(_offset, _offset + encoded.length, encoded);
    _offset += encoded.length;
  }

  @override
  Uint8List takeBytes() {
    final result = Uint8List.sublistView(_buffer, 0, _offset);

    _offset = 0;
    _initializeBuffer(_initialBufferSize);

    return result;
  }

  /// Initializes the buffer with the specified size.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void _initializeBuffer(int size) {
    _buffer = Uint8List(size);
    _data = ByteData.view(_buffer.buffer);
  }

  /// Ensures that the buffer has enough space to accommodate the specified
  /// size. If the buffer is too small, it expands it to the next power of two.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void _ensureSize(int size) {
    final requiredSize = _offset + size;
    if (_buffer.length < requiredSize) {
      final newSize = 1 << (requiredSize - 1).bitLength;
      final newBuffer = Uint8List(newSize)..setRange(0, _offset, _buffer);

      _buffer = newBuffer;
      _data = ByteData.view(_buffer.buffer);
    }
  }
}
