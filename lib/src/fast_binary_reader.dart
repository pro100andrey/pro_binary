import 'dart:convert';
import 'dart:typed_data';

extension type const FastBinaryReader._(_Buffer _ctx) {
  FastBinaryReader(Uint8List buffer) : this._(_Buffer(buffer));

  @pragma('vm:prefer-inline')
  int get availableBytes => _ctx.length - _ctx.offset;

  @pragma('vm:prefer-inline')
  int get lengthInBytes => _ctx.lengthInBytes;

  @pragma('vm:prefer-inline')
  int get offset => _ctx.offset;

  @pragma('vm:prefer-inline')
  int get length => _ctx.length;

  @pragma('vm:prefer-inline')
  int get _offset => _ctx.offset;

  @pragma('vm:prefer-inline')
  set _offset(int value) {
    _ctx.offset = value;
  }

  @pragma('vm:prefer-inline')
  ByteData get _data => _ctx.data;

  @pragma('vm:prefer-inline')
  void _checkBounds(int bytes, String type, [int? offset]) {
    assert(
      (offset ?? _offset) + bytes <= _ctx.length,
      'Not enough bytes to read $type: required $bytes bytes, available '
      '${_ctx.length - _offset} bytes at offset $_offset',
    );
  }

  @pragma('vm:prefer-inline')
  int readUint8() {
    _checkBounds(1, 'Uint8');

    return _data.getUint8(_offset++);
  }

  @pragma('vm:prefer-inline')
  int readInt8() {
    _checkBounds(1, 'Int8');

    return _data.getInt8(_offset++);
  }

  @pragma('vm:prefer-inline')
  int readUint16([Endian endian = .big]) {
    _checkBounds(2, 'Uint16');

    final value = _data.getUint16(_offset, endian);
    _offset += 2;

    return value;
  }

  @pragma('vm:prefer-inline')
  int readInt16([Endian endian = .big]) {
    _checkBounds(2, 'Int16');

    final value = _data.getInt16(_offset, endian);
    _offset += 2;

    return value;
  }

  @pragma('vm:prefer-inline')
  int readUint32([Endian endian = .big]) {
    _checkBounds(4, 'Uint32');

    final value = _data.getUint32(_offset, endian);
    _offset += 4;
    return value;
  }

  @pragma('vm:prefer-inline')
  int readInt32([Endian endian = .big]) {
    _checkBounds(4, 'Int32');
    final value = _data.getInt32(_offset, endian);
    _offset += 4;
    return value;
  }

  @pragma('vm:prefer-inline')
  int readUint64([Endian endian = .big]) {
    _checkBounds(8, 'Uint64');
    final value = _data.getUint64(_offset, endian);
    _offset += 8;
    return value;
  }

  @pragma('vm:prefer-inline')
  int readInt64([Endian endian = .big]) {
    _checkBounds(8, 'Int64');
    final value = _data.getInt64(_offset, endian);
    _offset += 8;
    return value;
  }

  @pragma('vm:prefer-inline')
  double readFloat32([Endian endian = .big]) {
    _checkBounds(4, 'Float32');

    final value = _data.getFloat32(_offset, endian);
    _offset += 4;

    return value;
  }

  @pragma('vm:prefer-inline')
  double readFloat64([Endian endian = .big]) {
    _checkBounds(8, 'Float64');

    final value = _data.getFloat64(_offset, endian);
    _offset += 8;
    return value;
  }

  @pragma('vm:prefer-inline')
  Uint8List readBytes(int length) {
    assert(length >= 0, 'Length must be non-negative');
    _checkBounds(length, 'Bytes');

    final bytes = _data.buffer.asUint8List(_offset, length);
    _offset += length;

    return bytes;
  }

  @pragma('vm:prefer-inline')
  String readString(int length, {bool allowMalformed = false}) {
    if (length == 0) {
      return '';
    }

    _checkBounds(length, 'String');

    final view = _data.buffer.asUint8List(_offset, length);
    _offset += length;

    return utf8.decode(view, allowMalformed: allowMalformed);
  }
  

  @pragma('vm:prefer-inline')
  Uint8List peekBytes(int length, [int? offset]) {
    assert(length >= 0, 'Length must be non-negative');

    if (length == 0) {
      return Uint8List(0);
    }

    final peekOffset = offset ?? _offset;
    _checkBounds(length, 'Peek Bytes', peekOffset);

    return _data.buffer.asUint8List(peekOffset, length);
  }

  void skip(int length) {
    assert(length >= 0, 'Length must be non-negative');
    _checkBounds(length, 'Skip');

    _offset += length;
  }

  @pragma('vm:prefer-inline')
  void reset() {
    _offset = 0;
  }
}

final class _Buffer {
  _Buffer(Uint8List buffer)
    : data = ByteData.sublistView(buffer).asUnmodifiableView(),
      length = buffer.length,
      lengthInBytes = buffer.lengthInBytes,
      offset = 0;

  /// Efficient view for typed data access.
  final ByteData data;

  /// Total length of the buffer.
  final int length;

  /// Current read position in the buffer.
  late int offset;

  final int lengthInBytes;
}
