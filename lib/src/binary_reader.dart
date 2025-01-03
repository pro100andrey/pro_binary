import 'dart:convert';
import 'dart:typed_data';

import 'binary_reader_interface.dart';

/// The [BinaryReader] class is an implementation of the [BinaryReaderInterface]
/// used to decode various types of data from a binary
class BinaryReader extends BinaryReaderInterface {
  BinaryReader(this._buffer)
      : _data = ByteData.sublistView(_buffer),
        _length = _buffer.length;

  final Uint8List _buffer;
  final ByteData _data;
  final int _length;
  int _offset = 0;

  @override
  int get availableBytes => _length - _offset;

  @override
  int get usedBytes => _offset;

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  int readUint8() {
    final value = _data.getUint8(_offset);
    _offset += 1;

    return value;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  int readInt8() {
    final value = _data.getInt8(_offset);
    _offset += 1;

    return value;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  int readUint16([Endian endian = Endian.big]) {
    final value = _data.getUint16(_offset, endian);
    _offset += 2;

    return value;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  int readInt16([Endian endian = Endian.big]) {
    final value = _data.getInt16(_offset, endian);
    _offset += 2;

    return value;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  int readUint32([Endian endian = Endian.big]) {
    final value = _data.getUint32(_offset, endian);
    _offset += 4;

    return value;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  int readInt32([Endian endian = Endian.big]) {
    final value = _data.getInt32(_offset, endian);
    _offset += 4;

    return value;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  int readUint64([Endian endian = Endian.big]) {
    final value = _data.getUint64(_offset, endian);
    _offset += 8;

    return value;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  int readInt64([Endian endian = Endian.big]) {
    final value = _data.getInt64(_offset, endian);
    _offset += 8;

    return value;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  double readFloat32([Endian endian = Endian.big]) {
    final value = _data.getFloat32(_offset, endian);
    _offset += 4;

    return value;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  double readFloat64([Endian endian = Endian.big]) {
    final value = _data.getFloat64(_offset, endian);
    _offset += 8;

    return value;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  Uint8List readBytes(int length) {
    final bytes = Uint8List.sublistView(_buffer, _offset, _offset + length);

    _offset += length;

    return bytes;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  String readString(int length) {
    final bytes = readBytes(length);

    return utf8.decode(bytes);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  Uint8List peekBytes(int length, [int? offset]) {
    if (length == 0) {
      throw ArgumentError.value(length, 'Length must be greater than zero.');
    }

    if (offset != null && offset < 0) {
      throw ArgumentError.value(
        offset,
        'Offset must be greater than or equal to zero.',
      );
    }

    final peekOffset = offset ?? _offset;

    if (peekOffset < 0) {
      throw ArgumentError.value(
        peekOffset,
        'Offset must be greater than or equal to zero.',
      );
    }

    return _data.buffer.asUint8List(peekOffset, length);
  }

  @override
  void skip(int length) {
    if (length < 0) {
      throw ArgumentError.value(
        length,
        'Length must be greater than or equal to zero.',
      );
    }

    if (_offset + length > _length) {
      throw ArgumentError.value(
        length,
        'Offset is out of bounds.',
      );
    }

    _offset += length;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void reset() {
    _offset = 0;
  }
}
