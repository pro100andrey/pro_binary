import 'dart:convert';
import 'dart:typed_data';

import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('FastBinaryReader', () {
    test('readUint8', () {
      final buffer = Uint8List.fromList([0x01]);
      final reader = FastBinaryReader(buffer);

      expect(reader.readUint8(), equals(1));
      expect(reader.availableBytes, equals(0));
    });

    test('readInt8', () {
      final buffer = Uint8List.fromList([0xFF]);
      final reader = FastBinaryReader(buffer);

      expect(reader.readInt8(), equals(-1));
      expect(reader.availableBytes, equals(0));
    });

    test('readUint16 big-endian', () {
      final buffer = Uint8List.fromList([0x01, 0x00]);
      final reader = FastBinaryReader(buffer);

      expect(reader.readUint16(), equals(256));
      expect(reader.availableBytes, equals(0));
    });

    test('readUint16 little-endian', () {
      final buffer = Uint8List.fromList([0x00, 0x01]);
      final reader = FastBinaryReader(buffer);

      expect(reader.readUint16(.little), equals(256));
      expect(reader.availableBytes, equals(0));
    });

    test('readInt16 big-endian', () {
      final buffer = Uint8List.fromList([0xFF, 0xFF]);
      final reader = FastBinaryReader(buffer);

      expect(reader.readInt16(), equals(-1));
      expect(reader.availableBytes, equals(0));
    });

    test('readInt16 little-endian', () {
      final buffer = Uint8List.fromList([0x00, 0x80]);
      final reader = FastBinaryReader(buffer);

      expect(reader.readInt16(.little), equals(-32768));
      expect(reader.availableBytes, equals(0));
    });

    test('readUint32 big-endian', () {
      final buffer = Uint8List.fromList([0x00, 0x01, 0x00, 0x00]);
      final reader = FastBinaryReader(buffer);

      expect(reader.readUint32(), equals(65536));
      expect(reader.availableBytes, equals(0));
    });

    test('readUint32 little-endian', () {
      final buffer = Uint8List.fromList([0x00, 0x00, 0x01, 0x00]);
      final reader = FastBinaryReader(buffer);

      expect(reader.readUint32(.little), equals(65536));
      expect(reader.availableBytes, equals(0));
    });

    test('readInt32 big-endian', () {
      final buffer = Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF]);
      final reader = FastBinaryReader(buffer);

      expect(reader.readInt32(), equals(-1));
      expect(reader.availableBytes, equals(0));
    });

    test('readInt32 little-endian', () {
      final buffer = Uint8List.fromList([0x00, 0x00, 0x00, 0x80]);
      final reader = FastBinaryReader(buffer);

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
      final reader = FastBinaryReader(buffer);

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
      final reader = FastBinaryReader(buffer);

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
      final reader = FastBinaryReader(buffer);

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
      final reader = FastBinaryReader(buffer);

      expect(reader.readInt64(.little), equals(-9223372036854775808));
      expect(reader.availableBytes, equals(0));
    });

    test('readFloat32 big-endian', () {
      final buffer = Uint8List.fromList([0x40, 0x49, 0x0F, 0xDB]); // 3.1415927
      final reader = FastBinaryReader(buffer);

      expect(reader.readFloat32(), closeTo(3.1415927, 0.0000001));
      expect(reader.availableBytes, equals(0));
    });

    test('readFloat32 little-endian', () {
      final buffer = Uint8List.fromList([0xDB, 0x0F, 0x49, 0x40]); // 3.1415927
      final reader = FastBinaryReader(buffer);

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
      final reader = FastBinaryReader(buffer);

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
      final reader = FastBinaryReader(buffer);

      expect(
        reader.readFloat64(.little),
        closeTo(3.141592653589793, 0.000000000000001),
      );
      expect(reader.availableBytes, equals(0));
    });

    test('readBytes', () {
      final data = [0x01, 0x02, 0x03, 0x04, 0x05];
      final buffer = Uint8List.fromList(data);
      final reader = FastBinaryReader(buffer);

      expect(reader.readBytes(5), equals(data));
      expect(reader.availableBytes, equals(0));
    });

    test('readString', () {
      const str = 'Hello, world!';
      final encoded = utf8.encode(str);
      final buffer = Uint8List.fromList(encoded);
      final reader = FastBinaryReader(buffer);

      expect(reader.readString(encoded.length), equals(str));
      expect(reader.availableBytes, equals(0));
    });

    test('readString with multi-byte UTF-8 characters', () {
      const str = 'Привет, мир!'; // "Hello, world!" in Russian
      final encoded = utf8.encode(str);
      final buffer = Uint8List.fromList(encoded);
      final reader = FastBinaryReader(buffer);

      expect(reader.readString(encoded.length), equals(str));
      expect(reader.availableBytes, equals(0));
    });

    test('availableBytes returns correct number of remaining bytes', () {
      final buffer = Uint8List.fromList([0x01, 0x02, 0x03, 0x04]);
      final reader = FastBinaryReader(buffer);

      expect(reader.availableBytes, equals(4));
      reader.readUint8();
      expect(reader.availableBytes, equals(3));
      reader.readBytes(2);
      expect(reader.availableBytes, equals(1));
    });

    test('usedBytes returns correct number of used bytes', () {
      final buffer = Uint8List.fromList([0x01, 0x02, 0x03, 0x04]);
      final reader = FastBinaryReader(buffer);

      expect(reader.offset, equals(0));
      reader.readUint8();
      expect(reader.offset, equals(1));
      reader.readBytes(2);
      expect(reader.offset, equals(3));
    });

    test(
      'peekBytes returns correct bytes without changing the internal state',
      () {
        final buffer = Uint8List.fromList([0x10, 0x20, 0x30, 0x40, 0x50]);
        final reader = FastBinaryReader(buffer);

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
      final reader = FastBinaryReader(buffer)..skip(2);
      expect(reader.offset, equals(2));
      expect(reader.readUint8(), equals(0x02));
    });

    test('read zero-length bytes', () {
      final buffer = Uint8List.fromList([]);
      final reader = FastBinaryReader(buffer);

      expect(reader.readBytes(0), equals([]));
      expect(reader.availableBytes, equals(0));
    });

    test('read beyond buffer throws AssertionError', () {
      final buffer = Uint8List.fromList([0x01, 0x02]);
      final reader = FastBinaryReader(buffer);

      expect(reader.readUint32, throwsA(isA<AssertionError>()));
    });

    test('negative length input throws AssertionError', () {
      final buffer = Uint8List.fromList([0x01, 0x02]);
      final reader = FastBinaryReader(buffer);

      expect(() => reader.readBytes(-1), throwsA(isA<AssertionError>()));
      expect(() => reader.skip(-5), throwsA(isA<AssertionError>()));
      expect(() => reader.peekBytes(-2), throwsA(isA<AssertionError>()));
    });

    test('reading from empty buffer', () {
      final buffer = Uint8List.fromList([]);
      final reader = FastBinaryReader(buffer);

      expect(reader.readUint8, throwsA(isA<AssertionError>()));
    });

    test('reading with offset at end of buffer', () {
      final buffer = Uint8List.fromList([0x01, 0x02]);
      final reader = FastBinaryReader(buffer)..skip(2);

      expect(reader.readUint8, throwsA(isA<AssertionError>()));
    });

    test('peekBytes beyond buffer throws AssertionError', () {
      final buffer = Uint8List.fromList([0x01, 0x02]);
      final reader = FastBinaryReader(buffer);

      expect(() => reader.peekBytes(3), throwsA(isA<AssertionError>()));
      expect(() => reader.peekBytes(1, 2), throwsA(isA<AssertionError>()));
    });

    test('readString with insufficient bytes throws AssertionError', () {
      final buffer = Uint8List.fromList([0x48, 0x65]); // 'He'
      final reader = FastBinaryReader(buffer);

      expect(() => reader.readString(5), throwsA(isA<AssertionError>()));
    });

    test('readBytes with insufficient bytes throws AssertionError', () {
      final buffer = Uint8List.fromList([0x01, 0x02]);
      final reader = FastBinaryReader(buffer);

      expect(() => reader.readBytes(3), throwsA(isA<AssertionError>()));
    });

    test('read methods throw AssertionError when not enough bytes', () {
      final buffer = Uint8List.fromList([0x00, 0x01]);
      final reader = FastBinaryReader(buffer);

      expect(reader.readUint32, throwsA(isA<AssertionError>()));
      expect(reader.readInt32, throwsA(isA<AssertionError>()));
      expect(reader.readFloat32, throwsA(isA<AssertionError>()));
    });

    test(
      'readUint64 and readInt64 with insufficient bytes throw AssertionError',
      () {
        final buffer = Uint8List.fromList(List.filled(7, 0x00)); // Only 7 bytes
        final reader = FastBinaryReader(buffer);

        expect(reader.readUint64, throwsA(isA<AssertionError>()));
        expect(reader.readInt64, throwsA(isA<AssertionError>()));
      },
    );

    test('skip beyond buffer throws AssertionError', () {
      final buffer = Uint8List.fromList([0x01, 0x02]);
      final reader = FastBinaryReader(buffer);

      expect(() => reader.skip(3), throwsA(isA<AssertionError>()));
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
      final reader = FastBinaryReader(buffer);

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
      final reader = FastBinaryReader(buffer);

      expect(reader.readString(encoded.length), equals(str));
    });

    group('Boundary checks', () {
      test('readUint8 throws when buffer is empty', () {
        final buffer = Uint8List.fromList([]);
        final reader = FastBinaryReader(buffer);

        expect(reader.readUint8, throwsA(isA<AssertionError>()));
      });

      test('readInt8 throws when buffer is empty', () {
        final buffer = Uint8List.fromList([]);
        final reader = FastBinaryReader(buffer);

        expect(reader.readInt8, throwsA(isA<AssertionError>()));
      });

      test('readUint16 throws when only 1 byte available', () {
        final buffer = Uint8List.fromList([0x01]);
        final reader = FastBinaryReader(buffer);

        expect(reader.readUint16, throwsA(isA<AssertionError>()));
      });

      test('readInt16 throws when only 1 byte available', () {
        final buffer = Uint8List.fromList([0xFF]);
        final reader = FastBinaryReader(buffer);

        expect(reader.readInt16, throwsA(isA<AssertionError>()));
      });

      test('readUint32 throws when only 3 bytes available', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03]);
        final reader = FastBinaryReader(buffer);

        expect(reader.readUint32, throwsA(isA<AssertionError>()));
      });

      test('readInt32 throws when only 3 bytes available', () {
        final buffer = Uint8List.fromList([0xFF, 0xFF, 0xFF]);
        final reader = FastBinaryReader(buffer);

        expect(reader.readInt32, throwsA(isA<AssertionError>()));
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
        final reader = FastBinaryReader(buffer);

        expect(reader.readUint64, throwsA(isA<AssertionError>()));
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
        final reader = FastBinaryReader(buffer);

        expect(reader.readInt64, throwsA(isA<AssertionError>()));
      });

      test('readFloat32 throws when only 3 bytes available', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03]);
        final reader = FastBinaryReader(buffer);

        expect(reader.readFloat32, throwsA(isA<AssertionError>()));
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
        final reader = FastBinaryReader(buffer);

        expect(reader.readFloat64, throwsA(isA<AssertionError>()));
      });

      test('readBytes throws when requested length exceeds available', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03]);
        final reader = FastBinaryReader(buffer);

        expect(() => reader.readBytes(5), throwsA(isA<AssertionError>()));
      });

      test('readBytes throws when length is negative', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03]);
        final reader = FastBinaryReader(buffer);

        expect(() => reader.readBytes(-1), throwsA(isA<AssertionError>()));
      });

      test('readString throws when requested length exceeds available', () {
        final buffer = Uint8List.fromList([0x48, 0x65, 0x6C]); // "Hel"
        final reader = FastBinaryReader(buffer);

        expect(() => reader.readString(10), throwsA(isA<AssertionError>()));
      });

      test('multiple reads exceed buffer size', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03, 0x04]);
        final reader = FastBinaryReader(buffer)
          ..readUint8() // 1 byte read, 3 remaining
          ..readUint8() // 1 byte read, 2 remaining
          ..readUint16(); // 2 bytes read, 0 remaining

        expect(reader.readUint8, throwsA(isA<AssertionError>()));
      });

      test('peekBytes throws when length is negative', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03]);
        final reader = FastBinaryReader(buffer);

        expect(() => reader.peekBytes(-1), throwsA(isA<AssertionError>()));
      });

      test('skip throws when length exceeds available bytes', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03]);
        final reader = FastBinaryReader(buffer);

        expect(() => reader.skip(5), throwsA(isA<AssertionError>()));
      });

      test('skip throws when length is negative', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03]);
        final reader = FastBinaryReader(buffer);

        expect(() => reader.skip(-1), throwsA(isA<AssertionError>()));
      });
    });

    group('offset getter', () {
      test('offset returns current reading position', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03, 0x04]);
        final reader = FastBinaryReader(buffer);

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
        final reader = FastBinaryReader(buffer)..readUint8();
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
        final reader = FastBinaryReader(buffer);

        expect(reader.readString(0), equals(''));
        expect(reader.availableBytes, equals(0));
      });

      test('readString with emoji characters', () {
        const str = '🚀👨‍👩‍👧‍👦'; // Rocket and family emoji
        final encoded = utf8.encode(str);
        final buffer = Uint8List.fromList(encoded);
        final reader = FastBinaryReader(buffer);

        expect(reader.readString(encoded.length), equals(str));
        expect(reader.availableBytes, equals(0));
      });

      test('readFloat32 with NaN', () {
        final buffer = Uint8List(4);
        ByteData.view(buffer.buffer).setFloat32(0, double.nan);
        final reader = FastBinaryReader(buffer);

        expect(reader.readFloat32().isNaN, isTrue);
      });

      test('readFloat32 with Infinity', () {
        final buffer = Uint8List(4);
        ByteData.view(buffer.buffer).setFloat32(0, double.infinity);
        final reader = FastBinaryReader(buffer);

        expect(reader.readFloat32(), equals(double.infinity));
      });

      test('readFloat32 with negative Infinity', () {
        final buffer = Uint8List(4);
        ByteData.view(buffer.buffer).setFloat32(0, double.negativeInfinity);
        final reader = FastBinaryReader(buffer);

        expect(reader.readFloat32(), equals(double.negativeInfinity));
      });

      test('readFloat64 with NaN', () {
        final buffer = Uint8List(8);
        ByteData.view(buffer.buffer).setFloat64(0, double.nan);
        final reader = FastBinaryReader(buffer);

        expect(reader.readFloat64().isNaN, isTrue);
      });

      test('readFloat64 with Infinity', () {
        final buffer = Uint8List(8);
        ByteData.view(buffer.buffer).setFloat64(0, double.infinity);
        final reader = FastBinaryReader(buffer);

        expect(reader.readFloat64(), equals(double.infinity));
      });

      test('readFloat64 with negative Infinity', () {
        final buffer = Uint8List(8);
        ByteData.view(buffer.buffer).setFloat64(0, double.negativeInfinity);
        final reader = FastBinaryReader(buffer);

        expect(reader.readFloat64(), equals(double.negativeInfinity));
      });

      test('readFloat64 with negative zero', () {
        final buffer = Uint8List(8);
        ByteData.view(buffer.buffer).setFloat64(0, -0);
        final reader = FastBinaryReader(buffer);

        final value = reader.readFloat64();
        expect(value, equals(0.0));
        expect(value.isNegative, isTrue);
      });

      test('readUint64 with maximum value', () {
        final buffer = Uint8List.fromList([
          0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, //
        ]);
        final reader = FastBinaryReader(buffer);

        // Max Uint64 is 2^64 - 1 = 18446744073709551615
        // In Dart, this wraps to -1 for signed int representation
        expect(reader.readUint64(), equals(0xFFFFFFFFFFFFFFFF));
      });

      test('peekBytes with zero length', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03]);
        final reader = FastBinaryReader(buffer);

        expect(reader.peekBytes(0), equals([]));
        expect(reader.offset, equals(0));
      });

      test('peekBytes with explicit zero offset', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03]);
        final reader = FastBinaryReader(buffer)..readUint8();

        final peeked = reader.peekBytes(2, 0);
        expect(peeked, equals([0x01, 0x02]));
        expect(reader.offset, equals(1));
      });

      test('multiple resets in sequence', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03]);
        final reader = FastBinaryReader(buffer)
          ..readUint8()
          ..reset()
          ..reset()
          ..reset();

        expect(reader.offset, equals(0));
        expect(reader.availableBytes, equals(3));
      });

      test('read after buffer exhaustion and reset', () {
        final buffer = Uint8List.fromList([0x42, 0x43]);
        final reader = FastBinaryReader(buffer);

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
        final reader = FastBinaryReader(buffer);

        final result = reader.readString(buffer.length, allowMalformed: true);
        expect(result, contains('Hello'));
        expect(result, contains('World'));
      });

      test('readString with allowMalformed=false throws on invalid UTF-8', () {
        final buffer = Uint8List.fromList([0xFF, 0xFE, 0xFD]);
        final reader = FastBinaryReader(buffer);

        expect(
          () => reader.readString(buffer.length),
          throwsA(isA<FormatException>()),
        );
      });

      test('readString handles truncated multi-byte sequence', () {
        final buffer = Uint8List.fromList([0xE0, 0xA0]);
        final reader = FastBinaryReader(buffer);

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
        final reader = FastBinaryReader(buffer);

        final result = reader.readString(buffer.length, allowMalformed: true);
        expect(result, startsWith('Hello'));
      });
    });

    group('Lone surrogate pairs', () {
      test('readString handles lone high surrogate', () {
        final buffer = utf8.encode('Test\uD800End');
        final reader = FastBinaryReader(buffer);

        final result = reader.readString(buffer.length, allowMalformed: true);
        expect(result, isNotEmpty);
      });

      test('readString handles lone low surrogate', () {
        final buffer = utf8.encode('Test\uDC00End');
        final reader = FastBinaryReader(buffer);

        final result = reader.readString(buffer.length, allowMalformed: true);
        expect(result, isNotEmpty);
      });
    });

    group('peekBytes advanced', () {
      test(
        'peekBytes with offset beyond current position but within buffer',
        () {
          final buffer = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
          final reader = FastBinaryReader(buffer)
            ..readUint8()
            ..readUint8();

          final peeked = reader.peekBytes(3, 5);
          expect(peeked, equals([6, 7, 8]));
          expect(reader.offset, equals(2));
        },
      );

      test('peekBytes at buffer boundary', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
        final reader = FastBinaryReader(buffer);

        final peeked = reader.peekBytes(2, 3);
        expect(peeked, equals([4, 5]));
        expect(reader.offset, equals(0));
      });

      test('peekBytes exactly at end with zero length', () {
        final buffer = Uint8List.fromList([1, 2, 3]);
        final reader = FastBinaryReader(buffer);

        final peeked = reader.peekBytes(0, 3);
        expect(peeked, isEmpty);
        expect(reader.offset, equals(0));
      });
    });

    group('Sequential operations', () {
      test('multiple reset calls with intermediate reads', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
        final reader = FastBinaryReader(buffer);

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
        final reader = FastBinaryReader(buffer);

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

        final reader = FastBinaryReader(buffer);
        final result = reader.readBytes(largeSize);

        expect(result.length, equals(largeSize));
        expect(reader.availableBytes, equals(0));
      });

      test('skip large amount of data', () {
        final buffer = Uint8List(100000);
        final reader = FastBinaryReader(buffer)..skip(50000);
        expect(reader.offset, equals(50000));
        expect(reader.availableBytes, equals(50000));
      });
    });

    group('Buffer sharing', () {
      test('multiple readers can read same buffer concurrently', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
        final reader1 = FastBinaryReader(buffer);
        final reader2 = FastBinaryReader(buffer);

        expect(reader1.readUint8(), equals(1));
        expect(reader2.readUint8(), equals(1));
        expect(reader1.readUint8(), equals(2));
        expect(reader2.readUint16(), equals(0x0203));
      });

      test('peekBytes returns independent views', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
        final reader = FastBinaryReader(buffer);

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
        final reader = FastBinaryReader(buffer);

        final bytes = reader.readBytes(3);

        expect(bytes, isA<Uint8List>());
        expect(bytes.length, equals(3));
      });

      test('peekBytes returns view of original buffer', () {
        final buffer = Uint8List.fromList([10, 20, 30, 40, 50]);
        final reader = FastBinaryReader(buffer);

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
        final reader = FastBinaryReader(buffer);

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
        final reader = FastBinaryReader(buffer);

        expect(reader.readFloat32(), closeTo(3.14, 0.01));
        expect(reader.readFloat32(.little), closeTo(2.71, 0.01));
        expect(reader.readFloat64(), closeTo(1.414, 0.001));
        expect(reader.readFloat64(.little), closeTo(1.732, 0.001));
      });
    });

    group('Boundary conditions at exact sizes', () {
      test('buffer exactly matches read size', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4]);
        final reader = FastBinaryReader(buffer);

        final result = reader.readBytes(4);
        expect(result, equals([1, 2, 3, 4]));
        expect(reader.availableBytes, equals(0));
      });

      test('reading exactly to boundary multiple times', () {
        final buffer = Uint8List.fromList([1, 2, 3, 4, 5, 6]);
        final reader = FastBinaryReader(buffer);

        expect(reader.readUint16(), equals(0x0102));
        expect(reader.readUint16(), equals(0x0304));
        expect(reader.readUint16(), equals(0x0506));
        expect(reader.availableBytes, equals(0));
      });
    });
  });
}
