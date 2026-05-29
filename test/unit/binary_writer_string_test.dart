import 'dart:convert';

import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('BinaryWriter String Operations', () {
    late BinaryWriter writer;

    setUp(() {
      writer = BinaryWriter();
    });

    group('UTF-8 encoding', () {
      test('encode ASCII characters to matching bytes', () {
        writer.writeString('ABC123');
        expect(writer.takeBytes(), equals([65, 66, 67, 49, 50, 51]));
      });

      test('encode Cyrillic characters as multi-byte UTF-8', () {
        writer.writeString('Привет');
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readString(bytes.length), equals('Привет'));
      });

      test('encode Chinese characters as multi-byte UTF-8', () {
        const str = '你好世界';
        writer.writeString(str);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readString(bytes.length), equals(str));
      });

      test('encode mixed ASCII, Cyrillic, CJK, and emoji in single string', () {
        const str = 'Hello мир 世界 🌍';
        writer.writeString(str);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readString(bytes.length), equals(str));
      });
    });

    group('Lone surrogate pairs', () {
      test('writeString defaults to allowMalformed=true', () {
        const testStr = 'Before\uD800After';
        // Should not throw
        writer.writeString(testStr);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        final result = reader.readString(bytes.length, allowMalformed: true);
        expect(result, contains('\uFFFD'));
      });

      test(
        'writeString handles lone high surrogate with allowMalformed=true',
        () {
          const testStr = 'Before\uD800After';
          writer.writeString(testStr);
          final bytes = writer.takeBytes();

          final reader = BinaryReader(bytes);
          final result = reader.readString(bytes.length, allowMalformed: true);
          expect(result, isNotEmpty);
          expect(result, contains('Before'));
          expect(result, contains('After'));
          expect(result.contains('\uFFFD') || result.contains(''), isTrue);
        },
      );

      test(
        'writeString throws on lone high surrogate with allowMalformed=false',
        () {
          const testStr = 'Before\uD800After';
          expect(
            () => writer.writeString(testStr, allowMalformed: false),
            throwsA(isA<FormatException>()),
          );
        },
      );

      test(
        'writeString handles lone low surrogate with allowMalformed=true',
        () {
          const testStr = 'Before\uDC00After';
          writer.writeString(testStr);
          final bytes = writer.takeBytes();

          final reader = BinaryReader(bytes);
          final result = reader.readString(bytes.length, allowMalformed: true);
          expect(result, isNotEmpty);
          expect(result, contains('Before'));
          expect(result, contains('After'));
          expect(result.contains('\uFFFD') || result.contains(''), isTrue);
        },
      );

      test(
        'writeString throws on lone low surrogate with allowMalformed=false',
        () {
          const testStr = 'Before\uDC00After';
          expect(
            () => writer.writeString(testStr, allowMalformed: false),
            throwsA(isA<FormatException>()),
          );
        },
      );

      test('writeString handles valid surrogate pair', () {
        const testStr = 'Test\u{1F600}End';
        writer.writeString(testStr);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        final result = reader.readString(bytes.length);
        expect(result, equals(testStr));
      });

      test('writeString handles mixed valid and invalid surrogates', () {
        const testStr = 'A\u{1F600}B\uD800C';
        writer.writeString(testStr);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        final result = reader.readString(bytes.length, allowMalformed: true);
        expect(result, contains('A'));
        expect(result, contains('B'));
        expect(result, contains('C'));
        expect(result.contains('\uFFFD') || result.contains(''), isTrue);
      });

      test(
        'writeString throws on mixed surrogates with allowMalformed=false',
        () {
          const testStr = 'A\u{1F600}B\uD800C';
          expect(
            () => writer.writeString(testStr, allowMalformed: false),
            throwsA(isA<FormatException>()),
          );
        },
      );

      test('writeVarString defaults to allowMalformed=true', () {
        const testStr = 'Before\uD800After';
        // Should not throw
        writer.writeVarString(testStr);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        final result = reader.readVarString(allowMalformed: true);
        expect(result, contains('\uFFFD'));
      });

      test('writeVarString respects allowMalformed=false', () {
        const testStr = 'Before\uD800After';
        expect(
          () => writer.writeVarString(testStr, allowMalformed: false),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('Very large strings', () {
      test('writeString with string exceeding initial buffer size', () {
        final writer = BinaryWriter(initialBufferSize: 8);
        const largeString =
            'This is a very long string that exceeds initial'
            ' buffer size and should trigger buffer expansion properly';

        writer.writeString(largeString);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        final result = reader.readString(bytes.length);
        expect(result, equals(largeString));
      });

      test('writeString with string requiring more than 1.5x growth', () {
        final writer = BinaryWriter(initialBufferSize: 4);
        const str = 'Very long string to force larger growth';

        writer.writeString(str);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        final result = reader.readString(bytes.length);
        expect(result, equals(str));
      });

      test('writeString with multi-byte UTF-8 characters exceeding buffer', () {
        final writer = BinaryWriter(initialBufferSize: 8);
        const str = 'Привет мир! Это длинная строка для теста';

        writer.writeString(str);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        final result = reader.readString(bytes.length);
        expect(result, equals(str));
      });

      test('writeString with Chinese characters requiring buffer growth', () {
        final writer = BinaryWriter(initialBufferSize: 16);
        const str = '这是一个非常长的中文字符串用于测试缓冲区扩展功能是否正常工作';

        writer.writeString(str);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        final result = reader.readString(bytes.length);
        expect(result, equals(str));
      });
    });

    group('getUtf8Length function', () {
      test('with ASCII only', () {
        expect(getUtf8Length('Hello'), equals(5));
        expect(getUtf8Length('ABCDEFGH'), equals(8)); // Fast path
      });

      test('with empty string', () {
        expect(getUtf8Length(''), equals(0));
      });

      test('with 2-byte UTF-8 chars', () {
        expect(getUtf8Length('café'), equals(5)); // 'caf' = 3, 'é' = 2
        expect(getUtf8Length('Привет'), equals(12)); // Each Cyrillic = 2 bytes
      });

      test('with 3-byte UTF-8 chars', () {
        expect(getUtf8Length('世界'), equals(6)); // Each Chinese = 3 bytes
        expect(getUtf8Length('你好'), equals(6));
      });

      test('with 4-byte UTF-8 chars (emoji)', () {
        expect(getUtf8Length('🌍'), equals(4));
        expect(getUtf8Length('🎉'), equals(4));
        expect(getUtf8Length('😀'), equals(4));
      });

      test('with mixed content', () {
        // 'Hello' = 5, ', ' = 2, '世界' = 6, '! ' = 2, '🌍' = 4
        expect(getUtf8Length('Hello, 世界! 🌍'), equals(19));
      });

      test('matches actual UTF-8 encoding', () {
        final strings = [
          'Test',
          'Тест',
          '测试',
          '🧪',
          'Mix テスト 123',
          'A' * 100, // Long ASCII for fast path
        ];

        for (final str in strings) {
          final calculated = getUtf8Length(str);
          final actual = utf8.encode(str).length;
          expect(
            calculated,
            equals(actual),
            reason: 'Failed for string: "$str"',
          );
        }
      });

      test('with surrogate pairs', () {
        // Valid surrogate pair forms emoji
        final emoji = String.fromCharCodes([0xD83C, 0xDF0D]); // 🌍
        expect(getUtf8Length(emoji), equals(4));
      });

      test('with malformed high surrogate', () {
        // High surrogate (0xD800-0xDBFF) not followed by low surrogate
        // This triggers the malformed surrogate pair path in getUtf8Length
        final malformed = String.fromCharCodes([
          0xD800,
          0x0041,
        ]); // High surrogate + 'A'
        expect(
          getUtf8Length(malformed),
          equals(4),
        ); // 3 bytes (replacement) + 1 byte (A)
      });

      test('with lone high surrogate at end', () {
        // High surrogate at the end of string (also malformed)
        final malformed = String.fromCharCodes([
          0x0041,
          0xD800,
        ]); // 'A' + high surrogate
        expect(
          getUtf8Length(malformed),
          equals(4),
        ); // 1 byte (A) + 3 bytes (replacement)
      });
    });

    group('Special UTF-8 cases', () {
      test('writeString with only ASCII (fast path)', () {
        const str = 'OnlyASCII123';
        writer.writeString(str);
        final bytes = writer.takeBytes();

        expect(bytes.length, equals(str.length));
      });

      test('writeString with mixed ASCII and multi-byte', () {
        const str = 'ASCII_Юникод_中文';
        writer.writeString(str);
        final bytes = writer.takeBytes();

        expect(bytes.length, greaterThan(str.length));
        final reader = BinaryReader(bytes);
        expect(reader.readString(bytes.length), equals(str));
      });

      test('writeString with only 4-byte characters (emojis)', () {
        const str = '🚀🌟💻🎉🔥';
        writer.writeString(str);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readString(bytes.length), equals(str));
      });

      test('writeString empty string after previous writes', () {
        writer
          ..writeUint8(42)
          ..writeString('')
          ..writeUint8(43);

        final bytes = writer.takeBytes();
        expect(bytes, equals([42, 43]));
      });
    });

    group('writeStringFixed', () {
      test('write with LengthEncoding.u8', () {
        writer.writeStringFixed('ABC');
        expect(writer.takeBytes(), equals([3, 65, 66, 67]));
      });

      test('write with LengthEncoding.u16', () {
        writer.writeStringFixed('ABC', lengthEncoding: LengthEncoding.u16);
        expect(writer.takeBytes(), equals([0, 3, 65, 66, 67]));
      });

      test('write empty string with LengthEncoding.u32', () {
        writer.writeStringFixed('', lengthEncoding: LengthEncoding.u32);
        expect(writer.takeBytes(), equals([0, 0, 0, 0]));
      });

      test('write multi-byte string with LengthEncoding.u8', () {
        writer.writeStringFixed('Привет');
        final bytes = writer.takeBytes();
        expect(bytes[0], equals(12)); // 6 characters * 2 bytes
        expect(utf8.decode(bytes.sublist(1)), equals('Привет'));
      });

      test('write with LengthEncoding.u64', () {
        writer.writeStringFixed('DART', lengthEncoding: LengthEncoding.u64);
        final bytes = writer.takeBytes();
        expect(bytes.length, equals(8 + 4));
        expect(bytes.sublist(0, 8), equals([0, 0, 0, 0, 0, 0, 0, 4]));
        expect(utf8.decode(bytes.sublist(8)), equals('DART'));
      });
    });
  });
}
