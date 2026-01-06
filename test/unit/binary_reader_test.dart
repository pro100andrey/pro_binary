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

      expect(reader.readUint16(.little), equals(256));
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

      expect(reader.readInt16(.little), equals(-32768));
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

      expect(reader.readUint32(.little), equals(65536));
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

      expect(reader.readInt32(.little), equals(-2147483648));
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

      expect(reader.readUint64(.little), equals(4294967296));
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

      expect(reader.readInt64(.little), equals(-9223372036854775808));
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

      expect(reader.readFloat32(.little), closeTo(3.1415927, 0.0000001));
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
        reader.readFloat64(.little),
        closeTo(3.141592653589793, 0.000000000000001),
      );
      expect(reader.availableBytes, equals(0));
    });

    test('readVarInt single byte (0)', () {
      final buffer = Uint8List.fromList([0]);
      final reader = BinaryReader(buffer);

      expect(reader.readVarUint(), equals(0));
      expect(reader.availableBytes, equals(0));
    });

    test('readVarInt single byte (127)', () {
      final buffer = Uint8List.fromList([127]);
      final reader = BinaryReader(buffer);

      expect(reader.readVarUint(), equals(127));
      expect(reader.availableBytes, equals(0));
    });

    test('readVarInt two bytes (128)', () {
      final buffer = Uint8List.fromList([0x80, 0x01]);
      final reader = BinaryReader(buffer);

      expect(reader.readVarUint(), equals(128));
      expect(reader.availableBytes, equals(0));
    });

    test('readVarInt two bytes (300)', () {
      final buffer = Uint8List.fromList([0xAC, 0x02]);
      final reader = BinaryReader(buffer);

      expect(reader.readVarUint(), equals(300));
      expect(reader.availableBytes, equals(0));
    });

    test('readVarInt three bytes (16384)', () {
      final buffer = Uint8List.fromList([0x80, 0x80, 0x01]);
      final reader = BinaryReader(buffer);

      expect(reader.readVarUint(), equals(16384));
      expect(reader.availableBytes, equals(0));
    });

    test('readVarInt four bytes (2097151)', () {
      final buffer = Uint8List.fromList([0xFF, 0xFF, 0x7F]);
      final reader = BinaryReader(buffer);

      expect(reader.readVarUint(), equals(2097151));
      expect(reader.availableBytes, equals(0));
    });

    test('readVarInt five bytes (268435455)', () {
      final buffer = Uint8List.fromList([0xFF, 0xFF, 0xFF, 0x7F]);
      final reader = BinaryReader(buffer);

      expect(reader.readVarUint(), equals(268435455));
      expect(reader.availableBytes, equals(0));
    });

    test('readVarInt large value', () {
      final buffer = Uint8List.fromList([0x80, 0x80, 0x80, 0x80, 0x04]);
      final reader = BinaryReader(buffer);

      expect(reader.readVarUint(), equals(1 << 30));
      expect(reader.availableBytes, equals(0));
    });

    test('readVarInt roundtrip with writeVarInt', () {
      final writer = BinaryWriter()
        ..writeVarUint(0)
        ..writeVarUint(1)
        ..writeVarUint(127)
        ..writeVarUint(128)
        ..writeVarUint(300)
        ..writeVarUint(70000)
        ..writeVarUint(1 << 20)
        ..writeVarUint(1 << 30);

      final buffer = writer.takeBytes();
      final reader = BinaryReader(buffer);

      expect(reader.readVarUint(), equals(0));
      expect(reader.readVarUint(), equals(1));
      expect(reader.readVarUint(), equals(127));
      expect(reader.readVarUint(), equals(128));
      expect(reader.readVarUint(), equals(300));
      expect(reader.readVarUint(), equals(70000));
      expect(reader.readVarUint(), equals(1 << 20));
      expect(reader.readVarUint(), equals(1 << 30));
      expect(reader.availableBytes, equals(0));
    });

    test('readZigZag encoding for zero', () {
      final buffer = Uint8List.fromList([0]);
      final reader = BinaryReader(buffer);

      expect(reader.readVarInt(), equals(0));
      expect(reader.availableBytes, equals(0));
    });

    test('readZigZag encoding for positive value 1', () {
      final buffer = Uint8List.fromList([2]);
      final reader = BinaryReader(buffer);

      expect(reader.readVarInt(), equals(1));
      expect(reader.availableBytes, equals(0));
    });

    test('readZigZag encoding for negative value -1', () {
      final buffer = Uint8List.fromList([1]);
      final reader = BinaryReader(buffer);

      expect(reader.readVarInt(), equals(-1));
      expect(reader.availableBytes, equals(0));
    });

    test('readZigZag encoding for positive value 2', () {
      final buffer = Uint8List.fromList([4]);
      final reader = BinaryReader(buffer);

      expect(reader.readVarInt(), equals(2));
      expect(reader.availableBytes, equals(0));
    });

    test('readZigZag encoding for negative value -2', () {
      final buffer = Uint8List.fromList([3]);
      final reader = BinaryReader(buffer);

      expect(reader.readVarInt(), equals(-2));
      expect(reader.availableBytes, equals(0));
    });

    test('readZigZag encoding for large positive value', () {
      final buffer = Uint8List.fromList([0xFE, 0xFF, 0xFF, 0xFF, 0x0F]);
      final reader = BinaryReader(buffer);

      expect(reader.readVarInt(), equals(2147483647));
      expect(reader.availableBytes, equals(0));
    });

    test('readZigZag encoding for large negative value', () {
      final buffer = Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF, 0x0F]);
      final reader = BinaryReader(buffer);

      expect(reader.readVarInt(), equals(-2147483648));
      expect(reader.availableBytes, equals(0));
    });

    test('readZigZag roundtrip with writeZigZag', () {
      final writer = BinaryWriter()
        ..writeVarInt(0)
        ..writeVarInt(1)
        ..writeVarInt(-1)
        ..writeVarInt(2)
        ..writeVarInt(-2)
        ..writeVarInt(100)
        ..writeVarInt(-100)
        ..writeVarInt(2147483647)
        ..writeVarInt(-2147483648);

      final buffer = writer.takeBytes();
      final reader = BinaryReader(buffer);

      expect(reader.readVarInt(), equals(0));
      expect(reader.readVarInt(), equals(1));
      expect(reader.readVarInt(), equals(-1));
      expect(reader.readVarInt(), equals(2));
      expect(reader.readVarInt(), equals(-2));
      expect(reader.readVarInt(), equals(100));
      expect(reader.readVarInt(), equals(-100));
      expect(reader.readVarInt(), equals(2147483647));
      expect(reader.readVarInt(), equals(-2147483648));
      expect(reader.availableBytes, equals(0));
    });

    test('readVarUint throws on truncated varint', () {
      // VarInt with continuation bit set but no following byte
      final buffer = Uint8List.fromList([0x80]); // MSB=1, expects more bytes
      final reader = BinaryReader(buffer);

      expect(reader.readVarUint, throwsA(isA<RangeError>()));
    });

    test('readVarUint throws on incomplete multi-byte varint', () {
      // Two-byte VarInt with only first byte
      final buffer = Uint8List.fromList([0xFF]); // All continuation bits set
      final reader = BinaryReader(buffer);

      expect(reader.readVarUint, throwsA(isA<RangeError>()));
    });

    test('readVarUint throws FormatException on too long varint', () {
      // 11 bytes with all continuation bits set (exceeds 10-byte limit)
      final buffer = Uint8List.fromList([
        0x80, 0x80, 0x80, 0x80, 0x80, //
        0x80, 0x80, 0x80, 0x80, 0x80, //
        0x80, // 11th byte
      ]);
      final reader = BinaryReader(buffer);

      expect(reader.readVarUint, throwsA(isA<FormatException>()));
    });

    test('readVarInt throws on truncated zigzag', () {
      // Truncated VarInt (continuation bit set but no next byte)
      final buffer = Uint8List.fromList([0x80]);
      final reader = BinaryReader(buffer);

      expect(reader.readVarInt, throwsA(isA<RangeError>()));
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

    test(
      'peekBytes returns correct bytes without changing the internal state',
      () {
        final buffer = Uint8List.fromList([0x10, 0x20, 0x30, 0x40, 0x50]);
        final reader = BinaryReader(buffer);

        final peekedBytes = reader.peekBytes(3);
        expect(peekedBytes, equals([0x10, 0x20, 0x30]));
        expect(reader.offset, equals(0));
        reader.readUint8(); // Now usedBytes should be 1
        final peekedBytesWithOffset = reader.peekBytes(2, 2);
        expect(peekedBytesWithOffset, equals([0x30, 0x40]));
        expect(reader.offset, equals(1));
      },
    );

    test('skip method correctly updates the offset', () {
      final buffer = Uint8List.fromList([0x00, 0x01, 0x02, 0x03, 0x04]);
      final reader = BinaryReader(buffer)..skip(2);
      expect(reader.offset, equals(2));
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

      expect(reader.readUint32, throwsA(isA<RangeError>()));
    });

    test('negative length input throws RangeError', () {
      final buffer = Uint8List.fromList([0x01, 0x02]);
      final reader = BinaryReader(buffer);

      expect(() => reader.readBytes(-1), throwsA(isA<RangeError>()));
      expect(() => reader.skip(-5), throwsA(isA<RangeError>()));
      expect(() => reader.peekBytes(-2), throwsA(isA<RangeError>()));
    });

    test('reading from empty buffer', () {
      final buffer = Uint8List.fromList([]);
      final reader = BinaryReader(buffer);

      expect(reader.readUint8, throwsA(isA<RangeError>()));
    });

    test('reading with offset at end of buffer', () {
      final buffer = Uint8List.fromList([0x01, 0x02]);
      final reader = BinaryReader(buffer)..skip(2);

      expect(reader.readUint8, throwsA(isA<RangeError>()));
    });

    test('peekBytes beyond buffer throws RangeError', () {
      final buffer = Uint8List.fromList([0x01, 0x02]);
      final reader = BinaryReader(buffer);

      expect(() => reader.peekBytes(3), throwsA(isA<RangeError>()));
      expect(() => reader.peekBytes(1, 2), throwsA(isA<RangeError>()));
    });

    test('readString with insufficient bytes throws RangeError', () {
      final buffer = Uint8List.fromList([0x48, 0x65]); // 'He'
      final reader = BinaryReader(buffer);

      expect(() => reader.readString(5), throwsA(isA<RangeError>()));
    });

    test('readBytes with insufficient bytes throws RangeError', () {
      final buffer = Uint8List.fromList([0x01, 0x02]);
      final reader = BinaryReader(buffer);

      expect(() => reader.readBytes(3), throwsA(isA<RangeError>()));
    });

    test('read methods throw RangeError when not enough bytes', () {
      final buffer = Uint8List.fromList([0x00, 0x01]);
      final reader = BinaryReader(buffer);

      expect(reader.readUint32, throwsA(isA<RangeError>()));
      expect(reader.readInt32, throwsA(isA<RangeError>()));
      expect(reader.readFloat32, throwsA(isA<RangeError>()));
    });

    test(
      'readUint64 and readInt64 with insufficient bytes throw RangeError',
      () {
        final buffer = Uint8List.fromList(List.filled(7, 0x00)); // Only 7 bytes
        final reader = BinaryReader(buffer);

        expect(reader.readUint64, throwsA(isA<RangeError>()));
        expect(reader.readInt64, throwsA(isA<RangeError>()));
      },
    );

    test('skip beyond buffer throws RangeError', () {
      final buffer = Uint8List.fromList([0x01, 0x02]);
      final reader = BinaryReader(buffer);

      expect(() => reader.skip(3), throwsA(isA<RangeError>()));
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

    group('Boundary checks', () {
      test('readUint8 throws when buffer is empty', () {
        final buffer = Uint8List.fromList([]);
        final reader = BinaryReader(buffer);

        expect(reader.readUint8, throwsA(isA<RangeError>()));
      });

      test('readInt8 throws when buffer is empty', () {
        final buffer = Uint8List.fromList([]);
        final reader = BinaryReader(buffer);

        expect(reader.readInt8, throwsA(isA<RangeError>()));
      });

      test('readUint16 throws when only 1 byte available', () {
        final buffer = Uint8List.fromList([0x01]);
        final reader = BinaryReader(buffer);

        expect(reader.readUint16, throwsA(isA<RangeError>()));
      });

      test('readInt16 throws when only 1 byte available', () {
        final buffer = Uint8List.fromList([0xFF]);
        final reader = BinaryReader(buffer);

        expect(reader.readInt16, throwsA(isA<RangeError>()));
      });

      test('readUint32 throws when only 3 bytes available', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03]);
        final reader = BinaryReader(buffer);

        expect(reader.readUint32, throwsA(isA<RangeError>()));
      });

      test('readInt32 throws when only 3 bytes available', () {
        final buffer = Uint8List.fromList([0xFF, 0xFF, 0xFF]);
        final reader = BinaryReader(buffer);

        expect(reader.readInt32, throwsA(isA<RangeError>()));
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

        expect(reader.readUint64, throwsA(isA<RangeError>()));
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

        expect(reader.readInt64, throwsA(isA<RangeError>()));
      });

      test('readFloat32 throws when only 3 bytes available', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03]);
        final reader = BinaryReader(buffer);

        expect(reader.readFloat32, throwsA(isA<RangeError>()));
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

        expect(reader.readFloat64, throwsA(isA<RangeError>()));
      });

      test('readBytes throws when requested length exceeds available', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03]);
        final reader = BinaryReader(buffer);

        expect(() => reader.readBytes(5), throwsA(isA<RangeError>()));
      });

      test('readBytes throws when length is negative', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03]);
        final reader = BinaryReader(buffer);

        expect(() => reader.readBytes(-1), throwsA(isA<RangeError>()));
      });

      test('readString throws when requested length exceeds available', () {
        final buffer = Uint8List.fromList([0x48, 0x65, 0x6C]); // "Hel"
        final reader = BinaryReader(buffer);

        expect(() => reader.readString(10), throwsA(isA<RangeError>()));
      });

      test('multiple reads exceed buffer size', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03, 0x04]);
        final reader = BinaryReader(buffer)
          ..readUint8() // 1 byte read, 3 remaining
          ..readUint8() // 1 byte read, 2 remaining
          ..readUint16(); // 2 bytes read, 0 remaining

        expect(reader.readUint8, throwsA(isA<RangeError>()));
      });

      test('peekBytes throws when length is negative', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03]);
        final reader = BinaryReader(buffer);

        expect(() => reader.peekBytes(-1), throwsA(isA<RangeError>()));
      });

      test('skip throws when length exceeds available bytes', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03]);
        final reader = BinaryReader(buffer);

        expect(() => reader.skip(5), throwsA(isA<RangeError>()));
      });

      test('skip throws when length is negative', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03]);
        final reader = BinaryReader(buffer);

        expect(() => reader.skip(-1), throwsA(isA<RangeError>()));
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

      test('offset resets to 0 after reset', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03]);
        final reader = BinaryReader(buffer)..readUint8();
        expect(reader.offset, equals(1));
        expect(reader.availableBytes, equals(2));

        reader.reset();
        expect(reader.offset, equals(0));
        expect(reader.availableBytes, equals(3));
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
        ByteData.view(buffer.buffer).setFloat32(0, .nan);
        final reader = BinaryReader(buffer);

        expect(reader.readFloat32().isNaN, isTrue);
      });

      test('readFloat32 with Infinity', () {
        final buffer = Uint8List(4);
        ByteData.view(buffer.buffer).setFloat32(0, .infinity);
        final reader = BinaryReader(buffer);

        expect(reader.readFloat32(), equals(double.infinity));
      });

      test('readFloat32 with negative Infinity', () {
        final buffer = Uint8List(4);
        ByteData.view(buffer.buffer).setFloat32(0, .negativeInfinity);
        final reader = BinaryReader(buffer);

        expect(reader.readFloat32(), equals(double.negativeInfinity));
      });

      test('readFloat64 with NaN', () {
        final buffer = Uint8List(8);
        ByteData.view(buffer.buffer).setFloat64(0, .nan);
        final reader = BinaryReader(buffer);

        expect(reader.readFloat64().isNaN, isTrue);
      });

      test('readFloat64 with Infinity', () {
        final buffer = Uint8List(8);
        ByteData.view(buffer.buffer).setFloat64(0, .infinity);
        final reader = BinaryReader(buffer);

        expect(reader.readFloat64(), equals(double.infinity));
      });

      test('readFloat64 with negative Infinity', () {
        final buffer = Uint8List(8);
        ByteData.view(buffer.buffer).setFloat64(0, .negativeInfinity);
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

    group('Malformed UTF-8', () {
      test('readString with allowMalformed=true handles invalid UTF-8', () {
        // Invalid UTF-8 sequence: 0xFF is not valid in UTF-8
        final buffer = Uint8List.fromList([
          0x48, 0x65, 0x6C, 0x6C, 0x6F, // "Hello"
          0xFF, // Invalid byte
          0x57, 0x6F, 0x72, 0x6C, 0x64, // "World"
        ]);
        final reader = BinaryReader(buffer);

        final result = reader.readString(buffer.length, allowMalformed: true);
        expect(result, contains('Hello'));
        expect(result, contains('World'));
      });

      test('readString with allowMalformed=false throws on invalid UTF-8', () {
        final buffer = Uint8List.fromList([0xFF, 0xFE, 0xFD]);
        final reader = BinaryReader(buffer);

        expect(
          () => reader.readString(buffer.length),
          throwsA(isA<FormatException>()),
        );
      });

      test('readString handles truncated multi-byte sequence', () {
        final buffer = Uint8List.fromList([0xE0, 0xA0]);
        final reader = BinaryReader(buffer);

        expect(
          () => reader.readString(buffer.length),
          throwsA(isA<FormatException>()),
        );
      });

      test('readString with allowMalformed handles truncated sequence', () {
        final buffer = Uint8List.fromList([
          0x48, 0x65, 0x6C, 0x6C, 0x6F, // "Hello"
          0xE0, 0xA0, // Incomplete 3-byte sequence
        ]);
        final reader = BinaryReader(buffer);

        final result = reader.readString(buffer.length, allowMalformed: true);
        expect(result, startsWith('Hello'));
      });
    });

    group('Lone surrogate pairs', () {
      test('readString handles lone high surrogate', () {
        final buffer = utf8.encode('Test\uD800End');
        final reader = BinaryReader(buffer);

        final result = reader.readString(buffer.length, allowMalformed: true);
        expect(result, isNotEmpty);
      });

      test('readString handles lone low surrogate', () {
        final buffer = utf8.encode('Test\uDC00End');
        final reader = BinaryReader(buffer);

        final result = reader.readString(buffer.length, allowMalformed: true);
        expect(result, isNotEmpty);
      });
    });

    group('peekBytes advanced', () {
      test(
        'peekBytes with offset beyond current position but within buffer',
        () {
          final buffer = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
          final reader = BinaryReader(buffer)
            ..readUint8()
            ..readUint8();

          final peeked = reader.peekBytes(3, 5);
          expect(peeked, equals([6, 7, 8]));
          expect(reader.offset, equals(2));
        },
      );

      test('peekBytes at buffer boundary', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
        final reader = BinaryReader(buffer);

        final peeked = reader.peekBytes(2, 3);
        expect(peeked, equals([4, 5]));
        expect(reader.offset, equals(0));
      });

      test('peekBytes exactly at end with zero length', () {
        final buffer = Uint8List.fromList([1, 2, 3]);
        final reader = BinaryReader(buffer);

        final peeked = reader.peekBytes(0, 3);
        expect(peeked, isEmpty);
        expect(reader.offset, equals(0));
      });
    });

    group('Sequential operations', () {
      test('multiple reset calls with intermediate reads', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
        final reader = BinaryReader(buffer);

        expect(reader.readUint8(), equals(1));
        reader.reset();
        expect(reader.readUint8(), equals(1));
        expect(reader.readUint8(), equals(2));
        reader.reset();
        expect(reader.offset, equals(0));
        expect(reader.readUint8(), equals(1));
      });

      test('alternating read and peek operations', () {
        final buffer = Uint8List.fromList([10, 20, 30, 40, 50]);
        final reader = BinaryReader(buffer);

        expect(reader.readUint8(), equals(10));
        expect(reader.peekBytes(2), equals([20, 30]));
        expect(reader.readUint8(), equals(20));
        expect(reader.peekBytes(1, 3), equals([40]));
        expect(reader.readUint8(), equals(30));
      });
    });

    group('Large buffer operations', () {
      test('readBytes with very large length', () {
        const largeSize = 1000000;
        final buffer = Uint8List(largeSize);
        for (var i = 0; i < largeSize; i++) {
          buffer[i] = i % 256;
        }

        final reader = BinaryReader(buffer);
        final result = reader.readBytes(largeSize);

        expect(result.length, equals(largeSize));
        expect(reader.availableBytes, equals(0));
      });

      test('skip large amount of data', () {
        final buffer = Uint8List(100000);
        final reader = BinaryReader(buffer)..skip(50000);
        expect(reader.offset, equals(50000));
        expect(reader.availableBytes, equals(50000));
      });
    });

    group('Buffer sharing', () {
      test('multiple readers can read same buffer concurrently', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
        final reader1 = BinaryReader(buffer);
        final reader2 = BinaryReader(buffer);

        expect(reader1.readUint8(), equals(1));
        expect(reader2.readUint8(), equals(1));
        expect(reader1.readUint8(), equals(2));
        expect(reader2.readUint16(), equals(0x0203));
      });

      test('peekBytes returns independent views', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
        final reader = BinaryReader(buffer);

        final peek1 = reader.peekBytes(3);
        final peek2 = reader.peekBytes(3);

        expect(peek1, equals([1, 2, 3]));
        expect(peek2, equals([1, 2, 3]));
        expect(identical(peek1, peek2), isFalse);
      });
    });

    group('Zero-copy verification', () {
      test('readBytes returns view of original buffer', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
        final reader = BinaryReader(buffer);

        final bytes = reader.readBytes(3);

        expect(bytes, isA<Uint8List>());
        expect(bytes.length, equals(3));
      });

      test('peekBytes returns view of original buffer', () {
        final buffer = Uint8List.fromList([10, 20, 30, 40, 50]);
        final reader = BinaryReader(buffer);

        final peeked = reader.peekBytes(3);

        expect(peeked, isA<Uint8List>());
        expect(peeked, equals([10, 20, 30]));
      });
    });

    group('Mixed endianness operations', () {
      test('reading alternating big and little endian values', () {
        final writer = BinaryWriter()
          ..writeUint16(0x1234)
          ..writeUint16(0x5678, .little)
          ..writeUint32(0x9ABCDEF0)
          ..writeUint32(0x11223344, .little);

        final buffer = writer.takeBytes();
        final reader = BinaryReader(buffer);

        expect(reader.readUint16(), equals(0x1234));
        expect(reader.readUint16(.little), equals(0x5678));
        expect(reader.readUint32(), equals(0x9ABCDEF0));
        expect(reader.readUint32(.little), equals(0x11223344));
      });

      test('float values with different endianness', () {
        final writer = BinaryWriter()
          ..writeFloat32(3.14)
          ..writeFloat32(2.71, .little)
          ..writeFloat64(1.414)
          ..writeFloat64(1.732, .little);

        final buffer = writer.takeBytes();
        final reader = BinaryReader(buffer);

        expect(reader.readFloat32(), closeTo(3.14, 0.01));
        expect(reader.readFloat32(.little), closeTo(2.71, 0.01));
        expect(reader.readFloat64(), closeTo(1.414, 0.001));
        expect(reader.readFloat64(.little), closeTo(1.732, 0.001));
      });
    });

    group('Boundary conditions at exact sizes', () {
      test('buffer exactly matches read size', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4]);
        final reader = BinaryReader(buffer);

        final result = reader.readBytes(4);
        expect(result, equals([1, 2, 3, 4]));
        expect(reader.availableBytes, equals(0));
      });

      test('reading exactly to boundary multiple times', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5, 6]);
        final reader = BinaryReader(buffer);

        expect(reader.readUint16(), equals(0x0102));
        expect(reader.readUint16(), equals(0x0304));
        expect(reader.readUint16(), equals(0x0506));
        expect(reader.availableBytes, equals(0));
      });
    });

    group('baseOffset handling', () {
      test('readBytes works correctly with non-zero baseOffset', () {
        // Create a larger buffer and take a sublist
        // (which will have non-zero baseOffset)
        final largeBuffer = Uint8List(100);
        for (var i = 0; i < 100; i++) {
          largeBuffer[i] = i;
        }

        // Create a view starting at offset 50
        final subBuffer = Uint8List.sublistView(largeBuffer, 50, 60);
        final reader = BinaryReader(subBuffer);

        // Read bytes and verify they match the expected values (50-59)
        final bytes = reader.readBytes(5);
        expect(bytes, equals([50, 51, 52, 53, 54]));
        expect(reader.availableBytes, equals(5));
      });

      test('readString works correctly with non-zero baseOffset', () {
        // Create a buffer with text data
        const text = 'Hello, World!';
        final encoded = utf8.encode(text);

        // Create a larger buffer and copy the text at an offset
        final largeBuffer = Uint8List(100)
          ..setRange(30, 30 + encoded.length, encoded);

        // Create a view of just the text portion
        final subBuffer = Uint8List.sublistView(
          largeBuffer,
          30,
          30 + encoded.length,
        );
        final reader = BinaryReader(subBuffer);

        final result = reader.readString(encoded.length);
        expect(result, equals(text));
        expect(reader.availableBytes, equals(0));
      });

      test('peekBytes works correctly with non-zero baseOffset', () {
        final largeBuffer = Uint8List(50);
        for (var i = 0; i < 50; i++) {
          largeBuffer[i] = i;
        }

        // Create a view starting at offset 20
        final subBuffer = Uint8List.sublistView(largeBuffer, 20, 30);
        final reader = BinaryReader(subBuffer);

        // Peek at bytes without consuming them
        final peeked = reader.peekBytes(5);
        expect(peeked, equals([20, 21, 22, 23, 24]));
        expect(reader.offset, equals(0));

        // Now read and verify
        final read = reader.readBytes(5);
        expect(read, equals([20, 21, 22, 23, 24]));
        expect(reader.offset, equals(5));
      });

      test('readUint16/32/64 work correctly with non-zero baseOffset', () {
        final largeBuffer = Uint8List(100);

        // Write some values at offset 40
        final writer = BinaryWriter()
          ..writeUint16(0x1234)
          ..writeUint32(0x56789ABC)
          // disabling lint for large integer literal
          // ignore: avoid_js_rounded_ints
          ..writeUint64(0x0FEDCBA987654321);

        final data = writer.takeBytes();
        largeBuffer.setRange(40, 40 + data.length, data);

        // Create a view starting at offset 40
        final subBuffer = Uint8List.sublistView(
          largeBuffer,
          40,
          40 + data.length,
        );
        final reader = BinaryReader(subBuffer);

        expect(reader.readUint16(), equals(0x1234));
        expect(reader.readUint32(), equals(0x56789ABC));
        // disabling lint for large integer literal
        // ignore: avoid_js_rounded_ints
        expect(reader.readUint64(), equals(0x0FEDCBA987654321));
        expect(reader.availableBytes, equals(0));
      });

      test('multiple readers from different offsets', () {
        final largeBuffer = Uint8List(100);
        for (var i = 0; i < 100; i++) {
          largeBuffer[i] = i;
        }

        // Create two readers from different offsets
        final reader1 = BinaryReader(
          Uint8List.sublistView(largeBuffer, 10, 20),
        );
        final reader2 = BinaryReader(
          Uint8List.sublistView(largeBuffer, 50, 60),
        );

        expect(reader1.readUint8(), equals(10));
        expect(reader2.readUint8(), equals(50));

        expect(reader1.readBytes(3), equals([11, 12, 13]));
        expect(reader2.readBytes(3), equals([51, 52, 53]));
      });

      test('readVarBytes basic usage', () {
        final writer = BinaryWriter()..writeVarBytes([1, 2, 3, 4]);
        final reader = BinaryReader(writer.takeBytes());

        expect(reader.readVarBytes(), equals([1, 2, 3, 4]));
      });

      test('readVarBytes with empty array', () {
        final writer = BinaryWriter()..writeVarBytes([]);
        final reader = BinaryReader(writer.takeBytes());

        expect(reader.readVarBytes(), equals([]));
      });

      test('readVarBytes multiple arrays', () {
        final writer = BinaryWriter()
          ..writeVarBytes([10, 20])
          ..writeVarBytes([30, 40, 50])
          ..writeVarBytes([60]);
        final reader = BinaryReader(writer.takeBytes());

        expect(reader.readVarBytes(), equals([10, 20]));
        expect(reader.readVarBytes(), equals([30, 40, 50]));
        expect(reader.readVarBytes(), equals([60]));
      });

      test('readVarBytes with large array', () {
        final writer = BinaryWriter();
        final data = List.generate(500, (i) => (i * 3) & 0xFF);
        writer.writeVarBytes(data);
        final reader = BinaryReader(writer.takeBytes());

        final result = reader.readVarBytes();
        expect(result, equals(data));
        expect(result.length, equals(500));
      });

      test('readVarBytes throws on truncated length', () {
        final bytes = Uint8List.fromList([0x85]); // Incomplete VarUint
        final reader = BinaryReader(bytes);

        expect(
          reader.readVarBytes,
          throwsA(isA<RangeError>()),
        );
      });

      test('readVarBytes throws when not enough data', () {
        final bytes = Uint8List.fromList([5, 1, 2]); // Length=5, only 2 bytes
        final reader = BinaryReader(bytes);

        expect(
          reader.readVarBytes,
          throwsA(isA<RangeError>()),
        );
      });

      test('readVarBytes preserves binary data', () {
        final writer = BinaryWriter();
        // Test with all byte values 0-255
        final allBytes = List.generate(256, (i) => i);
        writer.writeVarBytes(allBytes);

        final reader = BinaryReader(writer.takeBytes());
        final result = reader.readVarBytes();

        expect(result, equals(allBytes));
        for (var i = 0; i < 256; i++) {
          expect(result[i], equals(i), reason: 'Byte $i mismatch');
        }
      });

      test('readVarString basic usage', () {
        final writer = BinaryWriter()..writeVarString('Hello');
        final reader = BinaryReader(writer.takeBytes());

        expect(reader.readVarString(), equals('Hello'));
      });

      test('readVarString with UTF-8 multi-byte', () {
        final writer = BinaryWriter()..writeVarString('世界');
        final reader = BinaryReader(writer.takeBytes());

        expect(reader.readVarString(), equals('世界'));
      });

      test('readVarString with emoji', () {
        final writer = BinaryWriter()..writeVarString('🌍🎉');
        final reader = BinaryReader(writer.takeBytes());

        expect(reader.readVarString(), equals('🌍🎉'));
      });

      test('readVarString with empty string', () {
        final writer = BinaryWriter()..writeVarString('');
        final reader = BinaryReader(writer.takeBytes());

        expect(reader.readVarString(), equals(''));
      });

      test('readVarString multiple strings', () {
        final writer = BinaryWriter()
          ..writeVarString('First')
          ..writeVarString('Second 测试')
          ..writeVarString('Third 🎉');
        final reader = BinaryReader(writer.takeBytes());

        expect(reader.readVarString(), equals('First'));
        expect(reader.readVarString(), equals('Second 测试'));
        expect(reader.readVarString(), equals('Third 🎉'));
      });

      test('readVarString with allowMalformed=false on valid data', () {
        final writer = BinaryWriter()..writeVarString('Valid UTF-8');
        final reader = BinaryReader(writer.takeBytes());

        expect(
          reader.readVarString,
          returnsNormally,
        );
      });

      test('readVarString throws on truncated length', () {
        final bytes = Uint8List.fromList([0x85]); // Incomplete VarUint
        final reader = BinaryReader(bytes);

        expect(
          reader.readVarString,
          throwsA(isA<RangeError>()),
        );
      });

      test('readVarString throws when not enough data for string', () {
        final bytes = Uint8List.fromList([5, 65, 66]); // Length=5, only 2 bytes
        final reader = BinaryReader(bytes);

        expect(
          reader.readVarString,
          throwsA(isA<RangeError>()),
        );
      });

      test('baseOffset with readString containing multi-byte UTF-8', () {
        const text = 'Привет мир! 🌍';
        final encoded = utf8.encode(text);

        final largeBuffer = Uint8List(200)
          ..setRange(75, 75 + encoded.length, encoded);

        final subBuffer = Uint8List.sublistView(
          largeBuffer,
          75,
          75 + encoded.length,
        );
        final reader = BinaryReader(subBuffer);

        final result = reader.readString(encoded.length);
        expect(result, equals(text));
      });
    });

    group('Getter properties', () {
      test('offset getter returns current read position', () {
        final writer = BinaryWriter()
          ..writeUint8(1)
          ..writeUint16(2)
          ..writeUint32(3);
        final bytes = writer.takeBytes();
        final reader = BinaryReader(bytes);

        expect(reader.offset, equals(0));
        reader.readUint8();
        expect(reader.offset, equals(1));
        reader.readUint16();
        expect(reader.offset, equals(3));
        reader.readUint32();
        expect(reader.offset, equals(7));
      });

      test('length getter returns total buffer length', () {
        final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
        final reader = BinaryReader(bytes);

        expect(reader.length, equals(5));
        reader.readUint8();
        expect(reader.length, equals(5)); // Length doesn't change
        reader.readUint32();
        expect(reader.length, equals(5));
      });

      test('offset and length used together to calculate availableBytes', () {
        final bytes = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
        final reader = BinaryReader(bytes);

        expect(reader.length, equals(8));
        expect(reader.offset, equals(0));
        expect(reader.availableBytes, equals(8));

        reader.readUint32();
        expect(reader.offset, equals(4));
        expect(reader.length, equals(8));
        expect(reader.availableBytes, equals(4));

        reader.readUint32();
        expect(reader.offset, equals(8));
        expect(reader.length, equals(8));
        expect(reader.availableBytes, equals(0));
      });
    });

    group('readBool', () {
      test('reads false when byte is 0', () {
        final buffer = Uint8List.fromList([0x00]);
        final reader = BinaryReader(buffer);

        expect(reader.readBool(), isFalse);
        expect(reader.availableBytes, equals(0));
      });

      test('reads true when byte is 1', () {
        final buffer = Uint8List.fromList([0x01]);
        final reader = BinaryReader(buffer);

        expect(reader.readBool(), isTrue);
        expect(reader.availableBytes, equals(0));
      });

      test('reads true when byte is any non-zero value', () {
        final testValues = [1, 42, 127, 128, 255];
        for (final value in testValues) {
          final buffer = Uint8List.fromList([value]);
          final reader = BinaryReader(buffer);

          expect(
            reader.readBool(),
            isTrue,
            reason: 'Value $value should be true',
          );
        }
      });

      test('reads multiple boolean values correctly', () {
        final buffer = Uint8List.fromList([0x01, 0x00, 0xFF, 0x00, 0x01]);
        final reader = BinaryReader(buffer);

        expect(reader.readBool(), isTrue);
        expect(reader.readBool(), isFalse);
        expect(reader.readBool(), isTrue);
        expect(reader.readBool(), isFalse);
        expect(reader.readBool(), isTrue);
        expect(reader.availableBytes, equals(0));
      });

      test('advances offset correctly', () {
        final buffer = Uint8List.fromList([0x01, 0x00, 0xFF]);
        final reader = BinaryReader(buffer);

        expect(reader.offset, equals(0));
        reader.readBool();
        expect(reader.offset, equals(1));
        reader.readBool();
        expect(reader.offset, equals(2));
        reader.readBool();
        expect(reader.offset, equals(3));
      });

      test('throws when reading from empty buffer', () {
        final buffer = Uint8List.fromList([]);
        final reader = BinaryReader(buffer);

        expect(reader.readBool, throwsA(isA<RangeError>()));
      });

      test('throws when no bytes available', () {
        final buffer = Uint8List.fromList([0x01]);
        final reader = BinaryReader(buffer)..readBool(); // Consume the byte
        expect(reader.readBool, throwsA(isA<RangeError>()));
      });
    });

    group('readRemainingBytes', () {
      test('reads all remaining bytes from start', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
        final reader = BinaryReader(buffer);

        final remaining = reader.readRemainingBytes();
        expect(remaining, equals([1, 2, 3, 4, 5]));
        expect(reader.availableBytes, equals(0));
      });

      test('reads remaining bytes after partial read', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
        final reader = BinaryReader(buffer)
          // Read first 2 bytes
          ..readUint16();

        final remaining = reader.readRemainingBytes();
        expect(remaining, equals([3, 4, 5, 6, 7, 8]));
        expect(reader.availableBytes, equals(0));
      });

      test('returns empty list when at end of buffer', () {
        final buffer = Uint8List.fromList([1, 2, 3]);
        final reader = BinaryReader(buffer)..readBytes(3); // Read all bytes
        final remaining = reader.readRemainingBytes();
        expect(remaining, isEmpty);
        expect(reader.availableBytes, equals(0));
      });

      test('returns empty list for empty buffer', () {
        final buffer = Uint8List.fromList([]);
        final reader = BinaryReader(buffer);

        final remaining = reader.readRemainingBytes();
        expect(remaining, isEmpty);
        expect(reader.availableBytes, equals(0));
      });

      test('is zero-copy operation', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
        final reader = BinaryReader(buffer)
          // Skip first byte
          ..readUint8();

        final remaining = reader.readRemainingBytes();
        // Verify it's a view by checking buffer reference
        expect(remaining.buffer, equals(buffer.buffer));
      });

      test('can be called multiple times at end', () {
        final buffer = Uint8List.fromList([1, 2, 3]);
        final reader = BinaryReader(buffer)..readBytes(3);

        final first = reader.readRemainingBytes();
        final second = reader.readRemainingBytes();

        expect(first, isEmpty);
        expect(second, isEmpty);
      });

      test('works correctly after seek', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
        final reader = BinaryReader(buffer)..seek(2);

        final remaining = reader.readRemainingBytes();
        expect(remaining, equals([3, 4, 5]));
      });
    });

    group('hasBytes', () {
      test('returns true when enough bytes available', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
        final reader = BinaryReader(buffer);

        expect(reader.hasBytes(1), isTrue);
        expect(reader.hasBytes(3), isTrue);
        expect(reader.hasBytes(5), isTrue);
      });

      test('returns false when not enough bytes available', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
        final reader = BinaryReader(buffer);

        expect(reader.hasBytes(6), isFalse);
        expect(reader.hasBytes(10), isFalse);
        expect(reader.hasBytes(100), isFalse);
      });

      test('returns true for exact remaining bytes', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
        final reader = BinaryReader(buffer)..readUint16(); // Read 2 bytes
        expect(reader.hasBytes(3), isTrue); // Exactly 3 bytes left
        expect(reader.hasBytes(4), isFalse); // Too many
      });

      test('returns true for zero bytes on non-empty buffer', () {
        final buffer = Uint8List.fromList([1, 2, 3]);
        final reader = BinaryReader(buffer);

        expect(reader.hasBytes(0), isTrue);
      });

      test('returns true for zero bytes on empty buffer', () {
        final buffer = Uint8List.fromList([]);
        final reader = BinaryReader(buffer);

        expect(reader.hasBytes(0), isTrue);
        expect(reader.hasBytes(1), isFalse);
      });

      test('works correctly after reading', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
        final reader = BinaryReader(buffer);

        expect(reader.hasBytes(8), isTrue);
        reader.readUint32(); // Read 4 bytes
        expect(reader.hasBytes(5), isFalse);
        expect(reader.hasBytes(4), isTrue);
        reader.readUint32(); // Read 4 more bytes
        expect(reader.hasBytes(1), isFalse);
        expect(reader.hasBytes(0), isTrue);
      });

      test('does not modify offset', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
        final reader = BinaryReader(buffer);

        expect(reader.offset, equals(0));
        reader.hasBytes(3);
        expect(reader.offset, equals(0)); // Offset unchanged
        reader.hasBytes(10);
        expect(reader.offset, equals(0)); // Still unchanged
      });

      test('works correctly after seek', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
        final reader = BinaryReader(buffer)..seek(3);

        expect(reader.hasBytes(2), isTrue);
        expect(reader.hasBytes(3), isFalse);
        expect(reader.offset, equals(3)); // Unchanged
      });

      test('works correctly after rewind', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
        final reader = BinaryReader(buffer)
          ..readBytes(4)
          ..rewind(2);

        expect(reader.hasBytes(3), isTrue);
        expect(reader.hasBytes(4), isFalse);
      });
    });

    group('seek', () {
      test('sets position to beginning', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
        final reader = BinaryReader(buffer)
          ..readUint32() // Move to position 4
          ..seek(0);
        expect(reader.offset, equals(0));
        expect(reader.readUint8(), equals(1));
      });

      test('sets position to middle', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
        final reader = BinaryReader(buffer)..seek(2);
        expect(reader.offset, equals(2));
        expect(reader.readUint8(), equals(3));
      });

      test('sets position to end', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
        final reader = BinaryReader(buffer)..seek(5);
        expect(reader.offset, equals(5));
        expect(reader.availableBytes, equals(0));
      });

      test('allows seeking backwards', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
        final reader = BinaryReader(buffer)
          ..readBytes(4) // Move to position 4
          ..seek(1);
        expect(reader.offset, equals(1));
        expect(reader.readUint8(), equals(2));
      });

      test('allows seeking forwards', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
        final reader = BinaryReader(buffer)
          ..readUint8() // Move to position 1
          ..seek(5);
        expect(reader.offset, equals(5));
        expect(reader.readUint8(), equals(6));
      });

      test('seeking multiple times', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
        final reader = BinaryReader(buffer)..seek(3);
        expect(reader.offset, equals(3));
        reader.seek(1);
        expect(reader.offset, equals(1));
        reader.seek(7);
        expect(reader.offset, equals(7));
        reader.seek(0);
        expect(reader.offset, equals(0));
      });

      test('seeking to same position is valid', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
        final reader = BinaryReader(buffer)
          ..seek(2)
          ..seek(2);
        expect(reader.offset, equals(2));
      });

      test('throws on negative position', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
        final reader = BinaryReader(buffer);

        expect(() => reader.seek(-1), throwsA(isA<RangeError>()));
      });

      test('throws when seeking beyond buffer', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
        final reader = BinaryReader(buffer);

        expect(() => reader.seek(6), throwsA(isA<RangeError>()));
        expect(() => reader.seek(100), throwsA(isA<RangeError>()));
      });
    });

    group('rewind', () {
      test('moves back by specified bytes', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
        final reader = BinaryReader(buffer)
          ..readBytes(3) // Move to position 3
          ..rewind(2);
        expect(reader.offset, equals(1));
        expect(reader.readUint8(), equals(2));
      });

      test('rewind to beginning', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
        final reader = BinaryReader(buffer)
          ..readBytes(3)
          ..rewind(3);
        expect(reader.offset, equals(0));
        expect(reader.readUint8(), equals(1));
      });

      test('rewind single byte', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
        final reader = BinaryReader(buffer)..readUint16(); // Read 2 bytes
        expect(reader.offset, equals(2));
        reader.rewind(1);
        expect(reader.offset, equals(1));
        expect(reader.readUint8(), equals(2));
      });

      test('rewind zero bytes does nothing', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
        final reader = BinaryReader(buffer)..readUint16();
        final offsetBefore = reader.offset;
        reader.rewind(0);
        expect(reader.offset, equals(offsetBefore));
      });

      test('allows re-reading data', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03, 0x04]);
        final reader = BinaryReader(buffer);

        final first = reader.readUint32();
        expect(first, equals(0x01020304));

        reader.rewind(4);
        final second = reader.readUint32();
        expect(second, equals(0x01020304));
        expect(second, equals(first));
      });

      test('multiple rewinds', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
        final reader = BinaryReader(buffer)..readBytes(5); // Position 5
        expect(reader.offset, equals(5));

        reader.rewind(2); // Position 3
        expect(reader.offset, equals(3));

        reader.rewind(1); // Position 2
        expect(reader.offset, equals(2));

        expect(reader.readUint8(), equals(3));
      });

      test('rewind and seek together', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
        final reader = BinaryReader(buffer)
          ..seek(5)
          ..rewind(2);
        expect(reader.offset, equals(3));

        reader.rewind(3);
        expect(reader.offset, equals(0));
      });

      test('throws when rewinding beyond start', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
        final reader = BinaryReader(buffer)..readUint16(); // offset = 2

        expect(() => reader.rewind(3), throwsA(isA<RangeError>()));
      });

      test('throws when rewinding from start', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
        final reader = BinaryReader(buffer);

        expect(() => reader.rewind(1), throwsA(isA<RangeError>()));
      });

      test('throws on negative length', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
        final reader = BinaryReader(buffer)..readBytes(3);

        expect(() => reader.rewind(-1), throwsA(isA<RangeError>()));
      });
    });

    group('VarInt/VarUint edge cases', () {
      test('readVarUint with maximum safe 64-bit value boundary', () {
        // Test value close to overflow boundary
        final writer = BinaryWriter()..writeVarUint(0x7FFFFFFFFFFFFFFF);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readVarUint(), equals(0x7FFFFFFFFFFFFFFF));
      });

      test('readVarInt with maximum positive ZigZag value', () {
        // disabling lint for large integer literal
        // ignore: avoid_js_rounded_ints
        final writer = BinaryWriter()..writeVarInt(0x3FFFFFFFFFFFFFFF);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        // disabling lint for large integer literal
        // ignore: avoid_js_rounded_ints
        expect(reader.readVarInt(), equals(0x3FFFFFFFFFFFFFFF));
      });

      test('readVarInt with minimum negative ZigZag value', () {
        final writer = BinaryWriter()..writeVarInt(-0x4000000000000000);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readVarInt(), equals(-0x4000000000000000));
      });

      test('readVarUint boundary values sequence', () {
        final writer = BinaryWriter()
          ..writeVarUint(0x7F) // 1 byte max
          ..writeVarUint(0x80) // 2 byte min
          ..writeVarUint(0x3FFF) // 2 byte max
          ..writeVarUint(0x4000) // 3 byte min
          ..writeVarUint(0x1FFFFF) // 3 byte max
          ..writeVarUint(0x200000); // 4 byte min

        final bytes = writer.takeBytes();
        final reader = BinaryReader(bytes);

        expect(reader.readVarUint(), equals(0x7F));
        expect(reader.readVarUint(), equals(0x80));
        expect(reader.readVarUint(), equals(0x3FFF));
        expect(reader.readVarUint(), equals(0x4000));
        expect(reader.readVarUint(), equals(0x1FFFFF));
        expect(reader.readVarUint(), equals(0x200000));
      });
    });

    group('VarBytes/VarString error handling', () {
      test('readVarBytes throws when length exceeds available bytes', () {
        // Write VarInt claiming 1000 bytes but only provide 10
        final writer = BinaryWriter()
          ..writeVarUint(1000)
          ..writeBytes(List.filled(10, 42));

        final bytes = writer.takeBytes();
        final reader = BinaryReader(bytes);

        expect(reader.readVarBytes, throwsA(isA<RangeError>()));
      });

      test('readVarString throws when length exceeds available bytes', () {
        // Write VarInt claiming 100 bytes but only provide 5
        final writer = BinaryWriter()
          ..writeVarUint(100)
          ..writeBytes([72, 101, 108, 108, 111]); // "Hello"

        final bytes = writer.takeBytes();
        final reader = BinaryReader(bytes);

        expect(reader.readVarString, throwsA(isA<RangeError>()));
      });

      test('readVarBytes with corrupted length at buffer end', () {
        // VarInt that claims more bytes than buffer has
        final buffer = Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF, 0x0F]);
        final reader = BinaryReader(buffer);

        // Should throw when trying to read the claimed bytes
        expect(reader.readVarBytes, throwsA(isA<RangeError>()));
      });

      test('readVarString handles empty string correctly', () {
        final writer = BinaryWriter()..writeVarString('');
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readVarString(), equals(''));
      });

      test('readVarBytes with zero length', () {
        final writer = BinaryWriter()..writeVarBytes([]);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readVarBytes(), isEmpty);
      });

      test('readVarString with malformed UTF-8 in VarString format', () {
        // Write invalid UTF-8 sequence with VarInt length prefix
        final writer = BinaryWriter()
          ..writeVarUint(3)
          ..writeBytes([0xFF, 0xFE, 0xFD]); // Invalid UTF-8

        final bytes = writer.takeBytes();
        final reader = BinaryReader(bytes);

        expect(
          reader.readVarString,
          throwsA(isA<FormatException>()),
        );

        // Reset and try with allowMalformed
        final reader2 = BinaryReader(bytes);
        final result = reader2.readVarString(allowMalformed: true);
        expect(result, isNotEmpty); // Should contain replacement characters
      });
    });

    group('Partial read scenarios', () {
      test('reading after partial VarInt consumption', () {
        final writer = BinaryWriter()
          ..writeVarUint(300)
          ..writeUint32(0x12345678);

        final bytes = writer.takeBytes();
        final reader = BinaryReader(bytes);

        expect(reader.readVarUint(), equals(300));
        expect(reader.readUint32(), equals(0x12345678));
        expect(reader.availableBytes, equals(0));
      });

      test('interleaved VarInt and fixed-size reads', () {
        final writer = BinaryWriter()
          ..writeVarUint(127)
          ..writeUint8(42)
          ..writeVarInt(-1)
          ..writeUint16(1000)
          ..writeVarUint(128)
          ..writeUint32(0xDEADBEEF);

        final bytes = writer.takeBytes();
        final reader = BinaryReader(bytes);

        expect(reader.readVarUint(), equals(127));
        expect(reader.readUint8(), equals(42));
        expect(reader.readVarInt(), equals(-1));
        expect(reader.readUint16(), equals(1000));
        expect(reader.readVarUint(), equals(128));
        expect(reader.readUint32(), equals(0xDEADBEEF));
      });

      test('readRemainingBytes after VarBytes', () {
        final writer = BinaryWriter()
          ..writeVarBytes([1, 2, 3])
          ..writeBytes([4, 5, 6, 7, 8]);

        final bytes = writer.takeBytes();
        final reader = BinaryReader(bytes);

        final varBytes = reader.readVarBytes();
        expect(varBytes, equals([1, 2, 3]));

        final remaining = reader.readRemainingBytes();
        expect(remaining, equals([4, 5, 6, 7, 8]));
      });
    });

    group('Navigation edge cases', () {
      test('seek and hasBytes combined', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
        final reader = BinaryReader(buffer)..seek(3);
        expect(reader.hasBytes(5), isTrue);
        expect(reader.hasBytes(6), isFalse);

        reader.seek(7);
        expect(reader.hasBytes(1), isTrue);
        expect(reader.hasBytes(2), isFalse);
      });

      test('rewind to exactly zero offset', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
        final reader = BinaryReader(buffer)..readBytes(3);
        expect(reader.offset, equals(3));

        reader.rewind(3);
        expect(reader.offset, equals(0));
        expect(reader.readUint8(), equals(1));
      });

      test('multiple seeks without reading', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
        final reader = BinaryReader(buffer);

        for (var i = 0; i < 8; i++) {
          reader.seek(i);
          expect(reader.offset, equals(i));
        }
      });
    });
  });
}
