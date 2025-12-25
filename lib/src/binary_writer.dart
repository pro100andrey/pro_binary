import 'dart:typed_data';

/// A high-performance binary writer for encoding data into a byte buffer.
///
/// Provides methods for writing various data types including:
/// - Variable-length integers (VarInt, ZigZag)
/// - Fixed-width integers (8, 16, 32, 64-bit signed and unsigned)
/// - Floating-point numbers (32 and 64-bit)
/// - Byte arrays
/// - UTF-8 encoded strings
///
/// The writer automatically expands its internal buffer as needed.
///
/// Example:
/// ```dart
/// final writer = BinaryWriter();
///
/// // Write various data types
/// writer.writeUint32(42);
/// writer.writeFloat64(3.14);
/// // Write length-prefixed string
/// final text = 'Hello, World!';
/// final utf8Bytes = utf8.encode(text);
/// writer.writeVarUint(utf8Bytes.length);
/// writer.writeString(text);
/// // Extract bytes and optionally reuse writer
/// final bytes = writer.takeBytes(); // Resets writer for reuse
/// // or: final bytes = writer.toBytes(); // Keeps writer state
/// ```
extension type BinaryWriter._(_WriterState _ws) {
  /// Creates a new [BinaryWriter] with the specified initial buffer size.
  ///
  /// The buffer will automatically expand as needed when writing data.
  /// A larger initial size can improve performance if you know approximately
  /// how much data will be written.
  ///
  /// [initialBufferSize] defaults to 128 bytes.
  BinaryWriter({int initialBufferSize = 128})
    : this._(_WriterState(initialBufferSize));

  /// Returns the total number of bytes written to the buffer.
  int get bytesWritten => _ws.offset;

  /// Writes an unsigned variable-length integer using VarInt encoding.
  ///
  /// VarInt encoding uses the lower 7 bits of each byte for data and the
  /// highest bit as a continuation flag. This is more space-efficient for
  /// small unsigned numbers (1-5 bytes for typical 32-bit values).
  ///
  /// **When to use:**
  /// - Counts, lengths, array sizes (always non-negative)
  /// - IDs, indices, and other naturally unsigned values
  /// - When values are typically small (< 128 uses only 1 byte)
  ///
  /// **Performance:** Values 0-127 use fast single-byte path.
  ///
  /// For signed integers that may be negative, use [writeVarInt] instead,
  /// which uses ZigZag encoding to efficiently handle negative values.
  ///
  /// Example:
  /// ```dart
  /// writer.writeVarUint(42);        // 1 byte
  /// writer.writeVarUint(300);       // 2 bytes
  /// writer.writeVarUint(1000000);   // 3 bytes
  /// ```
  @pragma('vm:prefer-inline')
  void writeVarUint(int value) {
    // Fast path for single-byte VarInt
    if (value < 0x80 && value >= 0) {
      _ws.ensureOneByte();
      _ws.list[_ws.offset++] = value;
      return;
    }

    _ws.ensureSize(10);

    var v = value;
    final list = _ws.list;
    var offset = _ws.offset;

    while (v >= 0x80) {
      list[offset++] = (v & 0x7F) | 0x80;
      v >>>= 7;
    }

    list[offset++] = v & 0x7F;
    _ws.offset = offset;
  }

  /// Writes a signed variable-length integer using ZigZag encoding.
  ///
  /// ZigZag encoding maps signed integers to unsigned integers in a way that
  /// small absolute values (both positive and negative) use fewer bytes:
  /// - 0 => 0, -1 => 1, 1 => 2, -2 => 3, 2 => 4, etc.
  ///
  /// The encoded value is then written using VarInt format. This is more
  /// efficient than [writeVarUint] for signed values that may be negative.
  ///
  /// **When to use:**
  /// - Signed values where negatives are common (deltas, offsets)
  /// - Values centered around zero
  /// - Temperature readings, coordinate deltas, etc.
  ///
  /// **Performance:** Small absolute values (both + and -) encode efficiently.
  ///
  /// Example:
  /// ```dart
  /// writer.writeVarInt(0);    // 1 byte
  /// writer.writeVarInt(-1);   // 1 byte
  /// writer.writeVarInt(42);   // 1 byte
  /// writer.writeVarInt(-42);  // 1 byte
  /// ```
  void writeVarInt(int value) {
    // ZigZag: (n << 1) ^ (n >> 63)
    // Maps: 0=>0, -1=>1, 1=>2, -2=>3, 2=>4, -3=>5, 3=>6
    final encoded = (value << 1) ^ (value >> value.bitLength);
    writeVarUint(encoded);
  }

  /// Writes an 8-bit unsigned integer (0-255).
  ///
  /// Example:
  /// ```dart
  /// writer.writeUint8(0x42);  // Write message type
  /// ```
  ///
  /// Throws [RangeError] if [value] is outside the valid range.
  @pragma('vm:prefer-inline')
  void writeUint8(int value) {
    _checkRange(value, 0, 255, 'Uint8');
    _ws.ensureOneByte();

    _ws.list[_ws.offset++] = value;
  }

  /// Writes an 8-bit signed integer (-128 to 127).
  ///
  /// Example:
  /// ```dart
  /// writer.writeInt8(-50);  // Write temperature offset
  /// ```
  ///
  /// Throws [RangeError] if [value] is outside the valid range.
  @pragma('vm:prefer-inline')
  void writeInt8(int value) {
    _checkRange(value, -128, 127, 'Int8');
    _ws.ensureOneByte();

    _ws.list[_ws.offset++] = value & 0xFF;
  }

  /// Writes a 16-bit unsigned integer (0-65535).
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  ///
  /// Example:
  /// ```dart
  /// writer.writeUint16(8080);  // Port number
  /// ```
  ///
  /// Throws [RangeError] if [value] is outside the valid range.
  @pragma('vm:prefer-inline')
  void writeUint16(int value, [Endian endian = .big]) {
    _checkRange(value, 0, 65535, 'Uint16');
    _ws.ensureTwoBytes();

    _ws.data.setUint16(_ws.offset, value, endian);
    _ws.offset += 2;
  }

  /// Writes a 16-bit signed integer (-32768 to 32767).
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  ///
  /// Example:
  /// ```dart
  /// writer.writeInt16(-100);  // Temperature in Celsius
  /// ```
  ///
  /// Throws [RangeError] if [value] is outside the valid range.
  @pragma('vm:prefer-inline')
  void writeInt16(int value, [Endian endian = .big]) {
    _checkRange(value, -32768, 32767, 'Int16');
    _ws.ensureTwoBytes();

    _ws.data.setInt16(_ws.offset, value, endian);
    _ws.offset += 2;
  }

  /// Writes a 32-bit unsigned integer (0 to 4,294,967,295).
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  ///
  /// Example:
  /// ```dart
  /// writer.writeUint32(1640995200);  // Unix timestamp
  /// ```
  ///
  /// Throws [RangeError] if [value] is outside the valid range.
  @pragma('vm:prefer-inline')
  void writeUint32(int value, [Endian endian = .big]) {
    _checkRange(value, 0, 4294967295, 'Uint32');
    _ws.ensureFourBytes();

    _ws.data.setUint32(_ws.offset, value, endian);
    _ws.offset += 4;
  }

  /// Writes a 32-bit signed integer (-2,147,483,648 to 2,147,483,647).
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  ///
  /// Example:
  /// ```dart
  /// writer.writeInt32(-500000);  // Account balance in cents
  /// ```
  ///
  /// Throws [RangeError] if [value] is outside the valid range.
  @pragma('vm:prefer-inline')
  void writeInt32(int value, [Endian endian = .big]) {
    _checkRange(value, -2147483648, 2147483647, 'Int32');
    _ws.ensureFourBytes();

    _ws.data.setInt32(_ws.offset, value, endian);
    _ws.offset += 4;
  }

  /// Writes a 64-bit unsigned integer.
  ///
  /// **Note:** Since Dart's `int` type is a signed 64-bit integer, this method
  /// is limited to the range 0 to 2^63 - 1 (9,223,372,036,854,775,807).
  /// Values above this cannot be represented as positive integers in Dart.
  ///
  /// On web targets, precision is further limited to 2^53.
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  ///
  /// Example:
  /// ```dart
  /// writer.writeUint64(9007199254740991);  // Max safe JS int
  /// ```
  ///
  /// Throws [RangeError] if [value] is outside the valid range.
  @pragma('vm:prefer-inline')
  void writeUint64(int value, [Endian endian = .big]) {
    _checkRange(value, 0, 9223372036854775807, 'Uint64');
    _ws.ensureEightBytes();

    _ws.data.setUint64(_ws.offset, value, endian);
    _ws.offset += 8;
  }

  /// Writes a 64-bit signed integer.
  ///
  /// Note: Dart's integer precision is limited to 2^53 for web targets.
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  ///
  /// Example:
  /// ```dart
  /// writer.writeInt64(1234567890123456);  // Large ID
  /// ```
  ///
  /// Throws [RangeError] if [value] is outside the valid range.
  @pragma('vm:prefer-inline')
  void writeInt64(int value, [Endian endian = .big]) {
    _checkRange(value, -9223372036854775808, 9223372036854775807, 'Int64');
    _ws.ensureEightBytes();

    _ws.data.setInt64(_ws.offset, value, endian);
    _ws.offset += 8;
  }

  /// Writes a 32-bit floating-point number (IEEE 754 single precision).
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  ///
  /// Example:
  /// ```dart
  /// writer.writeFloat32(3.14);  // Pi approximation
  /// ```
  @pragma('vm:prefer-inline')
  void writeFloat32(double value, [Endian endian = .big]) {
    _ws.ensureFourBytes();
    _ws.data.setFloat32(_ws.offset, value, endian);
    _ws.offset += 4;
  }

  /// Writes a 64-bit floating-point number (IEEE 754 double precision).
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  ///
  /// Example:
  /// ```dart
  /// writer.writeFloat64(3.14159265359);  // High-precision pi
  /// ```
  @pragma('vm:prefer-inline')
  void writeFloat64(double value, [Endian endian = .big]) {
    _ws.ensureEightBytes();
    _ws.data.setFloat64(_ws.offset, value, endian);
    _ws.offset += 8;
  }

  /// Writes a sequence of bytes from the given list.
  ///
  /// [offset] specifies the starting position in [bytes] (defaults to 0).
  /// [length] specifies how many bytes to write (defaults to remaining bytes).
  ///
  /// Example:
  /// ```dart
  /// final data = [1, 2, 3, 4, 5];
  /// writer.writeBytes(data);           // Write all 5 bytes
  /// writer.writeBytes(data, 2);        // Write [3, 4, 5]
  /// writer.writeBytes(data, 1, 3);     // Write [2, 3, 4]
  /// ```
  @pragma('vm:prefer-inline')
  void writeBytes(List<int> bytes, [int offset = 0, int? length]) {
    final len = length ?? (bytes.length - offset);
    _ws.ensureSize(len);

    _ws.list.setRange(_ws.offset, _ws.offset + len, bytes, offset);
    _ws.offset += len;
  }

  /// Writes a length-prefixed byte array.
  ///
  /// First writes the length as a VarUint, followed by the byte data.
  /// This is useful for serializing binary blobs of unknown size.
  ///
  /// This is the counterpart to `BinaryReader.readVarBytes`.
  ///
  /// Example:
  /// ```dart
  /// final imageData = [/* ... binary data ... */];
  /// writer.writeVarBytes(imageData);
  /// // Length is automatically written as VarUint
  /// ```
  ///
  /// This is equivalent to:
  /// ```dart
  /// writer.writeVarUint(bytes.length);
  /// writer.writeBytes(bytes);
  /// ```
  @pragma('vm:prefer-inline')
  void writeVarBytes(List<int> bytes) {
    writeVarUint(bytes.length);
    writeBytes(bytes);
  }

  /// Writes a UTF-8 encoded string.
  ///
  /// The string is encoded directly to UTF-8 bytes with optimized handling for:
  /// - ASCII fast path (unrolled loops for better performance)
  /// - Multi-byte UTF-8 sequences (Cyrillic, CJK, emojis, etc.)
  /// - Proper surrogate pair handling for characters outside the BMP
  ///
  /// [allowMalformed] controls how invalid UTF-16 sequences are handled:
  /// - If true (default): replaces lone surrogates with U+FFFD (�)
  /// - If false: throws [FormatException] on malformed input
  ///
  /// **Important:** This does NOT write the string length. For self-describing
  /// data, write the length first:
  ///
  /// Example:
  /// ```dart
  /// // Length-prefixed string (recommended for most protocols)
  /// final text = 'Hello, 世界! 🌍';
  /// final utf8Bytes = utf8.encode(text);
  /// writer.writeVarUint(utf8Bytes.length);  // Write byte length
  /// writer.writeString(text);                // Write string data
  /// // Or for simple fixed-length strings:
  /// writer.writeString('MAGIC');  // No length prefix needed
  /// ```
  ///
  /// **Performance:** Highly optimized for ASCII-heavy strings.
  @pragma('vm:prefer-inline')
  void writeString(String value, {bool allowMalformed = true}) {
    final len = value.length;
    if (len == 0) {
      return;
    }

    // Pre-allocate buffer: worst case is 3 bytes per UTF-16 code unit
    // Most common case: 1 byte/char (ASCII) or 2-3 bytes/char (non-ASCII)
    // Surrogate pairs: 2 units -> 4 bytes UTF-8 (2 bytes per unit average)
    _ws.ensureSize(len * 3);

    final list = _ws.list;
    var offset = _ws.offset;
    var i = 0;

    while (i < len) {
      var c = value.codeUnitAt(i);

      if (c < 0x80) {
        // -------------------------------------------------------
        // ASCII Fast Path: Optimized for common case
        // Most strings contain primarily ASCII, so we optimize this path
        // with unrolled loops to process 4 characters at a time.
        // -------------------------------------------------------
        list[offset++] = c;
        i++;

        // Unrolled loop: process 4 ASCII chars at once
        // Bitwise OR (|) checks if any char >= 0x80 in one operation
        while (i <= len - 4) {
          final c0 = value.codeUnitAt(i);
          final c1 = value.codeUnitAt(i + 1);
          final c2 = value.codeUnitAt(i + 2);
          final c3 = value.codeUnitAt(i + 3);

          if ((c0 | c1 | c2 | c3) < 0x80) {
            list[offset] = c0;
            list[offset + 1] = c1;
            list[offset + 2] = c2;
            list[offset + 3] = c3;
            offset += 4;
            i += 4;
          } else {
            break;
          }
        }

        // Catch remaining ASCII characters before multi-byte logic
        while (i < len) {
          c = value.codeUnitAt(i);
          if (c >= 0x80) {
            break;
          }
          list[offset++] = c;
          i++;
        }

        if (i == len) {
          break;
        }
      }

      // -------------------------------------------------------
      // Multi-byte UTF-8 encoding
      // UTF-8 uses 2-4 bytes for non-ASCII characters
      // -------------------------------------------------------
      if (c < 0x800) {
        // 2-byte sequence: U+0080 to U+07FF
        // Covers: Latin Extended, Greek, Cyrillic, Arabic, Hebrew, etc.
        list[offset++] = 0xC0 | (c >> 6);
        list[offset++] = 0x80 | (c & 0x3F);
        i++;
      } else if (c < 0xD800 || c > 0xDFFF) {
        // 3-byte sequence: U+0800 to U+FFFF (excluding surrogates)
        // Covers: CJK characters, most world scripts, symbols, etc.
        list[offset++] = 0xE0 | (c >> 12);
        list[offset++] = 0x80 | ((c >> 6) & 0x3F);
        list[offset++] = 0x80 | (c & 0x3F);
        i++;
      } else if (c <= 0xDBFF && i + 1 < len) {
        // 4-byte sequence: U+10000 to U+10FFFF via surrogate pairs
        // High surrogate (0xD800-0xDBFF) must be followed by low
        // (0xDC00-0xDFFF)
        // Covers: Emojis, historic scripts, rare CJK, musical notation, etc.
        final next = value.codeUnitAt(i + 1);
        if (next >= 0xDC00 && next <= 0xDFFF) {
          // Valid surrogate pair: combine high and low surrogates
          // Formula: 0x10000 + ((high & 0x3FF) << 10) + (low & 0x3FF)
          final codePoint = 0x10000 + ((c & 0x3FF) << 10) + (next & 0x3FF);
          list[offset++] = 0xF0 | (codePoint >> 18);
          list[offset++] = 0x80 | ((codePoint >> 12) & 0x3F);
          list[offset++] = 0x80 | ((codePoint >> 6) & 0x3F);
          list[offset++] = 0x80 | (codePoint & 0x3F);
          i += 2;
        } else {
          // Invalid: high surrogate not followed by low surrogate
          offset = _handleMalformed(value, i, offset, allowMalformed);
          i++;
        }
      } else {
        // Malformed UTF-16: lone low surrogate or high surrogate at end
        offset = _handleMalformed(value, i, offset, allowMalformed);
        i++;
      }
    }

    _ws.offset = offset;
  }

  /// Writes a length-prefixed UTF-8 encoded string.
  ///
  /// First writes the UTF-8 byte length as a VarUint, followed by the
  /// UTF-8 encoded string data.
  ///
  /// [allowMalformed] controls how invalid UTF-16 sequences are handled:
  /// - If true (default): replaces lone surrogates with U+FFFD (�)
  /// - If false: throws [FormatException] on malformed input
  ///
  /// Example:
  /// ```dart
  /// final text = 'Hello, 世界! 🌍';
  /// writer.writeVarString(text);
  /// ```
  /// This is equivalent to:
  /// ```dart
  /// final utf8Bytes = utf8.encode(text);
  /// writer.writeVarUint(utf8Bytes.length);
  /// writer.writeString(text);
  /// ```
  @pragma('vm:prefer-inline')
  void writeVarString(String value, {bool allowMalformed = true}) {
    final utf8Length = getUtf8Length(value);
    writeVarUint(utf8Length);
    writeString(value, allowMalformed: allowMalformed);
  }

  /// Extracts all written bytes and resets the writer.
  ///
  /// After calling this method, the writer is reset and ready for reuse.
  /// This is more efficient than creating a new writer for each operation.
  ///
  /// Returns a view of the written bytes (no copying occurs).
  ///
  /// **Use case:** When you're done with this batch and want to start fresh.
  ///
  /// Example:
  /// ```dart
  /// final writer = BinaryWriter();
  /// writer.writeUint32(42);
  /// final packet1 = writer.takeBytes();  // Get bytes and reset
  /// writer.writeUint32(100);             // Writer is ready for reuse
  /// final packet2 = writer.takeBytes();
  /// ```
  @pragma('vm:prefer-inline')
  Uint8List takeBytes() {
    final result = Uint8List.sublistView(_ws.list, 0, _ws.offset);
    _ws._initializeBuffer();
    return result;
  }

  /// Returns a view of the written bytes without resetting the writer.
  ///
  /// Unlike [takeBytes], this does not reset the writer's state.
  /// Subsequent writes will continue appending to the buffer.
  ///
  /// **Use case:** When you need to inspect or copy data mid-stream.
  ///
  /// Example:
  /// ```dart
  /// final writer = BinaryWriter();
  /// writer.writeUint32(42);
  /// final snapshot = writer.toBytes();  // Peek at current data
  /// writer.writeUint32(100);            // Continue writing
  /// final final = writer.takeBytes();   // Get all data
  /// ```
  @pragma('vm:prefer-inline')
  Uint8List toBytes() => Uint8List.sublistView(_ws.list, 0, _ws.offset);

  /// Resets the writer to its initial state, discarding all written data.
  @pragma('vm:prefer-inline')
  void reset() => _ws._initializeBuffer();

  /// Handles malformed UTF-16 sequences (lone surrogates).
  ///
  /// If [allow] is false, throws [FormatException].
  /// Otherwise, writes the Unicode replacement character U+FFFD (�)
  /// encoded as UTF-8: 0xEF 0xBF 0xBD
  @pragma('vm:prefer-inline')
  int _handleMalformed(String v, int i, int offset, bool allow) {
    if (!allow) {
      throw FormatException('Invalid UTF-16: lone surrogate at index $i', v, i);
    }
    // Write UTF-8 encoding of U+FFFD replacement character (�)
    final list = _ws.list;
    list[offset] = 0xEF;
    list[offset + 1] = 0xBF;
    list[offset + 2] = 0xBD;
    return offset + 3;
  }

  @pragma('vm:prefer-inline')
  void _checkRange(int value, int min, int max, String typeName) {
    if (value < min || value > max) {
      throw RangeError.range(value, min, max, typeName);
    }
  }
}

/// Internal state holder for [BinaryWriter].
///
/// Manages the underlying buffer, capacity tracking, and expansion logic.
/// Separated from the extension type to allow efficient inline operations.
final class _WriterState {
  _WriterState(int initialBufferSize)
    : _size = initialBufferSize,
      capacity = initialBufferSize,
      offset = 0,
      list = Uint8List(initialBufferSize) {
    data = list.buffer.asByteData();
  }

  /// Current write position in the buffer.
  late int offset;

  /// Cached buffer capacity to avoid repeated length checks.
  late int capacity;

  /// Underlying byte buffer.
  late Uint8List list;

  /// ByteData view of the underlying buffer for efficient writes.
  late ByteData data;

  /// Initial buffer size.
  final int _size;

  @pragma('vm:prefer-inline')
  void _initializeBuffer() {
    list = Uint8List(_size);
    data = list.buffer.asByteData();
    capacity = _size;
    offset = 0;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void ensureSize(int size) {
    if (offset + size <= capacity) {
      return;
    }

    _expand(size);
  }

  @pragma('vm:prefer-inline')
  void ensureOneByte() {
    if (offset + 1 <= capacity) {
      return;
    }

    _expand(1);
  }

  @pragma('vm:prefer-inline')
  void ensureTwoBytes() {
    if (offset + 2 <= capacity) {
      return;
    }

    _expand(2);
  }

  @pragma('vm:prefer-inline')
  void ensureFourBytes() {
    if (offset + 4 <= capacity) {
      return;
    }

    _expand(4);
  }

  @pragma('vm:prefer-inline')
  void ensureEightBytes() {
    if (offset + 8 <= capacity) {
      return;
    }

    _expand(8);
  }

  /// Expands the buffer to accommodate additional data.
  ///
  /// Uses exponential growth (2x) for better amortized performance,
  /// but ensures the buffer is always large enough for the requested size.
  void _expand(int size) {
    final req = offset + size;
    // Double the capacity (exponential growth)
    var newCapacity = capacity * 2;
    // Ensure we meet the minimum requirement
    if (newCapacity < req) {
      newCapacity = req;
    }

    list = Uint8List(newCapacity)..setRange(0, offset, list);

    data = list.buffer.asByteData();
    capacity = newCapacity;
  }
}

/// Calculates the UTF-8 byte length of the given string without encoding it.
///
/// This function efficiently computes the number of bytes required to
/// encode the string in UTF-8, taking into account multi-byte characters
/// and surrogate pairs. It's optimized with an ASCII fast path that processes
/// up to 8 ASCII characters at once.
///
/// Useful for:
/// - Pre-allocating buffers of the correct size
/// - Calculating message sizes before serialization
/// - Validating string length constraints
///
/// Performance:
/// - ASCII strings: ~8 bytes per loop iteration
/// - Mixed content: Falls back to character-by-character analysis
///
/// Example:
/// ```dart
/// final text = 'Hello, 世界! 🌍';
/// final byteLength = getUtf8Length(text); // 20 bytes
/// // vs text.length would be 15 characters
/// ```
///
/// @param s The input string.
/// @return The number of bytes needed for UTF-8 encoding.
int getUtf8Length(String s) {
  if (s.isEmpty) {
    return 0;
  }

  final len = s.length;
  var bytes = 0;
  var i = 0;

  while (i < len) {
    final c = s.codeUnitAt(i);

    // ASCII fast path
    if (c < 0x80) {
      // Process 8 ASCII characters at a time
      final end = len - 8;
      while (i <= end) {
        final mask =
            s.codeUnitAt(i) |
            s.codeUnitAt(i + 1) |
            s.codeUnitAt(i + 2) |
            s.codeUnitAt(i + 3) |
            s.codeUnitAt(i + 4) |
            s.codeUnitAt(i + 5) |
            s.codeUnitAt(i + 6) |
            s.codeUnitAt(i + 7);

        if (mask >= 0x80) {
          break;
        }

        i += 8;
        bytes += 8;
      }

      // Handle remaining ASCII characters
      while (i < len && s.codeUnitAt(i) < 0x80) {
        i++;
        bytes++;
      }
      if (i >= len) {
        return bytes;
      }
      continue;
    }

    // 2-byte sequence
    if (c < 0x800) {
      bytes += 2;
      i++;
    }
    // 3-byte sequence
    else if (c >= 0xD800 && c <= 0xDBFF && i + 1 < len) {
      final next = s.codeUnitAt(i + 1);
      if (next >= 0xDC00 && next <= 0xDFFF) {
        bytes += 4;
        i += 2;
        continue;
      }
      // Malformed surrogate pair
      bytes += 3;
      i++;
    }
    // 3-byte sequence
    else {
      bytes += 3;
      i++;
    }
  }

  return bytes;
}
