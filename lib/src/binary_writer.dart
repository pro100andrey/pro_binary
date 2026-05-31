import 'dart:typed_data';

import 'constants.dart';

part 'binary_writer_pool.dart';
part 'string_utils.dart';

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
/// // Write various data types
/// writer.writeUint32(42);
/// writer.writeFloat64(3.14);
/// // Write length-prefixed string
/// final text = 'Hello, World!';
/// writer.writeVarString(text);
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
}

/// Core properties and operators for [BinaryWriter].
extension BinaryWriterCore on BinaryWriter {
  /// Returns the total number of bytes written to the buffer.
  int get bytesWritten => _ws.offset;

  /// Returns the current capacity of the internal buffer.
  int get capacity => _ws.capacity;

  /// Returns the byte at the specified [index] without changing the current
  /// write position.
  ///
  /// Throws [RangeError] if [index] is negative or greater than or equal to
  /// [bytesWritten].
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int operator [](int index) {
    if (index < 0 || index >= _ws.offset) {
      throw RangeError.range(index, 0, _ws.offset - 1, 'index');
    }
    return _ws.list[index];
  }

  /// Writes a byte at the specified [index] without changing the current
  /// write position.
  ///
  /// This operator is used to overwrite already written bytes. To append data,
  /// use the standard `write*` methods.
  ///
  /// Throws [RangeError] if [index] is negative or greater than or equal to
  /// [bytesWritten].
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void operator []=(int index, int value) {
    if (index < 0 || index >= _ws.offset) {
      throw RangeError.range(index, 0, _ws.offset - 1, 'index');
    }

    _checkRange(value, 0, 255, 'Uint8');
    _ws.list[index] = value;
  }

  /// Writes a sequence of bytes.
  ///
  /// This is a concise alias for [writeBytes].
  ///
  /// Example:
  /// ```dart
  /// writer([1, 2, 3]); // Same as writer.writeBytes([1, 2, 3])
  /// ```
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void call(List<int> bytes) => writeBytes(bytes);

  /// Extracts all written bytes and resets the writer.
  ///
  /// [copy] determines how the bytes are extracted:
  /// - If `true`: The written bytes are copied into a new [Uint8List]. The
  ///   internal buffer is retained and its offset is reset to 0. This is
  ///   highly efficient for pooling (e.g., [BinaryWriterPool]) as the same
  ///   large buffer is reused for subsequent operations without re-allocation.
  /// - If `false` (default): A view of the internal buffer is returned, and
  ///   the writer detaches from it by allocating a fresh initial-sized buffer.
  ///   While the returned bytes are "zero-copy" relative to the old buffer,
  ///   this forces the writer to re-allocate memory, which is less efficient
  ///   for pooling long-term.
  ///
  /// After calling this method, the writer is reset and ready for reuse.
  ///
  /// Example:
  /// ```dart
  /// final writer = BinaryWriter();
  /// writer.writeUint32(42);
  /// // For best pooling performance (retains internal buffer):
  /// final packet = writer.takeBytes(copy: true);
  /// ```
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  Uint8List takeBytes({bool copy = false}) {
    if (copy) {
      final result = _ws.list.sublist(0, _ws.offset);
      _ws.offset = 0;

      return result;
    }

    final result = Uint8List.sublistView(_ws.list, 0, _ws.offset);
    _ws._initializeBuffer();

    return result;
  }

  /// Returns a view of the written bytes (from index 0 up to the current
  /// [bytesWritten]) without resetting the writer.
  ///
  /// Unlike [takeBytes], this does not reset the writer's state.
  /// Subsequent writes will continue appending to the buffer.
  ///
  /// **Note:** Since this returns a view, the content of the returned list
  /// will change if you continue writing to this writer.
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
  @pragma('dart2js:tryInline')
  Uint8List toBytes() => Uint8List.sublistView(_ws.list, 0, _ws.offset);

  /// Resets the writer to its initial state, discarding all written data.
  @pragma('vm:prefer-inline')
  void reset() => _ws._initializeBuffer();
}

/// Variable-length integer writing methods for [BinaryWriter].
extension BinaryWriterVarInt on BinaryWriter {
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
  @pragma('dart2js:tryInline')
  void writeVarUint(int value) {
    // Fast path: single-byte (0-127)
    var offset = _ws.offset;
    if (value < 0x80 && value >= 0) {
      _ws.ensureOneByte();
      _ws.list[offset++] = value;
      _ws.offset = offset;

      return;
    }

    _ws.ensureSize(10);
    // Slow path: multi-byte VarInt
    final list = _ws.list;

    // First byte (always has continuation bit)
    list[offset++] = (value & 0x7F) | 0x80;
    var v = value >>> 7;

    // Unrolled 2-byte case (covers 0-16383, ~90% of real-world values)
    if (v < 0x80) {
      list[offset++] = v;
      _ws.offset = offset;

      return;
    }

    // Second byte
    list[offset++] = (v & 0x7F) | 0x80;
    v >>>= 7;

    // Unrolled 3-byte case (covers 0-2097151)
    if (v < 0x80) {
      list[offset++] = v;
      _ws.offset = offset;

      return;
    }

    // Third byte
    list[offset++] = (v & 0x7F) | 0x80;
    v >>>= 7;

    // Unrolled 4-byte case (covers 0-268435455, ~99.9% of 32-bit values)
    if (v < 0x80) {
      list[offset++] = v;
      _ws.offset = offset;

      return;
    }

    // Generic loop for remaining bytes (rare large 64-bit numbers)
    while (v >= 0x80) {
      list[offset++] = (v & 0x7F) | 0x80;
      v >>>= 7;
    }

    list[offset++] = v; // Last byte without continuation bit
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
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeVarInt(int value) {
    // ZigZag: (n << 1) ^ (n >> 63)
    // Maps: 0=>0, -1=>1, 1=>2, -2=>3, 2=>4, -3=>5, 3=>6
    final encoded = (value << 1) ^ (value >> 63);
    writeVarUint(encoded);
  }
}

/// Fixed-width numeric writing methods for [BinaryWriter].
extension BinaryWriterNumeric on BinaryWriter {
  /// Writes a boolean value as a single byte.
  ///
  /// `true` is written as `1` and `false` as `0`.
  ///
  /// Example:
  /// ```dart
  /// writer.writeBool(true);   // Writes byte 0x01
  /// writer.writeBool(false);  // Writes byte 0x00
  /// ```
  ///
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  // Disable lint to allow positional boolean parameter for simplicity
  void writeBool(bool value) {
    writeUint8(value ? 1 : 0);
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
  @pragma('dart2js:tryInline')
  void writeUint8(int value) {
    _checkRange(value, 0, 255, 'Uint8');

    _ws.ensureOneByte();
    _ws.data.setUint8(_ws.offset++, value);
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
  @pragma('dart2js:tryInline')
  void writeInt8(int value) {
    _checkRange(value, -128, 127, 'Int8');

    _ws.ensureOneByte();
    _ws.data.setInt8(_ws.offset++, value);
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
  @pragma('dart2js:tryInline')
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
  @pragma('dart2js:tryInline')
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
  @pragma('dart2js:tryInline')
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
  @pragma('dart2js:tryInline')
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
  @pragma('dart2js:tryInline')
  void writeUint64(int value, [Endian endian = .big]) {
    _checkRange(value, 0, kMaxInt64, 'Uint64');

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
  @pragma('dart2js:tryInline')
  void writeInt64(int value, [Endian endian = .big]) {
    _checkRange(value, kMinInt64, kMaxInt64, 'Int64');

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
  @pragma('dart2js:tryInline')
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
  @pragma('dart2js:tryInline')
  void writeFloat64(double value, [Endian endian = .big]) {
    _ws.ensureEightBytes();
    _ws.data.setFloat64(_ws.offset, value, endian);
    _ws.offset += 8;
  }
}

/// Byte array and string writing methods for [BinaryWriter].
extension BinaryWriterBytesString on BinaryWriter {
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
  @pragma('dart2js:tryInline')
  void writeBytes(List<int> bytes, [int offset = 0, int? length]) {
    if (offset < 0) {
      throw RangeError.value(offset, 'offset', 'Offset must be non-negative');
    }

    if (offset > bytes.length) {
      throw RangeError.range(offset, 0, bytes.length, 'offset');
    }

    final len = length ?? (bytes.length - offset);

    if (len < 0) {
      throw RangeError.value(len, 'length', 'Length must be non-negative');
    }

    if (offset + len > bytes.length) {
      throw RangeError(
        'Offset + length exceeds list length: '
        'offset=$offset length=$len '
        'listLength=${bytes.length}',
      );
    }

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
  @pragma('dart2js:tryInline')
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
  /// // 1. Easy way (highly optimized)
  /// writer.writeVarString('Hello, 世界! 🌍');
  ///
  /// // 2. Manual length-prefixed string (if data is already encoded)
  /// final text = 'Hello, 世界! 🌍';
  /// final utf8Bytes = utf8.encode(text);
  /// writer.writeVarUint(utf8Bytes.length);  // Write byte length
  /// writer.writeBytes(utf8Bytes);            // Write pre-encoded string data
  ///
  /// // 3. Fixed-length strings (no prefix)
  /// writer.writeString('MAGIC');
  /// ```
  ///
  /// **Performance:** Highly optimized for ASCII-heavy strings.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
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
  /// final byteLength = getUtf8Length(text);
  /// writer.writeVarUint(byteLength);
  /// writer.writeString(text);
  /// ```
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeVarString(String value, {bool allowMalformed = true}) {
    final len = value.length;
    if (len == 0) {
      writeVarUint(0);
      return;
    }

    // 1. Optimistically estimate the VarInt size based on string character
    // length. For pure ASCII strings, byte length matches character length
    // exactly.
    final estimatedSize = _varIntSize(len);

    // Cache the initial offset locally to avoid redundant heap lookups.
    final startOffset = _ws.offset;

    // Ensure enough space for the prefix and the worst-case UTF-8 scenario
    // (3 bytes per unit).
    _ws
      ..ensureSize(estimatedSize + len * 3)
      // 2. Reserve space for the estimated length prefix using a fast direct
      // assignment.
      ..offset = startOffset + estimatedSize;

    // 3. Write the actual string data directly into the buffer.
    writeString(value, allowMalformed: allowMalformed);

    // Cache the offset immediately after writing to determine the exact byte
    // length.
    var currentOffset = _ws.offset;
    final byteLength = currentOffset - (startOffset + estimatedSize);

    // 4. Determine the actual VarInt size required for the encoded byte length.
    final actualSize = _varIntSize(byteLength);

    // 5. If the optimistic estimate was wrong (e.g., due to multi-byte UTF-8
    // characters), shift the written string data to accommodate the actual
    //VarInt size.
    if (actualSize != estimatedSize) {
      final shift = actualSize - estimatedSize;
      if (shift > 0) {
        _ws.ensureSize(shift);
      }

      // Perform a fast native memory shift (memmove) using setRange.
      _ws.list.setRange(
        startOffset + actualSize,
        currentOffset + shift,
        _ws.list,
        startOffset + estimatedSize,
      );

      // Adjust the local tracker instead of modifying the heap property
      // repeatedly.
      currentOffset += shift;
    }

    // 6. Backtrack to the start offset and write the authentic VarInt length
    // prefix.
    _ws.offset = startOffset;
    writeVarUint(byteLength);

    // 7. Advance the buffer's final offset to the absolute end of the payload.
    _ws.offset = currentOffset;
  }

  /// Writes a UTF-8 encoded string prefixed with a fixed-width length.
  ///
  /// The length prefix size is determined by [lengthEncoding].
  ///
  /// [value] is the string to write.
  /// [lengthEncoding] specifies the size of the length prefix (defaults to
  /// [LengthEncoding.u8]).
  /// [allowMalformed] if true, malformed UTF-8 sequences will be replaced
  /// with U+FFFD.
  ///
  /// This is useful when you want to avoid VarInt encoding for lengths or
  /// when the format requires a specific fixed-width length prefix.
  ///
  /// Example:
  /// ```dart
  /// writer.writeStringFixed('Hello', lengthEncoding: LengthEncoding.u16);
  /// ```
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void writeStringFixed(
    String value, {
    LengthEncoding lengthEncoding = .u8,
    bool allowMalformed = true,
  }) {
    final len = value.length;
    if (len == 0) {
      _writeLength(0, lengthEncoding);
      return;
    }

    final sizeInBytes = lengthEncoding.sizeInBytes;
    _ws.ensureSize(sizeInBytes + len * 3);

    final startOffset = _ws.offset;

    _ws.offset = startOffset + sizeInBytes;

    writeString(value, allowMalformed: allowMalformed);

    final finalOffset = _ws.offset;
    final byteLength = finalOffset - (startOffset + sizeInBytes);

    _ws.offset = startOffset;
    _writeLength(byteLength, lengthEncoding);
    _ws.offset = finalOffset;
  }
}

/// Random access read/write methods for [BinaryWriter].
extension BinaryWriterRandomAccess on BinaryWriter {
  /// Reads a 8-bit unsigned at the specified [position] without changing the
  /// current write position.
  ///
  /// Throws [RangeError] if [position] is negative or greater than or equal to
  /// [bytesWritten].
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int getUint8(int position) => _ws.data.getUint8(position);

  /// Reads a 8-bit signed integer at the specified [position] without changing
  /// the current write position.
  ///
  /// Throws [RangeError] if [position] is negative or greater than or equal to
  /// [bytesWritten].
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int getInt8(int position) => _ws.data.getInt8(position);

  /// Reads a 16-bit unsigned integer at the specified [position] without
  /// changing the current write position.
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  ///
  /// Throws [RangeError] if [position] is negative or beyond
  ///  `bytesWritten - 1`.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int getUint16(int position, [Endian endian = Endian.big]) =>
      _ws.data.getUint16(position, endian);

  /// Reads a 16-bit signed integer at the specified [position] without changing
  /// the current write position.
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  ///
  /// Throws [RangeError] if [position] is negative or beyond
  /// `bytesWritten - 1`.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int getInt16(int position, [Endian endian = Endian.big]) =>
      _ws.data.getInt16(position, endian);

  /// Reads a 32-bit unsigned integer at the specified [position] without
  /// changing the current write position.
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  ///
  /// Throws [RangeError] if [position] is negative or beyond
  /// `bytesWritten - 3`.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int getUint32(int position, [Endian endian = Endian.big]) =>
      _ws.data.getUint32(position, endian);

  /// Reads a 32-bit signed integer at the specified [position] without changing
  /// the current write position.
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  ///
  /// Throws [RangeError] if [position] is negative or beyond
  /// `bytesWritten - 3`.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int getInt32(int position, [Endian endian = Endian.big]) =>
      _ws.data.getInt32(position, endian);

  /// Reads a 64-bit unsigned integer at the specified [position] without
  /// changing the current write position.
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  ///
  /// Throws [RangeError] if [position] is negative or beyond
  /// `bytesWritten - 7`.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int getUint64(int position, [Endian endian = Endian.big]) =>
      _ws.data.getUint64(position, endian);

  /// Reads a 64-bit signed integer at the specified [position] without changing
  /// the current write position.
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  ///
  /// Throws [RangeError] if [position] is negative or beyond
  /// `bytesWritten - 7`.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int getInt64(int position, [Endian endian = Endian.big]) =>
      _ws.data.getInt64(position, endian);

  /// Reads a 32-bit floating-point number at the specified [position] without
  /// changing the current write position.
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  ///
  /// Throws [RangeError] if [position] is negative or beyond
  /// `bytesWritten - 3`.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  double getFloat32(int position, [Endian endian = Endian.big]) =>
      _ws.data.getFloat32(position, endian);

  /// Reads a 64-bit floating-point number at the specified [position] without
  /// changing the current write position.
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  ///
  /// Throws [RangeError] if [position] is negative or beyond
  /// `bytesWritten - 7`.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  double getFloat64(int position, [Endian endian = Endian.big]) =>
      _ws.data.getFloat64(position, endian);

  /// Writes a 8-bit unsigned signed at the specified [position] without
  /// changing the current write position.
  ///
  /// Throws [RangeError] if [position] is negative or greater than or equal to
  /// [bytesWritten].
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void setUint8(int position, int value) {
    _checkRange(value, 0, 255, 'Uint8');
    _ws.data.setUint8(position, value);
  }

  /// Writes a 8-bit signed at the specified [position] without changing the
  /// current write position.
  ///
  /// Throws [RangeError] if [position] is negative or greater than or equal to
  /// [bytesWritten].
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void setInt8(int position, int value) {
    _checkRange(value, -128, 127, 'Int8');
    _ws.data.setUint8(position, value);
  }

  /// Writes a 16-bit unsigned integer at the specified [position] without
  /// changing the current write position.
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  ///
  /// Throws [RangeError] if [position] is negative or beyond
  /// `bytesWritten - 1`.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void setUint16(int position, int value, [Endian endian = Endian.big]) {
    _checkRange(value, 0, 65535, 'Uint16');
    _ws.data.setUint16(position, value, endian);
  }

  /// Writes a 16-bit signed integer at the specified [position] without
  /// changing the current write position.
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  ///
  /// Throws [RangeError] if [position] is negative or beyond
  /// `bytesWritten - 1`.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void setInt16(int position, int value, [Endian endian = Endian.big]) {
    _checkRange(value, -32768, 32767, 'Int16');
    _ws.data.setInt16(position, value, endian);
  }

  /// Writes a 32-bit unsigned integer at the specified [position] without
  /// changing the current write position.
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  ///
  /// Throws [RangeError] if [position] is negative or beyond
  /// `bytesWritten - 3`.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void setUint32(int position, int value, [Endian endian = Endian.big]) {
    _checkRange(value, 0, 4294967295, 'Uint32');
    _ws.data.setUint32(position, value, endian);
  }

  /// Writes a 32-bit signed integer at the specified [position] without
  /// changing the current write position.
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  ///
  /// Throws [RangeError] if [position] is negative or beyond
  /// `bytesWritten - 3`.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void setInt32(int position, int value, [Endian endian = Endian.big]) {
    _checkRange(value, -2147483648, 2147483647, 'Int32');
    _ws.data.setInt32(position, value, endian);
  }

  /// Writes a 64-bit unsigned integer at the specified [position] without
  /// changing the current write position.
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  ///
  /// Throws [RangeError] if [position] is negative or beyond
  /// `bytesWritten - 7`.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void setUint64(int position, int value, [Endian endian = Endian.big]) {
    _checkRange(value, 0, kMaxInt64, 'Uint64');
    _ws.data.setUint64(position, value, endian);
  }

  /// Writes a 64-bit signed integer at the specified [position] without
  /// changing the current write position.
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  ///
  /// Throws [RangeError] if [position] is negative or beyond
  /// `bytesWritten - 7`.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void setInt64(int position, int value, [Endian endian = Endian.big]) {
    _checkRange(value, kMinInt64, kMaxInt64, 'Int64');
    _ws.data.setInt64(position, value, endian);
  }

  /// Writes a 32-bit floating-point number at the specified [position] without
  /// changing the current write position.
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  ///
  /// Throws [RangeError] if [position] is negative or beyond
  /// `bytesWritten - 3`.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void setFloat32(int position, double value, [Endian endian = Endian.big]) {
    _ws.data.setFloat32(position, value, endian);
  }

  /// Writes a 64-bit floating-point number at the specified [position] without
  /// changing the current write position.
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  ///
  /// Throws [RangeError] if [position] is negative or beyond
  /// `bytesWritten - 7`.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void setFloat64(int position, double value, [Endian endian = Endian.big]) {
    _ws.data.setFloat64(position, value, endian);
  }
}

/// Position management methods for [BinaryWriter].
extension BinaryWriterPosition on BinaryWriter {
  /// Sets the write position to the specified byte offset.
  ///
  /// Subsequent writes will start from this new position.
  /// Use to go back and overwrite data, or to skip ahead.
  ///
  /// Throws [RangeError] if [position] is negative or exceeds [bytesWritten].
  ///
  /// Example:
  /// ```dart
  /// writer.writeUint32(42);
  /// writer.writeUint32(100);
  /// writer.seek(0);  // Go back to the beginning
  /// writer.writeUint32(99);  // Overwrite 42 with 99
  /// ```
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void seek(int position) {
    if (position < 0 || position > _ws.offset) {
      throw RangeError.range(position, 0, _ws.offset, 'position');
    }

    _ws.offset = position;
  }

  /// Advances the write position by [count] bytes without writing data.
  ///
  /// The skipped bytes may contain garbage. This is primarily used to reserve
  /// space for a header that will be written later
  /// (Reserve & Backpatch pattern).
  ///
  /// Throws [RangeError] if [count] is negative.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void skip(int count) {
    if (count < 0) {
      throw RangeError.value(count, 'count', 'must be non-negative');
    }

    if (count == 0) {
      return;
    }

    _ws
      ..ensureSize(count)
      ..offset += count;
  }

  /// Reserves [count] bytes for later backpatching and returns the starting
  /// offset of the reserved block.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int reserve(int count) {
    final currentOffset = _ws.offset;
    skip(count);

    return currentOffset;
  }

  /// Shifts a block of written bytes within the buffer.
  ///
  /// Used for the "Reserve & Backpatch" pattern when the reserved header space
  /// was larger than actually needed. This allows shifting the payload left to
  /// overwrite the unused reserved space, avoiding a new array allocation.
  ///
  /// [start] - The starting index of the block to shift.
  /// [end] - The ending index (exclusive) of the block to shift.
  /// [target] - The index where the block should be moved to
  ///   (must be <= start).
  ///
  /// Throws [RangeError] if parameters define an invalid range or would cause
  /// data corruption.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void shiftBytes(int start, int end, int target) {
    assert(start >= 0, 'start must be non-negative');
    assert(end >= start, 'end must be >= start');
    assert(end <= _ws.offset, 'end exceeds current bytesWritten');
    assert(target >= 0, 'target must be non-negative');
    assert(target <= start, 'target must be <= start (can only shift left)');

    final length = end - start;
    if (length == 0) {
      return;
    }

    _ws.list.setRange(target, target + length, _ws.list, start);

    if (end == _ws.offset) {
      _ws.offset = target + length;
    }
  }
}

/// Internal methods for [BinaryWriter].
extension _BinaryWriterInternal on BinaryWriter {
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  int _varIntSize(int value) => switch (value) {
    < 0x80 => 1,
    < 0x4000 => 2,
    < 0x200000 => 3,
    < 0x10000000 => 4,
    _ => 5,
  };

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void _writeLength(int length, LengthEncoding encoding) {
    switch (encoding) {
      case .u8:
        writeUint8(length);
      case .u16:
        writeUint16(length);
      case .u32:
        writeUint32(length);
      case .u64:
        writeUint64(length);
    }
  }

  /// Handles malformed UTF-16 sequences (lone surrogates).
  ///
  /// If [allow] is false, throws [FormatException].
  /// Otherwise, writes the Unicode replacement character U+FFFD (�)
  /// encoded as UTF-8: 0xEF 0xBF 0xBD
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
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
    : this._fromSize(_validateInitialBufferSize(initialBufferSize));

  _WriterState._fromSize(int size)
    : _size = size,
      _isInPool = false,
      capacity = (size + 63) & ~63,
      offset = 0,
      list = Uint8List((size + 63) & ~63) {
    data = list.buffer.asByteData();
  }

  static int _validateInitialBufferSize(int value) {
    if (value <= 0) {
      throw RangeError.value(
        value,
        'initialBufferSize',
        'Initial buffer size must be positive',
      );
    }
    return value;
  }

  /// Current write position in the buffer.
  int offset;

  /// Cached buffer capacity to avoid repeated length checks.
  int capacity;

  /// Underlying byte buffer.
  Uint8List list;

  /// ByteData view of the underlying buffer for efficient writes.
  late ByteData data;

  /// Initial buffer size.
  final int _size;

  /// Whether this writer is currently in the pool (not available for direct
  /// use).
  bool _isInPool;

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void _initializeBuffer() {
    final alignedSize = (_size + 63) & ~63;
    list = Uint8List(alignedSize);
    data = list.buffer.asByteData();
    capacity = alignedSize;
    offset = 0;
    _isInPool = false;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void ensureSize(int size) {
    assert(!_isInPool, 'Cannot ensure size on a pooled writer');

    if (offset + size > capacity) {
      _expand(size);
    }
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void ensureOneByte() {
    assert(!_isInPool, 'Cannot ensure size on a pooled writer');

    if (offset + 1 > capacity) {
      _expand(1);
    }
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void ensureTwoBytes() {
    assert(!_isInPool, 'Cannot ensure size on a pooled writer');

    if (offset + 2 > capacity) {
      _expand(2);
    }
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void ensureFourBytes() {
    assert(!_isInPool, 'Cannot ensure size on a pooled writer');

    if (offset + 4 > capacity) {
      _expand(4);
    }
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void ensureEightBytes() {
    assert(!_isInPool, 'Cannot ensure size on a pooled writer');

    if (offset + 8 > capacity) {
      _expand(8);
    }
  }

  /// Expands the buffer to accommodate additional data.
  ///
  /// Uses exponential growth (1.5x) for better memory efficiency,
  /// but ensures the buffer is always large enough for the requested size.
  @pragma('vm:never-inline')
  void _expand(int size) {
    final req = offset + size;
    // Grow by 1.5x (exponential growth with better memory efficiency)
    var newCapacity = capacity + (capacity >> 1);

    // Ensure we meet the minimum requirement
    if (newCapacity < req) {
      newCapacity = req;
    }
    // Align to 64-byte boundary
    newCapacity = (newCapacity + 63) & ~63;

    list = Uint8List(newCapacity)..setRange(0, offset, list);

    data = list.buffer.asByteData();
    capacity = newCapacity;
  }
}
