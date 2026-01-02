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
/// // Read various data types
/// final id = reader.readUint32();
/// final value = reader.readFloat64();
/// // Read length-prefixed string
/// final stringLength = reader.readVarUint();
/// final text = reader.readString(stringLength);
/// // Check remaining data
/// print('Bytes left: ${reader.availableBytes}');
/// ```
extension type const BinaryReader._(_ReaderState _rs) {
  /// Creates a new [BinaryReader] from the given byte buffer.
  ///
  /// The reader will start at position 0 and can read up to `buffer.length`
  /// bytes.
  BinaryReader(Uint8List buffer) : this._(_ReaderState(buffer));

  /// Returns the number of bytes remaining to be read.
  @pragma('vm:prefer-inline')
  int get availableBytes => _rs.length - _rs.offset;

  /// Returns the current read position in the buffer.
  @pragma('vm:prefer-inline')
  int get offset => _rs.offset;

  /// Returns the total length of the buffer in bytes.
  @pragma('vm:prefer-inline')
  int get length => _rs.length;

  /// Reads an unsigned variable-length integer encoded using VarInt format.
  ///
  /// VarInt encoding uses the lower 7 bits of each byte for data and the
  /// highest bit as a continuation flag. This format is space-efficient
  /// for small unsigned numbers (1-5 bytes for typical 32-bit values).
  ///
  /// The algorithm:
  /// 1. Read a byte and extract the lower 7 bits
  /// 2. If the 8th bit is set, continue reading
  /// 3. Shift and combine all 7-bit chunks
  ///
  /// **Use this for:** Lengths, counts, sizes, unsigned IDs.
  ///
  /// For signed integers (especially with negative values), use [readVarInt]
  /// which uses ZigZag decoding for better compression of negative numbers.
  ///
  /// Example:
  /// ```dart
  /// final count = reader.readVarUint();        // Read array length
  /// for (var i = 0; i < count; i++) {
  ///   // Process array elements
  /// }
  /// ```
  ///
  /// Throws [FormatException] if the VarInt exceeds 10 bytes (malformed data).
  /// Asserts bounds in debug mode if attempting to read past buffer end.
  @pragma('vm:prefer-inline')
  int readVarUint() {
    final list = _rs.list;
    final len = _rs.length;
    var offset = _rs.offset;

    if (offset >= len) {
      throw RangeError('VarInt out of bounds: offset=$offset length=$len');
    }

    // Fast path: single byte (0-127) — most common case
    var byte = list[offset++];
    if ((byte & 0x80) == 0) {
      _rs.offset = offset;
      return byte;
    }

    // Multi-byte VarInt (optimized for 2-3 byte case)
    var result = byte & 0x7f;
    var shift = 7;

    // Process remaining bytes: up to 9 more (total 10 max)
    for (var i = 1; i < 10; i++) {
      if (offset >= len) {
        throw RangeError(
          'VarInt out of bounds: offset=$offset length=$len (truncated)',
        );
      }
      byte = list[offset++];

      result |= (byte & 0x7f) << shift;

      if ((byte & 0x80) == 0) {
        _rs.offset = offset;
        return result;
      }

      shift += 7;
    }

    throw const FormatException('VarInt is too long (more than 10 bytes)');
  }

  /// Reads a signed variable-length integer using ZigZag decoding.
  ///
  /// ZigZag encoding maps signed integers to unsigned values such that
  /// small absolute values (both positive and negative) use fewer bytes:
  /// - 0 => 0, -1 => 1, 1 => 2, -2 => 3, 2 => 4, etc.
  ///
  /// First reads an unsigned VarInt, then applies ZigZag decoding.
  /// Decoding formula: (n >>> 1) ^ -(n & 1)
  /// This reverses the encoding: (n << 1) ^ (n >> 63)
  ///
  /// **Use this for:** Signed values, deltas, offsets, coordinates.
  ///
  /// Example:
  /// ```dart
  /// final delta = reader.readVarInt();  // Can be positive or negative
  /// final position = lastPosition + delta;
  /// ```
  @pragma('vm:prefer-inline')
  int readVarInt() {
    final v = readVarUint();
    // Decode: right shift by 1, XOR with sign-extended LSB
    return (v >>> 1) ^ -(v & 1);
  }

  /// Reads an 8-bit unsigned integer (0-255).
  ///
  /// Example:
  /// ```dart
  /// final version = reader.readUint8();  // Protocol version
  /// ```
  ///
  /// Asserts bounds in debug mode if insufficient bytes are available.
  @pragma('vm:prefer-inline')
  int readUint8() {
    _checkBounds(1, 'Uint8');

    return _rs.data.getUint8(_rs.offset++);
  }

  /// Reads an 8-bit signed integer (-128 to 127).
  ///
  /// Example:
  /// ```dart
  /// final offset = reader.readInt8();  // Small delta value
  /// ```
  ///
  /// Asserts bounds in debug mode if insufficient bytes are available.
  @pragma('vm:prefer-inline')
  int readInt8() {
    _checkBounds(1, 'Int8');

    return _rs.data.getInt8(_rs.offset++);
  }

  /// Reads a 16-bit unsigned integer (0-65535).
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  ///
  /// Example:
  /// ```dart
  /// final port = reader.readUint16();  // Network port number
  /// ```
  ///
  /// Asserts bounds in debug mode if insufficient bytes are available.
  @pragma('vm:prefer-inline')
  int readUint16([Endian endian = .big]) {
    _checkBounds(2, 'Uint16');

    final value = _rs.data.getUint16(_rs.offset, endian);
    _rs.offset += 2;

    return value;
  }

  /// Reads a 16-bit signed integer (-32768 to 32767).
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  ///
  /// Example:
  /// ```dart
  /// final temperature = reader.readInt16();  // -100 to 100°C
  /// ```
  ///
  /// Asserts bounds in debug mode if insufficient bytes are available.
  @pragma('vm:prefer-inline')
  int readInt16([Endian endian = .big]) {
    _checkBounds(2, 'Int16');

    final value = _rs.data.getInt16(_rs.offset, endian);
    _rs.offset += 2;

    return value;
  }

  /// Reads a 32-bit unsigned integer (0 to 4,294,967,295).
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  ///
  /// Example:
  /// ```dart
  /// final timestamp = reader.readUint32();  // Unix timestamp
  /// ```
  ///
  /// Asserts bounds in debug mode if insufficient bytes are available.
  @pragma('vm:prefer-inline')
  int readUint32([Endian endian = .big]) {
    _checkBounds(4, 'Uint32');

    final value = _rs.data.getUint32(_rs.offset, endian);
    _rs.offset += 4;
    return value;
  }

  /// Reads a 32-bit signed integer (-2,147,483,648 to 2,147,483,647).
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  ///
  /// Example:
  /// ```dart
  /// final coordinate = reader.readInt32();  // GPS coordinate
  /// ```
  ///
  /// Asserts bounds in debug mode if insufficient bytes are available.
  @pragma('vm:prefer-inline')
  int readInt32([Endian endian = .big]) {
    _checkBounds(4, 'Int32');
    final value = _rs.data.getInt32(_rs.offset, endian);
    _rs.offset += 4;
    return value;
  }

  /// Reads a 64-bit unsigned integer.
  ///
  /// **Note:** Since Dart's `int` type is a signed 64-bit integer, this method
  /// will return negative values for numbers greater than 2^63 - 1.
  ///
  /// On web targets, precision is limited to 2^53.
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  ///
  /// Example:
  /// ```dart
  /// final id = reader.readUint64();  // Large unique identifier
  /// ```
  ///
  /// Asserts bounds in debug mode if insufficient bytes are available.
  @pragma('vm:prefer-inline')
  int readUint64([Endian endian = .big]) {
    _checkBounds(8, 'Uint64');
    final value = _rs.data.getUint64(_rs.offset, endian);
    _rs.offset += 8;
    return value;
  }

  /// Reads a 64-bit signed integer.
  ///
  /// Note: Dart's integer precision is limited to 2^53 on web targets.
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  ///
  /// Example:
  /// ```dart
  /// final nanoseconds = reader.readInt64();  // High-precision time
  /// ```
  ///
  /// Asserts bounds in debug mode if insufficient bytes are available.
  @pragma('vm:prefer-inline')
  int readInt64([Endian endian = .big]) {
    _checkBounds(8, 'Int64');
    final value = _rs.data.getInt64(_rs.offset, endian);
    _rs.offset += 8;
    return value;
  }

  /// Reads a 32-bit floating-point number (IEEE 754 single precision).
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  ///
  /// Example:
  /// ```dart
  /// final temperature = reader.readFloat32();  // 25.5°C
  /// ```
  ///
  /// Asserts bounds in debug mode if insufficient bytes are available.
  @pragma('vm:prefer-inline')
  double readFloat32([Endian endian = .big]) {
    _checkBounds(4, 'Float32');

    final value = _rs.data.getFloat32(_rs.offset, endian);
    _rs.offset += 4;

    return value;
  }

  /// Reads a 64-bit floating-point number (IEEE 754 double precision).
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  ///
  /// Example:
  /// ```dart
  /// final price = reader.readFloat64();  // $123.45
  /// ```
  ///
  /// Asserts bounds in debug mode if insufficient bytes are available.
  @pragma('vm:prefer-inline')
  double readFloat64([Endian endian = .big]) {
    _checkBounds(8, 'Float64');

    final value = _rs.data.getFloat64(_rs.offset, endian);
    _rs.offset += 8;
    return value;
  }

  /// Reads a sequence of bytes and returns them as a [Uint8List].
  ///
  /// Returns a view of the underlying buffer without copying data,
  /// which is efficient for large byte sequences.
  ///
  /// [length] specifies the number of bytes to read.
  ///
  /// Example:
  /// ```dart
  /// final header = reader.readBytes(4);  // Read 4-byte header
  /// final payload = reader.readBytes(256);  // Read payload
  /// ```
  ///
  /// **Performance:** Zero-copy operation using buffer views.
  ///
  /// Asserts bounds in debug mode if insufficient bytes are available.
  @pragma('vm:prefer-inline')
  Uint8List readBytes(int length) {
    if (length < 0) {
      throw RangeError.value(length, 'length', 'Length must be non-negative');
    }
    _checkBounds(length, 'Bytes');

    // Create a view of the underlying buffer without copying
    final bOffset = _rs.baseOffset;
    final bytes = _rs.data.buffer.asUint8List(bOffset + _rs.offset, length);

    _rs.offset += length;

    return bytes;
  }

  /// Reads all remaining bytes from the current position to the end of the
  /// buffer.
  ///
  /// Returns a view of the remaining bytes without copying data.
  /// Useful for reading trailing data or payloads of unknown length.
  ///
  /// Example:
  /// ```dart
  /// final payload = reader.readRemainingBytes();
  /// print('Payload length: ${payload.length}');
  /// ```
  @pragma('vm:prefer-inline')
  Uint8List readRemainingBytes() => readBytes(availableBytes);

  /// Reads a length-prefixed byte array.
  ///
  /// First reads the length as a VarUint, then reads that many bytes.
  /// Returns a view of the underlying buffer without copying data.
  ///
  /// This is the counterpart to `BinaryWriter.writeVarBytes`.
  ///
  /// Example:
  /// ```dart
  /// final data = reader.readVarBytes();
  /// print('Read ${data.length} bytes');
  /// ```
  ///
  /// This is equivalent to:
  /// ```dart
  /// final length = reader.readVarUint();
  /// final data = reader.readBytes(length);
  /// ```
  ///
  /// **Performance:** Zero-copy operation using buffer views.
  ///
  /// Asserts bounds in debug mode if insufficient bytes are available.
  @pragma('vm:prefer-inline')
  Uint8List readVarBytes() {
    final length = readVarUint();
    return readBytes(length);
  }

  /// Reads a UTF-8 encoded string of the specified byte length.
  ///
  /// [length] is the number of UTF-8 bytes to read (not the number of
  /// characters). The string is decoded directly from the buffer without
  /// copying.
  ///
  /// [allowMalformed] controls how invalid UTF-8 sequences are handled:
  /// - If true: replaces malformed sequences with U+FFFD (�)
  /// - If false (default): throws [FormatException] on invalid UTF-8
  ///
  /// **Common pattern:** Read length first, then string:
  ///
  /// ```dart
  /// // Length-prefixed string
  /// final byteLength = reader.readVarUint();
  /// final text = reader.readString(byteLength);
  /// // Fixed-length magic string
  /// final magic = reader.readString(4);  // e.g., "PNG\n"
  /// ```
  ///
  /// **Performance:** Zero-copy operation using buffer views.
  @pragma('vm:prefer-inline')
  String readString(int length, {bool allowMalformed = false}) {
    if (length == 0) {
      return '';
    }

    _checkBounds(length, 'String');

    final bOffset = _rs.baseOffset;
    final view = _rs.data.buffer.asUint8List(bOffset + _rs.offset, length);
    _rs.offset += length;

    return utf8.decode(view, allowMalformed: allowMalformed);
  }

  /// Reads a length-prefixed UTF-8 encoded string.
  ///
  /// First reads the UTF-8 byte length as a VarUint, then reads and decodes
  /// the UTF-8 string data.
  ///
  /// [allowMalformed] controls how invalid UTF-8 sequences are handled:
  /// - If true: replaces invalid sequences with U+FFFD (�)
  /// - If false (default): throws [FormatException] on malformed UTF-8
  ///
  /// This is the counterpart to `BinaryWriter.writeVarString`.
  ///
  /// Example:
  /// ```dart
  /// final text = reader.readVarString();
  /// print(text); // 'Hello, 世界! 🌍'
  /// ```
  ///
  /// Throws [RangeError] if attempting to read past buffer end.
  @pragma('vm:prefer-inline')
  String readVarString({bool allowMalformed = false}) {
    final length = readVarUint();
    return readString(length, allowMalformed: allowMalformed);
  }

  /// Reads a boolean value (1 byte).
  ///
  /// A byte value of 0 is interpreted as `false`, any non-zero value as `true`.
  ///
  /// Example:
  /// ```dart
  /// final isActive = reader.readBool();  // Read active flag
  /// ```
  /// Asserts bounds in debug mode if insufficient bytes are available.
  @pragma('vm:prefer-inline')
  bool readBool() {
    final value = readUint8();
    return value != 0;
  }

  /// Checks if there are at least [length] bytes available to read.
  ///
  /// Returns `true` if enough bytes are available, `false` otherwise.
  ///
  /// Useful for conditional reads when the data format may vary.
  /// Example:
  /// ```dart
  /// if (reader.hasBytes(4)) {
  ///   final value = reader.readUint32();
  ///   // Process value
  /// } else {
  ///   // Handle missing data
  /// }
  /// ```
  @pragma('vm:prefer-inline')
  bool hasBytes(int length) {
    if (length < 0) {
      throw RangeError.value(length, 'length', 'Length must be non-negative');
    }
    return (_rs.offset + length) <= _rs.length;
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
  ///
  /// Example:
  /// ```dart
  /// // Check message type without consuming the byte
  /// final typeBytes = reader.peekBytes(1);
  /// if (typeBytes[0] == 0x42) {
  ///   // Handle type 0x42
  /// }
  /// final actualType = reader.readUint8();  // Now read it
  /// ```
  @pragma('vm:prefer-inline')
  Uint8List peekBytes(int length, [int? offset]) {
    if (length < 0) {
      throw RangeError.value(length, 'length', 'Length must be non-negative');
    }

    if (length == 0) {
      return Uint8List(0);
    }

    final peekOffset = offset ?? _rs.offset;
    _checkBounds(length, 'Peek Bytes', peekOffset);

    final bOffset = _rs.baseOffset;

    return _rs.data.buffer.asUint8List(bOffset + peekOffset, length);
  }

  /// Advances the read position by the specified number of bytes.
  ///
  /// This is useful for skipping over data you don't need to process.
  /// More efficient than reading and discarding data.
  ///
  /// Asserts bounds in debug mode if skipping past buffer end.
  ///
  /// Example:
  /// ```dart
  /// // Skip optional padding or reserved fields
  /// reader.skip(4);  // Skip 4 bytes of padding
  /// // Skip unknown message payload
  /// final payloadSize = reader.readUint32();
  /// reader.skip(payloadSize);
  /// ```
  void skip(int length) {
    if (length < 0) {
      throw RangeError.value(length, 'length', 'Length must be non-negative');
    }
    _checkBounds(length, 'Skip');

    _rs.offset += length;
  }

  /// Sets the read position to the specified byte offset.
  ///
  /// This allows random access within the buffer.
  /// Asserts bounds in debug mode if position is out of range.
  ///
  /// Example:
  /// ```dart
  /// // Jump to a specific offset to read data
  /// reader.seek(128);  // Move to byte offset 128
  /// final value = reader.readUint32();
  /// ```
  @pragma('vm:prefer-inline')
  void seek(int position) {
    if (position < 0 || position > _rs.length) {
      throw RangeError.range(position, 0, _rs.length, 'position');
    }
    _rs.offset = position;
  }

  /// Moves the read position backwards by the specified number of bytes.
  ///
  /// This allows re-reading previously read data.
  /// Asserts bounds in debug mode if rewinding before the start of the buffer.
  ///
  /// Example:
  /// ```dart
  /// // Re-read the last 4 bytes
  /// reader.rewind(4);
  /// final value = reader.readUint32();
  /// ```
  @pragma('vm:prefer-inline')
  void rewind(int length) {
    if (length < 0) {
      throw RangeError.value(length, 'length', 'Length must be non-negative');
    }
    if (_rs.offset - length < 0) {
      throw RangeError(
        'Cannot rewind $length bytes from offset ${_rs.offset}',
      );
    }
    _rs.offset -= length;
  }

  /// Resets the read position to the beginning of the buffer.
  ///
  /// This allows re-reading the same data without creating a new reader.
  @pragma('vm:prefer-inline')
  void reset() {
    _rs.offset = 0;
  }

  /// Internal method to check if enough bytes are available to read.
  ///
  /// Throws an assertion error in debug mode if not enough bytes.
  @pragma('vm:prefer-inline')
  void _checkBounds(int bytes, String type, [int? offset]) {
    if (bytes < 0) {
      throw RangeError.value(bytes, 'bytes', 'Bytes must be non-negative');
    }

    final start = offset ?? _rs.offset;
    final end = start + bytes;

    if (start < 0 || start > _rs.length) {
      throw RangeError.range(start, 0, _rs.length, 'offset');
    }

    if (end > _rs.length) {
      throw RangeError(
        'Not enough bytes to read $type: required $bytes bytes, available '
        '${_rs.length - _rs.offset} bytes at offset ${_rs.offset}',
      );
    }
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
