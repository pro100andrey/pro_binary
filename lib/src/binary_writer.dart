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
/// writer.writeUint32(42);
/// writer.writeString('Hello');
/// final bytes = writer.takeBytes();
/// ```
extension type BinaryWriter._(_WriterState _ctx) {
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
  int get bytesWritten => _ctx.offset;

  /// Writes a variable-length integer using VarInt encoding.
  ///
  /// VarInt encoding uses the lower 7 bits of each byte for data and the
  /// highest bit as a continuation flag. This is more space-efficient for
  /// small numbers (1-5 bytes for typical 32-bit values).
  ///
  /// Only non-negative integers are supported. For signed integers, use
  /// [writeZigZag] instead.
  @pragma('vm:prefer-inline')
  void writeVarInt(int value) {
    // Fast path for single-byte VarInt
    if (value < 0x80 && value >= 0) {
      _ctx.ensureOneByte();
      _ctx.list[_ctx.offset++] = value;
      return;
    }

    _ctx.ensureSize(10);

    var v = value;
    final list = _ctx.list;
    var offset = _ctx.offset;

    while (v >= 0x80) {
      list[offset++] = (v & 0x7F) | 0x80;
      v >>>= 7;
    }

    list[offset++] = v & 0x7F;
    _ctx.offset = offset;
  }

  /// Writes a signed integer using ZigZag encoding followed by VarInt.
  ///
  /// ZigZag encoding maps signed integers to unsigned integers in a way that
  /// small absolute values (both positive and negative) use fewer bytes:
  /// - 0 => 0, -1 => 1, 1 => 2, -2 => 3, 2 => 4, etc.
  ///
  /// This is more efficient than VarInt for signed values that may be negative.
  void writeZigZag(int value) {
    // ZigZag: (n << 1) ^ (n >> 63)
    // Maps: 0=>0, -1=>1, 1=>2, -2=>3, 2=>4, -3=>5, 3=>6
    final encoded = (value << 1) ^ (value >> 63);
    writeVarInt(encoded);
  }

  /// Writes an 8-bit unsigned integer (0-255).
  ///
  /// Throws [RangeError] if [value] is outside the valid range.
  @pragma('vm:prefer-inline')
  void writeUint8(int value) {
    _checkRange(value, 0, 255, 'Uint8');
    _ctx.ensureOneByte();

    _ctx.list[_ctx.offset++] = value;
  }

  /// Writes an 8-bit signed integer (-128 to 127).
  ///
  /// Throws [RangeError] if [value] is outside the valid range.
  @pragma('vm:prefer-inline')
  void writeInt8(int value) {
    _checkRange(value, -128, 127, 'Int8');
    _ctx.ensureOneByte();

    _ctx.list[_ctx.offset++] = value & 0xFF;
  }

  /// Writes a 16-bit unsigned integer (0-65535).
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  /// Throws [RangeError] if [value] is outside the valid range.
  @pragma('vm:prefer-inline')
  void writeUint16(int value, [Endian endian = .big]) {
    _checkRange(value, 0, 65535, 'Uint16');
    _ctx.ensureTwoBytes();

    _ctx.data.setUint16(_ctx.offset, value, endian);
    _ctx.offset += 2;
  }

  /// Writes a 16-bit signed integer (-32768 to 32767).
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  /// Throws [RangeError] if [value] is outside the valid range.
  @pragma('vm:prefer-inline')
  void writeInt16(int value, [Endian endian = .big]) {
    _checkRange(value, -32768, 32767, 'Int16');
    _ctx.ensureTwoBytes();

    _ctx.data.setInt16(_ctx.offset, value, endian);
    _ctx.offset += 2;
  }

  /// Writes a 32-bit unsigned integer (0 to 4,294,967,295).
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  /// Throws [RangeError] if [value] is outside the valid range.
  @pragma('vm:prefer-inline')
  void writeUint32(int value, [Endian endian = .big]) {
    _checkRange(value, 0, 4294967295, 'Uint32');
    _ctx.ensureFourBytes();

    _ctx.data.setUint32(_ctx.offset, value, endian);
    _ctx.offset += 4;
  }

  /// Writes a 32-bit signed integer (-2,147,483,648 to 2,147,483,647).
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  /// Throws [RangeError] if [value] is outside the valid range.
  @pragma('vm:prefer-inline')
  void writeInt32(int value, [Endian endian = .big]) {
    _checkRange(value, -2147483648, 2147483647, 'Int32');
    _ctx.ensureFourBytes();

    _ctx.data.setInt32(_ctx.offset, value, endian);
    _ctx.offset += 4;
  }

  /// Writes a 64-bit unsigned integer (0 to 9,223,372,036,854,775,807).
  ///
  /// Note: Dart's integer precision is limited to 2^53 for web targets.
  /// [endian] specifies byte order (defaults to big-endian).
  /// Throws [RangeError] if [value] is outside the valid range.
  @pragma('vm:prefer-inline')
  void writeUint64(int value, [Endian endian = .big]) {
    _checkRange(value, 0, 9223372036854775807, 'Uint64');
    _ctx.ensureEightBytes();

    _ctx.data.setUint64(_ctx.offset, value, endian);
    _ctx.offset += 8;
  }

  /// Writes a 64-bit signed integer.
  ///
  /// Note: Dart's integer precision is limited to 2^53 for web targets.
  /// [endian] specifies byte order (defaults to big-endian).
  /// Throws [RangeError] if [value] is outside the valid range.
  @pragma('vm:prefer-inline')
  void writeInt64(int value, [Endian endian = .big]) {
    _checkRange(value, -9223372036854775808, 9223372036854775807, 'Int64');
    _ctx.ensureEightBytes();

    _ctx.data.setInt64(_ctx.offset, value, endian);
    _ctx.offset += 8;
  }

  /// Writes a 32-bit floating-point number (IEEE 754 single precision).
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  @pragma('vm:prefer-inline')
  void writeFloat32(double value, [Endian endian = .big]) {
    _ctx.ensureFourBytes();
    _ctx.data.setFloat32(_ctx.offset, value, endian);
    _ctx.offset += 4;
  }

  /// Writes a 64-bit floating-point number (IEEE 754 double precision).
  ///
  /// [endian] specifies byte order (defaults to big-endian).
  @pragma('vm:prefer-inline')
  void writeFloat64(double value, [Endian endian = .big]) {
    _ctx.ensureEightBytes();
    _ctx.data.setFloat64(_ctx.offset, value, endian);
    _ctx.offset += 8;
  }

  /// Writes a sequence of bytes from the given list.
  ///
  /// [offset] specifies the starting position in [bytes] (defaults to 0).
  /// [length] specifies how many bytes to write (defaults to remaining bytes).
  @pragma('vm:prefer-inline')
  void writeBytes(List<int> bytes, [int offset = 0, int? length]) {
    final len = length ?? (bytes.length - offset);
    _ctx.ensureSize(len);

    _ctx.list.setRange(_ctx.offset, _ctx.offset + len, bytes, offset);
    _ctx.offset += len;
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
  /// Note: This does NOT write the string length. For length-prefixed strings,
  /// call [writeVarInt] with the length before calling this method.
  @pragma('vm:prefer-inline')
  void writeString(String value, {bool allowMalformed = true}) {
    final len = value.length;
    if (len == 0) {
      return;
    }

    // Pre-allocate buffer: worst case is 3 bytes per UTF-16 code unit
    // Most common case: 1 byte/char (ASCII) or 2-3 bytes/char (non-ASCII)
    // Surrogate pairs: 2 units -> 4 bytes UTF-8 (2 bytes per unit average)
    _ctx.ensureSize(len * 3);

    final list = _ctx.list;
    var offset = _ctx.offset;
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

    _ctx.offset = offset;
  }

  /// Extracts all written bytes and resets the writer.
  ///
  /// After calling this method, the writer is reset and ready for reuse.
  /// This is more efficient than creating a new writer for each operation.
  ///
  /// Returns a view of the written bytes (no copying occurs).
  @pragma('vm:prefer-inline')
  Uint8List takeBytes() {
    final result = Uint8List.sublistView(_ctx.list, 0, _ctx.offset);
    _ctx._initializeBuffer();
    return result;
  }

  /// Returns a view of the written bytes without resetting the writer.
  ///
  /// Unlike [takeBytes], this does not reset the writer's state.
  /// Subsequent writes will continue appending to the buffer.
  @pragma('vm:prefer-inline')
  Uint8List toBytes() => Uint8List.sublistView(_ctx.list, 0, _ctx.offset);

  /// Resets the writer to its initial state, discarding all written data.
  @pragma('vm:prefer-inline')
  void reset() => _ctx._initializeBuffer();

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
    final list = _ctx.list;
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
