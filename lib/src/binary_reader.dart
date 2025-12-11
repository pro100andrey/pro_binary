import 'dart:convert';
import 'dart:typed_data';

import 'binary_reader_interface.dart';

/// A high-performance implementation of [BinaryReaderInterface] for decoding
/// binary data.
///
/// Features:
/// - Zero-copy operations using ByteData views
/// - Inline bounds checking for safety
/// - Support for big-endian and little-endian byte order
/// - UTF-8 string decoding
/// - Peek operations without advancing position
///
/// Example:
/// ```dart
/// final bytes = Uint8List.fromList([0, 0, 0, 42]);
/// final reader = BinaryReader(bytes);
/// final value = reader.readUint32(); // 42
/// print(reader.availableBytes); // 0
/// ```
class BinaryReader extends BinaryReaderInterface {
  /// Creates a new [BinaryReader] for the given byte buffer.
  ///
  /// The [buffer] parameter must be a [Uint8List] containing the data to read.
  /// The reader starts at position 0 and can read up to the buffer's length.
  BinaryReader(Uint8List buffer)
    : _buffer = buffer,
      _data = ByteData.sublistView(buffer),
      _length = buffer.length;

  /// The underlying byte buffer being read from.
  final Uint8List _buffer;

  /// Efficient view for typed data access.
  final ByteData _data;

  /// Total length of the buffer.
  final int _length;

  /// Current read position in the buffer.
  int _offset = 0;

  /// Performs inline bounds check to ensure safe reads.
  ///
  /// Throws [AssertionError] if attempting to read beyond buffer boundaries.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void _checkBounds(int bytes, String type, [int? offset]) {
    assert(
      (offset ?? _offset) + bytes <= _length,
      'Not enough bytes to read $type: required $bytes bytes, available '
      '${_length - _offset} bytes at offset $_offset',
    );
  }

  @override
  int get availableBytes => _length - _offset;

  @override
  int get usedBytes => _offset;

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  int readUint8() {
    _checkBounds(1, 'Uint8');
    return _data.getUint8(_offset++);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  int readInt8() {
    _checkBounds(1, 'Int8');

    return _data.getInt8(_offset++);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  int readUint16([Endian endian = Endian.big]) {
    _checkBounds(2, 'Uint16');

    final value = _data.getUint16(_offset, endian);
    _offset += 2;

    return value;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  int readInt16([Endian endian = Endian.big]) {
    _checkBounds(2, 'Int16');

    final value = _data.getInt16(_offset, endian);
    _offset += 2;

    return value;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  int readUint32([Endian endian = Endian.big]) {
    _checkBounds(4, 'Uint32');

    final value = _data.getUint32(_offset, endian);
    _offset += 4;

    return value;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  int readInt32([Endian endian = Endian.big]) {
    _checkBounds(4, 'Int32');

    final value = _data.getInt32(_offset, endian);
    _offset += 4;

    return value;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  int readUint64([Endian endian = Endian.big]) {
    _checkBounds(8, 'Uint64');

    final value = _data.getUint64(_offset, endian);
    _offset += 8;

    return value;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  int readInt64([Endian endian = Endian.big]) {
    _checkBounds(8, 'Int64');

    final value = _data.getInt64(_offset, endian);
    _offset += 8;

    return value;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  double readFloat32([Endian endian = Endian.big]) {
    _checkBounds(4, 'Float32');

    final value = _data.getFloat32(_offset, endian);
    _offset += 4;

    return value;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  double readFloat64([Endian endian = Endian.big]) {
    _checkBounds(8, 'Float64');

    final value = _data.getFloat64(_offset, endian);
    _offset += 8;

    return value;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  Uint8List readBytes(int length) {
    assert(length >= 0, 'Length must be non-negative');
    _checkBounds(length, 'Bytes');

    final bytes = Uint8List.sublistView(_buffer, _offset, _offset + length);
    _offset += length;

    return bytes;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  String readString(int length, {bool allowMalformed = false}) {
    if (length == 0) {
      return '';
    }

    _checkBounds(length, 'String');

    final view = Uint8List.sublistView(_buffer, _offset, _offset + length);
    _offset += length;

    return utf8.decode(view, allowMalformed: allowMalformed);
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  Uint8List peekBytes(int length, [int? offset]) {
    assert(length >= 0, 'Length must be non-negative');

    if (length == 0) {
      return Uint8List(0);
    }

    final peekOffset = offset ?? _offset;
    _checkBounds(length, 'Peek Bytes', peekOffset);

    return Uint8List.sublistView(_buffer, peekOffset, peekOffset + length);
  }

  @override
  void skip(int length) {
    assert(length >= 0, 'Length must be non-negative');
    _checkBounds(length, 'Skip');
    _offset += length;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void reset() {
    _offset = 0;
  }

  @override
  int get offset => _offset;
}
