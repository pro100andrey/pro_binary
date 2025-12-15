import 'dart:typed_data';

extension type const FastBinaryWriter._(_Buffer _ctx) {
  FastBinaryWriter({int initialBufferSize = 128})
    : this._(_Buffer(initialBufferSize));

  int get bytesWritten => _ctx._offset;

  void _checkRange(int value, int min, int max, String typeName) {
    if (value < min || value > max) {
      throw RangeError.range(value, min, max, typeName);
    }
  }

  void writeUint8(int value) {
    _checkRange(value, 0, 255, 'Uint8');
    _ctx._ensureSize(1);
    _ctx._data.setUint8(_ctx._offset, value);
    _ctx._offset += 1;
  }

  void writeInt8(int value) {
    _checkRange(value, -128, 127, 'Int8');
    _ctx._ensureSize(1);
    _ctx._data.setInt8(_ctx._offset, value);
    _ctx._offset += 1;
  }

  void writeUint16(int value, [Endian endian = Endian.big]) {
    _checkRange(value, 0, 65535, 'Uint16');
    _ctx._ensureSize(2);
    _ctx._data.setUint16(_ctx._offset, value, endian);
    _ctx._offset += 2;
  }

  void writeInt16(int value, [Endian endian = Endian.big]) {
    _checkRange(value, -32768, 32767, 'Int16');
    _ctx._ensureSize(2);
    _ctx._data.setInt16(_ctx._offset, value, endian);
    _ctx._offset += 2;
  }

  void writeUint32(int value, [Endian endian = Endian.big]) {
    _checkRange(value, 0, 4294967295, 'Uint32');
    _ctx._ensureSize(4);
    _ctx._data.setUint32(_ctx._offset, value, endian);
    _ctx._offset += 4;
  }

  void writeInt32(int value, [Endian endian = Endian.big]) {
    _checkRange(value, -2147483648, 2147483647, 'Int32');
    _ctx._ensureSize(4);
    _ctx._data.setInt32(_ctx._offset, value, endian);
    _ctx._offset += 4;
  }

  void writeUint64(int value, [Endian endian = Endian.big]) {
    _checkRange(value, 0, 9223372036854775807, 'Uint64');
    _ctx._ensureSize(8);
    _ctx._data.setUint64(_ctx._offset, value, endian);
    _ctx._offset += 8;
  }

  void writeInt64(int value, [Endian endian = Endian.big]) {
    _checkRange(value, -9223372036854775808, 9223372036854775807, 'Int64');
    _ctx._ensureSize(8);
    _ctx._data.setInt64(_ctx._offset, value, endian);
    _ctx._offset += 8;
  }

  void writeFloat32(double value, [Endian endian = Endian.big]) {
    _ctx._ensureSize(4);
    _ctx._data.setFloat32(_ctx._offset, value, endian);
    _ctx._offset += 4;
  }

  void writeFloat64(double value, [Endian endian = Endian.big]) {
    _ctx._ensureSize(8);
    _ctx._data.setFloat64(_ctx._offset, value, endian);
    _ctx._offset += 8;
  }

  void writeBytes(Iterable<int> bytes) {
    // Early return for empty byte lists
    if (bytes.isEmpty) {
      return;
    }

    final length = bytes.length;
    _ctx._ensureSize(length);

    final offset = _ctx._offset;
    _ctx._list.setRange(offset, offset + length, bytes);
    _ctx._offset = offset + length;
  }

  void writeString(String value, {bool allowMalformed = true}) {
    final len = value.length;
    if (len == 0) {
      return;
    }

    // Optimize allocation: 3 bytes per char is enough for worst-case UTF-16
    // to UTF-8 expansion.(Surrogate pairs take 2 chars for 4 bytes = 2
    // bytes/char avg. Asian chars take 1 char for 3 bytes = 3 bytes/char avg).
    _ctx._ensureSize(len * 3);

    final list = _ctx._list;
    var offset = _ctx._offset;
    var i = 0;

    while (i < len) {
      // -------------------------------------------------------
      // ASCII Fast Path
      // Loops tightly as long as characters are standard ASCII
      // -------------------------------------------------------
      var c = value.codeUnitAt(i);
      if (c < 128) {
        // Unroll loop slightly or trust JIT/AOT to inline checking
        list[offset++] = c;
        i++;
        // Inner loop for runs of ASCII characters
        while (i < len) {
          c = value.codeUnitAt(i);
          if (c >= 128) {
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
      if (c < 2048) {
        // 2 bytes (Cyrillic, extended Latin, etc.)
        list[offset++] = 192 | (c >> 6);
        list[offset++] = 128 | (c & 63);
        i++;
      } else if (c < 0xD800 || c > 0xDFFF) {
        // 3 bytes (Standard BMP plane, excluding surrogates)
        list[offset++] = 224 | (c >> 12);
        list[offset++] = 128 | ((c >> 6) & 63);
        list[offset++] = 128 | (c & 63);
        i++;
      } else {
        // 4 bytes or malformed (Surrogates)
        // Check for high surrogate
        if (c >= 0xD800 && c <= 0xDBFF) {
          if (i + 1 < len) {
            final next = value.codeUnitAt(i + 1);
            if (next >= 0xDC00 && next <= 0xDFFF) {
              // Valid surrogate pair
              final n = 0x10000 + ((c & 0x3FF) << 10) + (next & 0x3FF);
              list[offset++] = 240 | (n >> 18);
              list[offset++] = 128 | ((n >> 12) & 63);
              list[offset++] = 128 | ((n >> 6) & 63);
              list[offset++] = 128 | (n & 63);
              i += 2;
              continue;
            }
          }
        }

        // Handle error cases (Lone surrogates)
        if (!allowMalformed) {
          throw FormatException(
            'Invalid UTF-16: lone surrogate at index $i',
            value,
            i,
          );
        }

        // Replacement char U+FFFD (EF BF BD)
        list[offset++] = 0xEF;
        list[offset++] = 0xBF;
        list[offset++] = 0xBD;
        i++;
      }
    }

    _ctx._offset = offset;
  }

  Uint8List takeBytes() {
    final result = Uint8List.sublistView(_ctx._list, 0, _ctx._offset);
    _ctx._initializeBuffer();
    return result;
  }

  Uint8List toBytes() => Uint8List.sublistView(_ctx._list, 0, _ctx._offset);

  void reset() => _ctx._initializeBuffer();
}

final class _Buffer {
  _Buffer(int initialBufferSize)
    : _size = initialBufferSize,
      _capacity = initialBufferSize,
      _list = Uint8List(initialBufferSize) {
    _data = _list.buffer.asByteData();
  }

  /// Current write position in the buffer.
  var _offset = 0;

  /// Cached buffer capacity to avoid repeated length checks.
  var _capacity = 0;

  late Uint8List _list;

  late ByteData _data;

  final int _size;

  void _initializeBuffer() {
    final newBuffer = Uint8List(_size);

    _list = newBuffer;
    _data = newBuffer.buffer.asByteData();
    _capacity = _size;
    _offset = 0;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void _ensureSize(int size) {
    if (_offset + size <= _capacity) {
      return;
    }
    _expand(size);
  }

  void _expand(int size) {
    final req = _offset + size;
    var newCapacity = _capacity * 3 ~/ 2;
    if (newCapacity < req) {
      newCapacity = req;
    }

    final newBuffer = Uint8List(newCapacity)..setRange(0, _offset, _list);

    _list = newBuffer;
    _data = newBuffer.buffer.asByteData();
    _capacity = newCapacity;
  }
}
