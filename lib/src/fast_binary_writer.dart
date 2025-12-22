import 'dart:typed_data';

extension type FastBinaryWriter._(_Writer _ctx) {
  FastBinaryWriter({int initialBufferSize = 128})
    : this._(_Writer(initialBufferSize));

  int get bytesWritten => _ctx.offset;

  @pragma('vm:prefer-inline')
  void _checkRange(int value, int min, int max, String typeName) {
    if (value < min || value > max) {
      throw RangeError.range(value, min, max, typeName);
    }
  }

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

  void writeZigZag(int value) {
    // Encode zig-zag encoding
    final encoded = (value << 1) ^ (value >> 63);
    writeVarInt(encoded);
  }

  @pragma('vm:prefer-inline')
  void writeUint8(int value) {
    _checkRange(value, 0, 255, 'Uint8');
    _ctx.ensureOneByte();

    _ctx.list[_ctx.offset++] = value;
  }

  @pragma('vm:prefer-inline')
  void writeInt8(int value) {
    _checkRange(value, -128, 127, 'Int8');
    _ctx.ensureOneByte();

    _ctx.list[_ctx.offset++] = value & 0xFF;
  }

  @pragma('vm:prefer-inline')
  void writeUint16(int value, [Endian endian = .big]) {
    _checkRange(value, 0, 65535, 'Uint16');
    _ctx.ensureTwoBytes();

    _ctx.data.setUint16(_ctx.offset, value, endian);
    _ctx.offset += 2;
  }

  @pragma('vm:prefer-inline')
  void writeInt16(int value, [Endian endian = .big]) {
    _checkRange(value, -32768, 32767, 'Int16');
    _ctx.ensureTwoBytes();

    _ctx.data.setInt16(_ctx.offset, value, endian);
    _ctx.offset += 2;
  }

  @pragma('vm:prefer-inline')
  void writeUint32(int value, [Endian endian = .big]) {
    _checkRange(value, 0, 4294967295, 'Uint32');
    _ctx.ensureFourBytes();

    _ctx.data.setUint32(_ctx.offset, value, endian);
    _ctx.offset += 4;
  }

  @pragma('vm:prefer-inline')
  void writeInt32(int value, [Endian endian = .big]) {
    _checkRange(value, -2147483648, 2147483647, 'Int32');
    _ctx.ensureFourBytes();

    _ctx.data.setInt32(_ctx.offset, value, endian);
    _ctx.offset += 4;
  }

  @pragma('vm:prefer-inline')
  void writeUint64(int value, [Endian endian = .big]) {
    _checkRange(value, 0, 9223372036854775807, 'Uint64');
    _ctx.ensureEightBytes();

    _ctx.data.setUint64(_ctx.offset, value, endian);
    _ctx.offset += 8;
  }

  @pragma('vm:prefer-inline')
  void writeInt64(int value, [Endian endian = .big]) {
    _checkRange(value, -9223372036854775808, 9223372036854775807, 'Int64');
    _ctx.ensureEightBytes();

    _ctx.data.setInt64(_ctx.offset, value, endian);
    _ctx.offset += 8;
  }

  @pragma('vm:prefer-inline')
  void writeFloat32(double value, [Endian endian = .big]) {
    _ctx.ensureFourBytes();
    _ctx.data.setFloat32(_ctx.offset, value, endian);
    _ctx.offset += 4;
  }

  @pragma('vm:prefer-inline')
  void writeFloat64(double value, [Endian endian = .big]) {
    _ctx.ensureEightBytes();
    _ctx.data.setFloat64(_ctx.offset, value, endian);
    _ctx.offset += 8;
  }

  @pragma('vm:prefer-inline')
  void writeBytes(List<int> bytes, [int offset = 0, int? length]) {
    final len = length ?? (bytes.length - offset);
    _ctx.ensureSize(len);

    _ctx.list.setRange(_ctx.offset, _ctx.offset + len, bytes, offset);
    _ctx.offset += len;
  }

  @pragma('vm:prefer-inline')
  void writeString(String value, {bool allowMalformed = true}) {
    final len = value.length;
    if (len == 0) {
      return;
    }

    // Pre-allocate: worst case for UTF-16 to UTF-8 is 3 bytes per code unit.
    // (Surrogate pairs are 2 units -> 4 bytes, which is 2 bytes/unit).
    _ctx.ensureSize(len * 3);

    final list = _ctx.list;
    var offset = _ctx.offset;
    var i = 0;

    while (i < len) {
      var c = value.codeUnitAt(i);

      if (c < 0x80) {
        // -------------------------------------------------------
        // ASCII Fast Path
        // -------------------------------------------------------
        list[offset++] = c;
        i++;

        // Unrolled loop for blocks of 4 ASCII characters
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
      // Multi-byte handling
      // -------------------------------------------------------
      if (c < 0x800) {
        // 2 bytes: Cyrillic, Greek, Arabic, etc.
        list[offset++] = 0xC0 | (c >> 6);
        list[offset++] = 0x80 | (c & 0x3F);
        i++;
      } else if (c < 0xD800 || c > 0xDFFF) {
        // 3 bytes: Basic Multilingual Plane
        list[offset++] = 0xE0 | (c >> 12);
        list[offset++] = 0x80 | ((c >> 6) & 0x3F);
        list[offset++] = 0x80 | (c & 0x3F);
        i++;
      } else if (c <= 0xDBFF && i + 1 < len) {
        // 4 bytes: Valid Surrogate Pair
        final next = value.codeUnitAt(i + 1);
        if (next >= 0xDC00 && next <= 0xDFFF) {
          final codePoint = 0x10000 + ((c & 0x3FF) << 10) + (next & 0x3FF);
          list[offset++] = 0xF0 | (codePoint >> 18);
          list[offset++] = 0x80 | ((codePoint >> 12) & 0x3F);
          list[offset++] = 0x80 | ((codePoint >> 6) & 0x3F);
          list[offset++] = 0x80 | (codePoint & 0x3F);
          i += 2;
        } else {
          offset = _handleMalformed(value, i, offset, allowMalformed);
          i++;
        }
      } else {
        // Malformed: Lone surrogate or end of string
        offset = _handleMalformed(value, i, offset, allowMalformed);
        i++;
      }
    }

    _ctx.offset = offset;
  }

  @pragma('vm:prefer-inline')
  int _handleMalformed(String v, int i, int offset, bool allow) {
    if (!allow) {
      throw FormatException('Invalid UTF-16: lone surrogate at index $i', v, i);
    }
    final list = _ctx.list;
    list[offset] = 0xEF;
    list[offset + 1] = 0xBF;
    list[offset + 2] = 0xBD;
    return offset + 3;
  }

  @pragma('vm:prefer-inline')
  Uint8List takeBytes() {
    final result = Uint8List.sublistView(_ctx.list, 0, _ctx.offset);
    _ctx._initializeBuffer();
    return result;
  }

  @pragma('vm:prefer-inline')
  Uint8List toBytes() => Uint8List.sublistView(_ctx.list, 0, _ctx.offset);

  @pragma('vm:prefer-inline')
  void reset() => _ctx._initializeBuffer();
}

final class _Writer {
  _Writer(int initialBufferSize)
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

  void _expand(int size) {
    final req = offset + size;
    var newCapacity = capacity * 2;
    if (newCapacity < req) {
      newCapacity = req;
    }

    list = Uint8List(newCapacity)..setRange(0, offset, list);

    data = list.buffer.asByteData();
    capacity = newCapacity;
  }
}
