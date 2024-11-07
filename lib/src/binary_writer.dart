import 'dart:convert';
import 'dart:typed_data';

import 'binary_writer_interface.dart';

/// The [BinaryWriter] class is an implementation of the [BinaryWriterInterface]
/// used to encode various types of data into a binary format.
class BinaryWriter extends BinaryWriterInterface {
  BinaryWriter({int initialBufferSize = 64})
      : _initialBufferSize = initialBufferSize;

  final int _initialBufferSize;

  Uint8List? _buffer;
  ByteData? _data;
  int _offset = 0;

  @override
  int get bytesWritten => _offset;

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeUint8(int value) {
    _ensureSize(1);
    _data!.setUint8(_offset, value);
    _offset += 1;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeInt8(int value) {
    _ensureSize(1);
    _data!.setInt8(_offset, value);
    _offset += 1;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeUint16(int value, [Endian endian = Endian.big]) {
    _ensureSize(2);
    _data!.setUint16(_offset, value, endian);
    _offset += 2;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeInt16(int value, [Endian endian = Endian.big]) {
    _ensureSize(2);
    _data!.setInt16(_offset, value, endian);
    _offset += 2;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeUint32(int value, [Endian endian = Endian.big]) {
    _ensureSize(4);
    _data!.setUint32(_offset, value, endian);
    _offset += 4;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeInt32(int value, [Endian endian = Endian.big]) {
    _ensureSize(4);
    _data!.setInt32(_offset, value, endian);
    _offset += 4;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeUint64(int value, [Endian endian = Endian.big]) {
    _ensureSize(8);
    _data!.setUint64(_offset, value, endian);
    _offset += 8;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeInt64(int value, [Endian endian = Endian.big]) {
    _ensureSize(8);
    _data!.setInt64(_offset, value, endian);
    _offset += 8;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeFloat32(double value, [Endian endian = Endian.big]) {
    _ensureSize(4);
    _data!.setFloat32(_offset, value, endian);
    _offset += 4;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeFloat64(double value, [Endian endian = Endian.big]) {
    _ensureSize(8);
    _data!.setFloat64(_offset, value, endian);
    _offset += 8;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeBytes(List<int> bytes) {
    final length = bytes.length;
    _ensureSize(length);

    final list = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);

    _buffer!.setRange(_offset, _offset + length, list);
    _offset += length;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeString(String value) {
    final encoded = utf8.encode(value);
    writeBytes(encoded);
  }

  @override
  Uint8List takeBytes() {
    if (_buffer == null) {
      return Uint8List(0);
    }

    final result = Uint8List.sublistView(_buffer!, 0, _offset);

    _offset = 0;
    _buffer = null;
    _data = null;

    return result;
  }

  /// Ensures that the buffer has enough space to accommodate the specified
  /// size. If the buffer is too small, it expands it to the next power of two.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void _ensureSize(int size) {
    if (_buffer == null) {
      final initialSize = size > _initialBufferSize
          ? _nextPowerOfTwo(size)
          : _initialBufferSize;
      _buffer = Uint8List(initialSize);
      _data = ByteData.view(_buffer!.buffer, _buffer!.offsetInBytes);

      return;
    }

    final requiredSize = _offset + size;
    if (_buffer!.length < requiredSize) {
      final newSize = _nextPowerOfTwo(requiredSize);

      _buffer = Uint8List(newSize)..setRange(0, _offset, _buffer!);
      _data = ByteData.view(_buffer!.buffer, _buffer!.offsetInBytes);
    }
  }

  /// Returns the next power of two for the specified value.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int _nextPowerOfTwo(int value) {
    assert(value > 0, 'Value must be greater than zero.');

    final result = 1 << (value - 1).bitLength;

    return result;
  }
}
