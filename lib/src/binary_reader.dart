import 'dart:convert';
import 'dart:typed_data';

extension type const BinaryReader._(_Reader _ctx) {
  BinaryReader(Uint8List buffer) : this._(_Reader(buffer));

  @pragma('vm:prefer-inline')
  int get availableBytes => _ctx.length - _ctx.offset;

  @pragma('vm:prefer-inline')
  int get offset => _ctx.offset;

  @pragma('vm:prefer-inline')
  int get length => _ctx.length;

  @pragma('vm:prefer-inline')
  void _checkBounds(int bytes, String type, [int? offset]) {
    assert(
      (offset ?? _ctx.offset) + bytes <= _ctx.length,
      'Not enough bytes to read $type: required $bytes bytes, available '
      '${_ctx.length - _ctx.offset} bytes at offset ${_ctx.offset}',
    );
  }

  @pragma('vm:prefer-inline')
  int readVarInt() {
    var result = 0;
    var shift = 0;

    final list = _ctx.list;
    var offset = _ctx.offset;

    for (var i = 0; i < 10; i++) {
      assert(offset < _ctx.length, 'VarInt out of bounds');
      final byte = list[offset++];

      result |= (byte & 0x7f) << shift;

      if ((byte & 0x80) == 0) {
        _ctx.offset = offset;
        return result;
      }

      shift += 7;
    }

    throw const FormatException('VarInt is too long (more than 10 bytes)');
  }

  @pragma('vm:prefer-inline')
  int readZigZag() {
    final v = readVarInt();
    // Decode zig-zag encoding
    return (v >>> 1) ^ -(v & 1);
  }

  @pragma('vm:prefer-inline')
  int readUint8() {
    _checkBounds(1, 'Uint8');

    return _ctx.data.getUint8(_ctx.offset++);
  }

  @pragma('vm:prefer-inline')
  int readInt8() {
    _checkBounds(1, 'Int8');

    return _ctx.data.getInt8(_ctx.offset++);
  }

  @pragma('vm:prefer-inline')
  int readUint16([Endian endian = .big]) {
    _checkBounds(2, 'Uint16');

    final value = _ctx.data.getUint16(_ctx.offset, endian);
    _ctx.offset += 2;

    return value;
  }

  @pragma('vm:prefer-inline')
  int readInt16([Endian endian = .big]) {
    _checkBounds(2, 'Int16');

    final value = _ctx.data.getInt16(_ctx.offset, endian);
    _ctx.offset += 2;

    return value;
  }

  @pragma('vm:prefer-inline')
  int readUint32([Endian endian = .big]) {
    _checkBounds(4, 'Uint32');

    final value = _ctx.data.getUint32(_ctx.offset, endian);
    _ctx.offset += 4;
    return value;
  }

  @pragma('vm:prefer-inline')
  int readInt32([Endian endian = .big]) {
    _checkBounds(4, 'Int32');
    final value = _ctx.data.getInt32(_ctx.offset, endian);
    _ctx.offset += 4;
    return value;
  }

  @pragma('vm:prefer-inline')
  int readUint64([Endian endian = .big]) {
    _checkBounds(8, 'Uint64');
    final value = _ctx.data.getUint64(_ctx.offset, endian);
    _ctx.offset += 8;
    return value;
  }

  @pragma('vm:prefer-inline')
  int readInt64([Endian endian = .big]) {
    _checkBounds(8, 'Int64');
    final value = _ctx.data.getInt64(_ctx.offset, endian);
    _ctx.offset += 8;
    return value;
  }

  @pragma('vm:prefer-inline')
  double readFloat32([Endian endian = .big]) {
    _checkBounds(4, 'Float32');

    final value = _ctx.data.getFloat32(_ctx.offset, endian);
    _ctx.offset += 4;

    return value;
  }

  @pragma('vm:prefer-inline')
  double readFloat64([Endian endian = .big]) {
    _checkBounds(8, 'Float64');

    final value = _ctx.data.getFloat64(_ctx.offset, endian);
    _ctx.offset += 8;
    return value;
  }

  @pragma('vm:prefer-inline')
  Uint8List readBytes(int length) {
    assert(length >= 0, 'Length must be non-negative');
    _checkBounds(length, 'Bytes');

    // Create a view of the underlying buffer without copying.
    final bOffset = _ctx.baseOffset;
    final bytes = _ctx.data.buffer.asUint8List(bOffset + _ctx.offset, length);

    _ctx.offset += length;

    return bytes;
  }

  @pragma('vm:prefer-inline')
  String readString(int length, {bool allowMalformed = false}) {
    if (length == 0) {
      return '';
    }

    _checkBounds(length, 'String');

    final bOffset = _ctx.baseOffset;
    final view = _ctx.data.buffer.asUint8List(bOffset + _ctx.offset, length);
    _ctx.offset += length;

    return utf8.decode(view, allowMalformed: allowMalformed);
  }

  @pragma('vm:prefer-inline')
  Uint8List peekBytes(int length, [int? offset]) {
    assert(length >= 0, 'Length must be non-negative');

    if (length == 0) {
      return Uint8List(0);
    }

    final peekOffset = offset ?? _ctx.offset;
    _checkBounds(length, 'Peek Bytes', peekOffset);

    final bOffset = _ctx.baseOffset;

    return _ctx.data.buffer.asUint8List(bOffset + peekOffset, length);
  }

  void skip(int length) {
    assert(length >= 0, 'Length must be non-negative');
    _checkBounds(length, 'Skip');

    _ctx.offset += length;
  }

  @pragma('vm:prefer-inline')
  void reset() {
    _ctx.offset = 0;
  }
}

final class _Reader {
  _Reader(Uint8List buffer)
    : list = buffer,
      data = ByteData.sublistView(buffer).asUnmodifiableView(),
      buffer = buffer.buffer,
      length = buffer.length,
      baseOffset = buffer.offsetInBytes,
      offset = 0;

  final Uint8List list;

  /// Efficient view for typed data access.
  final ByteData data;

  final ByteBuffer buffer;

  /// Total length of the buffer.
  final int length;

  /// Current read position in the buffer.
  late int offset;

  final int baseOffset;
}
