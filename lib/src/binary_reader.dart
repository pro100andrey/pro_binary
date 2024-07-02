import 'dart:typed_data';

import 'binary_reader_interface.dart';

class BinaryReader extends BinaryReaderInterface {
  BinaryReader(
    Uint8List list, {
    this.copyBinaryData = false,
  })  : _list = list,
        _data = ByteData.view(list.buffer, list.offsetInBytes);

  final Uint8List _list;
  final ByteData _data;
  final bool copyBinaryData;

  int _offset = 0;

  @override
  int readUInt8() {
    final result = _data.getUint8(_offset);
    _offset += 1;

    return result;
  }

  @override
  int readInt8() {
    final result = _data.getInt8(_offset);
    _offset += 1;

    return result;
  }

  @override
  int readUInt16([Endian endian = Endian.big]) {
    final result = _data.getUint16(_offset, endian);
    _offset += 2;

    return result;
  }

  @override
  int readInt16([Endian endian = Endian.big]) {
    final result = _data.getInt16(_offset, endian);
    _offset += 2;

    return result;
  }

  @override
  int readUInt32([Endian endian = Endian.big]) {
    final result = _data.getUint32(_offset, endian);
    _offset += 4;

    return result;
  }

  @override
  int readInt32([Endian endian = Endian.big]) {
    final result = _data.getInt32(_offset, endian);
    _offset += 4;

    return result;
  }

  @override
  int readUInt64([Endian endian = Endian.big]) {
    final result = _data.getUint64(_offset, endian);
    _offset += 8;

    return result;
  }

  @override
  int readInt64([Endian endian = Endian.big]) {
    final result = _data.getInt64(_offset, endian);
    _offset += 8;

    return result;
  }

  @override
  double readFloat32([Endian endian = Endian.big]) {
    final result = _data.getFloat32(_offset, endian);
    _offset += 4;

    return result;
  }

  @override
  double readFloat64([Endian endian = Endian.big]) {
    final result = _data.getFloat64(_offset, endian);
    _offset += 8;

    return result;
  }

  Uint8List _readBuffer(int length) {
    final res = Uint8List.view(
      _list.buffer,
      _list.offsetInBytes + _offset,
      length,
    );
    _offset += length;

    return copyBinaryData ? Uint8List.fromList(res) : res;
  }
}
