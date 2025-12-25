import 'dart:convert';
import 'dart:typed_data';

/// A high-performance binary reader for decoding data from a byte buffer.
///
/// Provides methods for reading various data types including:
/// - Variable-length integers (VarInt, ZigZag)
/// - Fixed-width integers (8, 16, 32, 64-bit signed and unsigned)
/// - Floating-point numbers (32 and 64-bit)
/// - Byte arrays and strings
///
/// The reader maintains an internal offset that advances as data is read.
/// Use [reset] to restart reading from the beginning.
///
/// Example:
/// ```dart
/// final reader = BinaryReader(bytes);
/// final value = reader.readUint32();
/// final text = reader.readString(10);
/// ```
extension type const BinaryReader._(_ReaderState _ctx) {
  /// Creates a new [BinaryReader] from the given byte buffer.
  ///
  /// The reader will start at position 0 and can read up to `buffer.length`
  /// bytes.
  BinaryReader(Uint8List buffer) : this._(_ReaderState(buffer));

  /// Returns the number of bytes remaining to be read.
  @pragma('vm:prefer-inline')
  int get availableBytes => _ctx.length - _ctx.offset;

  /// Returns the current read position in the buffer.
  @pragma('vm:prefer-inline')
  int get offset => _ctx.offset;

  /// Returns the total length of the buffer in bytes.
  @pragma('vm:prefer-inline')
  int get length => _ctx.length;

  /// Reads a variable-length integer encoded using VarInt format.
  ///
  /// VarInt encoding uses the lower 7 bits of each byte for data and the
  /// highest bit as a continuation flag. This format is space-efficient
  /// for small numbers (1-5 bytes for typical 32-bit values).
  ///
  /// The algorithm:
  /// 1. Read a byte and extract the lower 7 bits
  /// 2. If the 8th bit is set, continue reading
  /// 3. Shift and combine all 7-bit chunks
  ///
  /// Throws [FormatException] if the VarInt exceeds 10 bytes (malformed data).
  /// Asserts bounds in debug mode if attempting to read past buffer end.
  @pragma('vm:prefer-inline')
  int readVarInt() {
    var result = 0;
    var shift = 0;

    final list = _ctx.list;
    var offset = _ctx.offset;

    // VarInt uses up to 10 bytes for 64-bit integers
    for (var i = 0; i < 10; i++) {
      assert(offset < _ctx.length, 'VarInt out of bounds');
      final byte = list[offset++];

      // Extract lower 7 bits and shift into position
      result |= (byte & 0x7f) << shift;

      // If MSB is 0, we've reached the last byte
      if ((byte & 0x80) == 0) {
        _ctx.offset = offset;
        return result;
      }

      shift += 7;
    }

    throw const FormatException('VarInt is too long (more than 10 bytes)');
  }

  /// Reads a ZigZag-encoded signed integer.
  ///
  /// ZigZag encoding maps signed integers to unsigned values such that
  /// small absolute values (both positive and negative) use fewer bytes:
  /// - 0 => 0, -1 => 1, 1 => 2, -2 => 3, 2 => 4, etc.
  ///
  /// Decoding formula: (n >>> 1) ^ -(n & 1)
  /// This reverses the encoding: (n << 1) ^ (n >> 63)
  @pragma('vm:prefer-inline')
  int readZigZag() {
    final v = readVarInt();
    // Decode: right shift by 1, XOR with sign-extended LSB
    return (v >>> 1) ^ -(v & 1);
  }

  /// Reads an 8-bit unsigned integer (0-255).
  ///
  /// Asserts bounds in debug mode if insufficient bytes are available.
  @pragma('vm:prefer-inline')
  int readUint8() {
    _checkBounds(1, 'Uint8');

    return _ctx.data.getUint8(_ctx.offset++);
  }

  /// Reads an 8-bit signed integer (-128 to 127).
  ///
  /// Asserts bounds in debug mode if insufficient bytes are available.
  @pragma('vm:prefer-inline')
  int readInt8() {
    _checkBounds(1, 'Int8');

    return _ctx.data.getInt8(_ctx.offset++);
  }

  /// Reads a 16-bit unsigned integer (0-65535).
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  /// Asserts bounds in debug mode if insufficient bytes are available.
  @pragma('vm:prefer-inline')
  int readUint16([Endian endian = .big]) {
    _checkBounds(2, 'Uint16');

    final value = _ctx.data.getUint16(_ctx.offset, endian);
    _ctx.offset += 2;

    return value;
  }

  /// Reads a 16-bit signed integer (-32768 to 32767).
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  /// Asserts bounds in debug mode if insufficient bytes are available.
  @pragma('vm:prefer-inline')
  int readInt16([Endian endian = .big]) {
    _checkBounds(2, 'Int16');

    final value = _ctx.data.getInt16(_ctx.offset, endian);
    _ctx.offset += 2;

    return value;
  }

  /// Reads a 32-bit unsigned integer (0 to 4,294,967,295).
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  /// Asserts bounds in debug mode if insufficient bytes are available.
  @pragma('vm:prefer-inline')
  int readUint32([Endian endian = .big]) {
    _checkBounds(4, 'Uint32');

    final value = _ctx.data.getUint32(_ctx.offset, endian);
    _ctx.offset += 4;
    return value;
  }

  /// Reads a 32-bit signed integer (-2,147,483,648 to 2,147,483,647).
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  /// Asserts bounds in debug mode if insufficient bytes are available.
  @pragma('vm:prefer-inline')
  int readInt32([Endian endian = .big]) {
    _checkBounds(4, 'Int32');
    final value = _ctx.data.getInt32(_ctx.offset, endian);
    _ctx.offset += 4;
    return value;
  }

  /// Reads a 64-bit unsigned integer.
  ///
  /// Note: Dart's integer precision is limited to 2^53 on web targets.
  /// [endian] specifies byte order (defaults to big-endian).
  /// Asserts bounds in debug mode if insufficient bytes are available.
  @pragma('vm:prefer-inline')
  int readUint64([Endian endian = .big]) {
    _checkBounds(8, 'Uint64');
    final value = _ctx.data.getUint64(_ctx.offset, endian);
    _ctx.offset += 8;
    return value;
  }

  /// Reads a 64-bit signed integer.
  ///
  /// Note: Dart's integer precision is limited to 2^53 on web targets.
  /// [endian] specifies byte order (defaults to big-endian).
  /// Asserts bounds in debug mode if insufficient bytes are available.
  @pragma('vm:prefer-inline')
  int readInt64([Endian endian = .big]) {
    _checkBounds(8, 'Int64');
    final value = _ctx.data.getInt64(_ctx.offset, endian);
    _ctx.offset += 8;
    return value;
  }

  /// Reads a 32-bit floating-point number (IEEE 754 single precision).
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  /// Asserts bounds in debug mode if insufficient bytes are available.
  @pragma('vm:prefer-inline')
  double readFloat32([Endian endian = .big]) {
    _checkBounds(4, 'Float32');

    final value = _ctx.data.getFloat32(_ctx.offset, endian);
    _ctx.offset += 4;

    return value;
  }

  /// Reads a 64-bit floating-point number (IEEE 754 double precision).
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  /// Asserts bounds in debug mode if insufficient bytes are available.
  @pragma('vm:prefer-inline')
  double readFloat64([Endian endian = .big]) {
    _checkBounds(8, 'Float64');

    final value = _ctx.data.getFloat64(_ctx.offset, endian);
    _ctx.offset += 8;
    return value;
  }

  /// Reads a sequence of bytes and returns them as a [Uint8List].
  ///
  /// Returns a view of the underlying buffer without copying data,
  /// which is efficient for large byte sequences.
  ///
  /// [length] specifies the number of bytes to read.
  /// Asserts bounds in debug mode if insufficient bytes are available.
  @pragma('vm:prefer-inline')
  Uint8List readBytes(int length) {
    assert(length >= 0, 'Length must be non-negative');
    _checkBounds(length, 'Bytes');

    // Create a view of the underlying buffer without copying
    final bOffset = _ctx.baseOffset;
    final bytes = _ctx.data.buffer.asUint8List(bOffset + _ctx.offset, length);

    _ctx.offset += length;

    return bytes;
  }

  /// Reads a UTF-8 encoded string of the specified byte length.
  ///
  /// [length] is the number of UTF-8 bytes to read (not the number of
  /// characters).
  /// The string is decoded directly from the buffer without copying.
  ///
  /// [allowMalformed] controls how invalid UTF-8 sequences are handled:
  /// - If true: replaces malformed sequences with U+FFFD (�)
  /// - If false (default): throws [FormatException] on invalid UTF-8
  ///
  /// Note: This reads a fixed number of bytes. For length-prefixed strings,
  /// read the length first (e.g., with [readVarInt]) then call this method.
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

  /// Reads bytes without advancing the read position.
  ///
  /// This allows inspecting upcoming data without consuming it.
  /// Useful for protocol parsing where you need to look ahead.
  ///
  /// [length] specifies the number of bytes to peek at.
  /// [offset] specifies where to start peeking (defaults to current position).
  ///
  /// Returns a view of the buffer without copying data.
  /// Asserts bounds in debug mode if peeking past buffer end.
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

  /// Advances the read position by the specified number of bytes.
  ///
  /// This is useful for skipping over data you don't need to process.
  /// More efficient than reading and discarding data.
  ///
  /// Asserts bounds in debug mode if skipping past buffer end.
  void skip(int length) {
    assert(length >= 0, 'Length must be non-negative');
    _checkBounds(length, 'Skip');

    _ctx.offset += length;
  }

  /// Resets the read position to the beginning of the buffer.
  ///
  /// This allows re-reading the same data without creating a new reader.
  @pragma('vm:prefer-inline')
  void reset() {
    _ctx.offset = 0;
  }

  /// Internal method to check if enough bytes are available to read.
  ///
  /// Throws an assertion error in debug mode if not enough bytes.
  @pragma('vm:prefer-inline')
  void _checkBounds(int bytes, String type, [int? offset]) {
    assert(
      (offset ?? _ctx.offset) + bytes <= _ctx.length,
      'Not enough bytes to read $type: required $bytes bytes, available '
      '${_ctx.length - _ctx.offset} bytes at offset ${_ctx.offset}',
    );
  }
}

/// Internal state holder for [BinaryReader].
///
/// Stores the buffer, read position, and provides efficient typed access
/// through [ByteData]. Separated from the extension type to enable
/// zero-cost abstractions and efficient inline operations.
final class _ReaderState {
  _ReaderState(Uint8List buffer)
    : list = buffer,
      data = ByteData.sublistView(buffer).asUnmodifiableView(),
      buffer = buffer.buffer,
      length = buffer.length,
      baseOffset = buffer.offsetInBytes,
      offset = 0;

  /// Direct access to the underlying byte list.
  final Uint8List list;

  /// Efficient view for typed data access (getInt32, getFloat64, etc.).
  final ByteData data;

  /// The underlying byte buffer.
  final ByteBuffer buffer;

  /// Total length of the buffer in bytes.
  final int length;

  /// Current read position in the buffer.
  late int offset;

  /// Offset of the buffer view within its underlying [ByteBuffer].
  /// Necessary for creating accurate subviews.
  final int baseOffset;
}
