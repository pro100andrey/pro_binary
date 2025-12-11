import 'dart:convert';
import 'dart:typed_data';

import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('BinaryReader', () {
    test('readUint8', () {
      final buffer = Uint8List.fromList([0x01]);
      final reader = BinaryReader(buffer);

      expect(reader.readUint8(), equals(1));
      expect(reader.availableBytes, equals(0));
    });

    test('readInt8', () {
      final buffer = Uint8List.fromList([0xFF]);
      final reader = BinaryReader(buffer);

      expect(reader.readInt8(), equals(-1));
      expect(reader.availableBytes, equals(0));
    });

    test('readUint16 big-endian', () {
      final buffer = Uint8List.fromList([0x01, 0x00]);
      final reader = BinaryReader(buffer);

      expect(reader.readUint16(), equals(256));
      expect(reader.availableBytes, equals(0));
    });

    test('readUint16 little-endian', () {
      final buffer = Uint8List.fromList([0x00, 0x01]);
      final reader = BinaryReader(buffer);

      expect(reader.readUint16(Endian.little), equals(256));
      expect(reader.availableBytes, equals(0));
    });

    test('readInt16 big-endian', () {
      final buffer = Uint8List.fromList([0xFF, 0xFF]);
      final reader = BinaryReader(buffer);

      expect(reader.readInt16(), equals(-1));
      expect(reader.availableBytes, equals(0));
    });

    test('readInt16 little-endian', () {
      final buffer = Uint8List.fromList([0x00, 0x80]);
      final reader = BinaryReader(buffer);

      expect(reader.readInt16(Endian.little), equals(-32768));
      expect(reader.availableBytes, equals(0));
    });

    test('readUint32 big-endian', () {
      final buffer = Uint8List.fromList([0x00, 0x01, 0x00, 0x00]);
      final reader = BinaryReader(buffer);

      expect(reader.readUint32(), equals(65536));
      expect(reader.availableBytes, equals(0));
    });

    test('readUint32 little-endian', () {
      final buffer = Uint8List.fromList([0x00, 0x00, 0x01, 0x00]);
      final reader = BinaryReader(buffer);

      expect(reader.readUint32(Endian.little), equals(65536));
      expect(reader.availableBytes, equals(0));
    });

    test('readInt32 big-endian', () {
      final buffer = Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF]);
      final reader = BinaryReader(buffer);

      expect(reader.readInt32(), equals(-1));
      expect(reader.availableBytes, equals(0));
    });

    test('readInt32 little-endian', () {
      final buffer = Uint8List.fromList([0x00, 0x00, 0x00, 0x80]);
      final reader = BinaryReader(buffer);

      expect(reader.readInt32(Endian.little), equals(-2147483648));
      expect(reader.availableBytes, equals(0));
    });

    test('readUint64 big-endian', () {
      final buffer = Uint8List.fromList([
        0x00,
        0x00,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
        0x00,
      ]);
      final reader = BinaryReader(buffer);

      expect(reader.readUint64(), equals(4294967296));
      expect(reader.availableBytes, equals(0));
    });

    test('readUint64 little-endian', () {
      final buffer = Uint8List.fromList([
        0x00,
        0x00,
        0x00,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
      ]);
      final reader = BinaryReader(buffer);

      expect(reader.readUint64(Endian.little), equals(4294967296));
      expect(reader.availableBytes, equals(0));
    });

    test('readInt64 big-endian', () {
      final buffer = Uint8List.fromList([
        0xFF,
        0xFF,
        0xFF,
        0xFF,
        0xFF,
        0xFF,
        0xFF,
        0xFF,
      ]);
      final reader = BinaryReader(buffer);

      expect(reader.readInt64(), equals(-1));
      expect(reader.availableBytes, equals(0));
    });

    test('readInt64 little-endian', () {
      final buffer = Uint8List.fromList([
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x80,
      ]);
      final reader = BinaryReader(buffer);

      expect(reader.readInt64(Endian.little), equals(-9223372036854775808));
      expect(reader.availableBytes, equals(0));
    });

    test('readFloat32 big-endian', () {
      final buffer = Uint8List.fromList([0x40, 0x49, 0x0F, 0xDB]); // 3.1415927
      final reader = BinaryReader(buffer);

      expect(reader.readFloat32(), closeTo(3.1415927, 0.0000001));
      expect(reader.availableBytes, equals(0));
    });

    test('readFloat32 little-endian', () {
      final buffer = Uint8List.fromList([0xDB, 0x0F, 0x49, 0x40]); // 3.1415927
      final reader = BinaryReader(buffer);

      expect(reader.readFloat32(Endian.little), closeTo(3.1415927, 0.0000001));
      expect(reader.availableBytes, equals(0));
    });

    test('readFloat64 big-endian', () {
      final buffer = Uint8List.fromList([
        0x40,
        0x09,
        0x21,
        0xFB,
        0x54,
        0x44,
        0x2D,
        0x18,
      ]); // 3.141592653589793
      final reader = BinaryReader(buffer);

      expect(
        reader.readFloat64(),
        closeTo(3.141592653589793, 0.000000000000001),
      );
      expect(reader.availableBytes, equals(0));
    });

    test('readFloat64 little-endian', () {
      final buffer = Uint8List.fromList([
        0x18,
        0x2D,
        0x44,
        0x54,
        0xFB,
        0x21,
        0x09,
        0x40,
      ]); // 3.141592653589793
      final reader = BinaryReader(buffer);

      expect(
        reader.readFloat64(Endian.little),
        closeTo(3.141592653589793, 0.000000000000001),
      );
      expect(reader.availableBytes, equals(0));
    });

    test('readBytes', () {
      final data = [0x01, 0x02, 0x03, 0x04, 0x05];
      final buffer = Uint8List.fromList(data);
      final reader = BinaryReader(buffer);

      expect(reader.readBytes(5), equals(data));
      expect(reader.availableBytes, equals(0));
    });

    test('readString', () {
      const str = 'Hello, world!';
      final encoded = utf8.encode(str);
      final buffer = Uint8List.fromList(encoded);
      final reader = BinaryReader(buffer);

      expect(reader.readString(encoded.length), equals(str));
      expect(reader.availableBytes, equals(0));
    });

    test('readString with multi-byte UTF-8 characters', () {
      const str = 'Привет, мир!'; // "Hello, world!" in Russian
      final encoded = utf8.encode(str);
      final buffer = Uint8List.fromList(encoded);
      final reader = BinaryReader(buffer);

      expect(reader.readString(encoded.length), equals(str));
      expect(reader.availableBytes, equals(0));
    });

    test('availableBytes returns correct number of remaining bytes', () {
      final buffer = Uint8List.fromList([0x01, 0x02, 0x03, 0x04]);
      final reader = BinaryReader(buffer);

      expect(reader.availableBytes, equals(4));
      reader.readUint8();
      expect(reader.availableBytes, equals(3));
      reader.readBytes(2);
      expect(reader.availableBytes, equals(1));
    });

    test('usedBytes returns correct number of used bytes', () {
      final buffer = Uint8List.fromList([0x01, 0x02, 0x03, 0x04]);
      final reader = BinaryReader(buffer);

      expect(reader.usedBytes, equals(0));
      reader.readUint8();
      expect(reader.usedBytes, equals(1));
      reader.readBytes(2);
      expect(reader.usedBytes, equals(3));
    });

    test(
      'peekBytes returns correct bytes without changing the internal state',
      () {
        final buffer = Uint8List.fromList([0x10, 0x20, 0x30, 0x40, 0x50]);
        final reader = BinaryReader(buffer);

        final peekedBytes = reader.peekBytes(3);
        expect(peekedBytes, equals([0x10, 0x20, 0x30]));
        expect(reader.usedBytes, equals(0));

        reader.readUint8(); // Now usedBytes should be 1
        final peekedBytesWithOffset = reader.peekBytes(2, 2);
        expect(peekedBytesWithOffset, equals([0x30, 0x40]));
        expect(reader.usedBytes, equals(1));
      },
    );

    test('skip method correctly updates the offset', () {
      final buffer = Uint8List.fromList([0x00, 0x01, 0x02, 0x03, 0x04]);
      final reader = BinaryReader(buffer)..skip(2);
      expect(reader.usedBytes, equals(2));
      expect(reader.readUint8(), equals(0x02));
    });

    test('read zero-length bytes', () {
      final buffer = Uint8List.fromList([]);
      final reader = BinaryReader(buffer);

      expect(reader.readBytes(0), equals([]));
      expect(reader.availableBytes, equals(0));
    });

    test('read beyond buffer throws RangeError', () {
      final buffer = Uint8List.fromList([0x01, 0x02]);
      final reader = BinaryReader(buffer);

      expect(reader.readUint32, throwsRangeError);
    });

    test('negative length input throws ArgumentError', () {
      final buffer = Uint8List.fromList([0x01, 0x02]);
      final reader = BinaryReader(buffer);

      expect(() => reader.readBytes(-1), throwsArgumentError);
      expect(() => reader.skip(-5), throwsArgumentError);
      expect(() => reader.peekBytes(-2), throwsArgumentError);
    });

    test('reading from empty buffer', () {
      final buffer = Uint8List.fromList([]);
      final reader = BinaryReader(buffer);

      expect(reader.readUint8, throwsRangeError);
    });

    test('reading with offset at end of buffer', () {
      final buffer = Uint8List.fromList([0x01, 0x02]);
      final reader = BinaryReader(buffer)..skip(2);

      expect(reader.readUint8, throwsRangeError);
    });

    test('peekBytes beyond buffer throws RangeError', () {
      final buffer = Uint8List.fromList([0x01, 0x02]);
      final reader = BinaryReader(buffer);

      expect(() => reader.peekBytes(3), throwsRangeError);
      expect(() => reader.peekBytes(1, 2), throwsRangeError);
    });

    test('readString with insufficient bytes throws RangeError', () {
      final buffer = Uint8List.fromList([0x48, 0x65]); // 'He'
      final reader = BinaryReader(buffer);

      expect(() => reader.readString(5), throwsRangeError);
    });

    test('readBytes with insufficient bytes throws RangeError', () {
      final buffer = Uint8List.fromList([0x01, 0x02]);
      final reader = BinaryReader(buffer);

      expect(() => reader.readBytes(3), throwsRangeError);
    });

    test('read methods throw RangeError when not enough bytes', () {
      final buffer = Uint8List.fromList([0x00, 0x01]);
      final reader = BinaryReader(buffer);

      expect(reader.readUint32, throwsRangeError);
      expect(reader.readInt32, throwsRangeError);
      expect(reader.readFloat32, throwsRangeError);
    });

    test(
      'readUint64 and readInt64 with insufficient bytes throw RangeError',
      () {
        final buffer = Uint8List.fromList(List.filled(7, 0x00)); // Only 7 bytes
        final reader = BinaryReader(buffer);

        expect(reader.readUint64, throwsRangeError);
        expect(reader.readInt64, throwsRangeError);
      },
    );

    test('skip beyond buffer throws RangeError', () {
      final buffer = Uint8List.fromList([0x01, 0x02]);
      final reader = BinaryReader(buffer);

      expect(() => reader.skip(3), throwsArgumentError);
    });

    test('read and verify multiple values sequentially', () {
      final buffer = Uint8List.fromList([
        0x01, // Uint8
        0xFF, // Int8
        0x00, 0x01, // Uint16 big-endian
        0xFF, 0xFF, // Int16 big-endian
        0x00, 0x00, 0x00, 0x01, // Uint32 big-endian
        0xFF, 0xFF, 0xFF, 0xFF, // Int32 big-endian
        0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // Float64 (double 2.0)
      ]);
      final reader = BinaryReader(buffer);

      expect(reader.readUint8(), equals(0x01));
      expect(reader.readInt8(), equals(-1));
      expect(reader.readUint16(), equals(1));
      expect(reader.readInt16(), equals(-1));
      expect(reader.readUint32(), equals(1));
      expect(reader.readInt32(), equals(-1));
      expect(reader.readFloat64(), equals(2.0));
    });

    test('readString with UTF-8 multi-byte characters', () {
      const str = 'こんにちは世界'; // "Hello, World" in Japanese
      final encoded = utf8.encode(str);
      final buffer = Uint8List.fromList(encoded);
      final reader = BinaryReader(buffer);

      expect(reader.readString(encoded.length), equals(str));
    });

    group('Boundary checks', () {
      test('readUint8 throws when buffer is empty', () {
        final buffer = Uint8List.fromList([]);
        final reader = BinaryReader(buffer);

        expect(reader.readUint8, throwsRangeError);
      });

      test('readInt8 throws when buffer is empty', () {
        final buffer = Uint8List.fromList([]);
        final reader = BinaryReader(buffer);

        expect(reader.readInt8, throwsRangeError);
      });

      test('readUint16 throws when only 1 byte available', () {
        final buffer = Uint8List.fromList([0x01]);
        final reader = BinaryReader(buffer);

        expect(reader.readUint16, throwsRangeError);
      });

      test('readInt16 throws when only 1 byte available', () {
        final buffer = Uint8List.fromList([0xFF]);
        final reader = BinaryReader(buffer);

        expect(reader.readInt16, throwsRangeError);
      });

      test('readUint32 throws when only 3 bytes available', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03]);
        final reader = BinaryReader(buffer);

        expect(reader.readUint32, throwsRangeError);
      });

      test('readInt32 throws when only 3 bytes available', () {
        final buffer = Uint8List.fromList([0xFF, 0xFF, 0xFF]);
        final reader = BinaryReader(buffer);

        expect(reader.readInt32, throwsRangeError);
      });

      test('readUint64 throws when only 7 bytes available', () {
        final buffer = Uint8List.fromList([
          0x01,
          0x02,
          0x03,
          0x04,
          0x05,
          0x06,
          0x07,
        ]);
        final reader = BinaryReader(buffer);

        expect(reader.readUint64, throwsRangeError);
      });

      test('readInt64 throws when only 7 bytes available', () {
        final buffer = Uint8List.fromList([
          0xFF,
          0xFF,
          0xFF,
          0xFF,
          0xFF,
          0xFF,
          0xFF,
        ]);
        final reader = BinaryReader(buffer);

        expect(reader.readInt64, throwsRangeError);
      });

      test('readFloat32 throws when only 3 bytes available', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03]);
        final reader = BinaryReader(buffer);

        expect(reader.readFloat32, throwsRangeError);
      });

      test('readFloat64 throws when only 7 bytes available', () {
        final buffer = Uint8List.fromList([
          0x01,
          0x02,
          0x03,
          0x04,
          0x05,
          0x06,
          0x07,
        ]);
        final reader = BinaryReader(buffer);

        expect(reader.readFloat64, throwsRangeError);
      });

      test('readBytes throws when requested length exceeds available', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03]);
        final reader = BinaryReader(buffer);

        expect(() => reader.readBytes(5), throwsRangeError);
      });

      test('readBytes throws when length is negative', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03]);
        final reader = BinaryReader(buffer);

        expect(() => reader.readBytes(-1), throwsArgumentError);
      });

      test('readString throws when requested length exceeds available', () {
        final buffer = Uint8List.fromList([0x48, 0x65, 0x6C]); // "Hel"
        final reader = BinaryReader(buffer);

        expect(() => reader.readString(10), throwsRangeError);
      });

      test('multiple reads exceed buffer size', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03, 0x04]);
        final reader = BinaryReader(buffer)
          ..readUint8() // 1 byte read, 3 remaining
          ..readUint8() // 1 byte read, 2 remaining
          ..readUint16(); // 2 bytes read, 0 remaining

        expect(reader.readUint8, throwsRangeError);
      });

      test('peekBytes throws when length is negative', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03]);
        final reader = BinaryReader(buffer);

        expect(() => reader.peekBytes(-1), throwsArgumentError);
      });

      test('skip throws when length exceeds available bytes', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03]);
        final reader = BinaryReader(buffer);

        expect(() => reader.skip(5), throwsArgumentError);
      });

      test('skip throws when length is negative', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03]);
        final reader = BinaryReader(buffer);

        expect(() => reader.skip(-1), throwsArgumentError);
      });
    });

    group('offset getter', () {
      test('offset returns current reading position', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03, 0x04]);
        final reader = BinaryReader(buffer);

        expect(reader.offset, equals(0));

        reader.readUint8();
        expect(reader.offset, equals(1));

        reader.readUint16();
        expect(reader.offset, equals(3));

        reader.readUint8();
        expect(reader.offset, equals(4));
      });

      test('offset equals usedBytes', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03]);
        final reader = BinaryReader(buffer)..readUint8();
        expect(reader.offset, equals(reader.usedBytes));

        reader.readUint8();
        expect(reader.offset, equals(reader.usedBytes));
      });

      test('offset resets to 0 after reset', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03]);
        final reader = BinaryReader(buffer)..readUint8();
        expect(reader.offset, equals(1));

        reader.reset();
        expect(reader.offset, equals(0));
      });
    });

    group('Special values and edge cases', () {
      test('readString with empty UTF-8 string', () {
        final buffer = Uint8List.fromList([]);
        final reader = BinaryReader(buffer);

        expect(reader.readString(0), equals(''));
        expect(reader.availableBytes, equals(0));
      });

      test('readString with emoji characters', () {
        const str = '🚀👨‍👩‍👧‍👦'; // Rocket and family emoji
        final encoded = utf8.encode(str);
        final buffer = Uint8List.fromList(encoded);
        final reader = BinaryReader(buffer);

        expect(reader.readString(encoded.length), equals(str));
        expect(reader.availableBytes, equals(0));
      });

      test('readFloat32 with NaN', () {
        final buffer = Uint8List(4);
        ByteData.view(buffer.buffer).setFloat32(0, double.nan);
        final reader = BinaryReader(buffer);

        expect(reader.readFloat32().isNaN, isTrue);
      });

      test('readFloat32 with Infinity', () {
        final buffer = Uint8List(4);
        ByteData.view(buffer.buffer).setFloat32(0, double.infinity);
        final reader = BinaryReader(buffer);

        expect(reader.readFloat32(), equals(double.infinity));
      });

      test('readFloat32 with negative Infinity', () {
        final buffer = Uint8List(4);
        ByteData.view(buffer.buffer).setFloat32(0, double.negativeInfinity);
        final reader = BinaryReader(buffer);

        expect(reader.readFloat32(), equals(double.negativeInfinity));
      });

      test('readFloat64 with NaN', () {
        final buffer = Uint8List(8);
        ByteData.view(buffer.buffer).setFloat64(0, double.nan);
        final reader = BinaryReader(buffer);

        expect(reader.readFloat64().isNaN, isTrue);
      });

      test('readFloat64 with Infinity', () {
        final buffer = Uint8List(8);
        ByteData.view(buffer.buffer).setFloat64(0, double.infinity);
        final reader = BinaryReader(buffer);

        expect(reader.readFloat64(), equals(double.infinity));
      });

      test('readFloat64 with negative Infinity', () {
        final buffer = Uint8List(8);
        ByteData.view(buffer.buffer).setFloat64(0, double.negativeInfinity);
        final reader = BinaryReader(buffer);

        expect(reader.readFloat64(), equals(double.negativeInfinity));
      });

      test('readFloat64 with negative zero', () {
        final buffer = Uint8List(8);
        ByteData.view(buffer.buffer).setFloat64(0, -0);
        final reader = BinaryReader(buffer);

        final value = reader.readFloat64();
        expect(value, equals(0.0));
        expect(value.isNegative, isTrue);
      });

      test('readUint64 with maximum value', () {
        final buffer = Uint8List.fromList([
          0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, //
        ]);
        final reader = BinaryReader(buffer);

        // Max Uint64 is 2^64 - 1 = 18446744073709551615
        // In Dart, this wraps to -1 for signed int representation
        expect(reader.readUint64(), equals(0xFFFFFFFFFFFFFFFF));
      });

      test('peekBytes with zero length', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03]);
        final reader = BinaryReader(buffer);

        expect(reader.peekBytes(0), equals([]));
        expect(reader.offset, equals(0));
      });

      test('peekBytes with explicit zero offset', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03]);
        final reader = BinaryReader(buffer)..readUint8();

        final peeked = reader.peekBytes(2, 0);
        expect(peeked, equals([0x01, 0x02]));
        expect(reader.offset, equals(1));
      });

      test('multiple resets in sequence', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03]);
        final reader = BinaryReader(buffer)
          ..readUint8()
          ..reset()
          ..reset()
          ..reset();

        expect(reader.offset, equals(0));
        expect(reader.availableBytes, equals(3));
      });

      test('read after buffer exhaustion and reset', () {
        final buffer = Uint8List.fromList([0x42, 0x43]);
        final reader = BinaryReader(buffer);

        expect(reader.readUint8(), equals(0x42));
        expect(reader.readUint8(), equals(0x43));
        expect(reader.availableBytes, equals(0));

        reader.reset();
        expect(reader.readUint8(), equals(0x42));
      });
    });
  });
}
