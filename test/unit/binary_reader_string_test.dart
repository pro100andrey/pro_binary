import 'dart:convert';
import 'dart:typed_data';

import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('BinaryReader String Operations', () {
    test('readString correctly', () {
      const str = 'Hello, world!';
      final encoded = utf8.encode(str);
      final reader = BinaryReader(Uint8List.fromList(encoded));
      expect(reader.readString(encoded.length), equals(str));
    });

    test('readString with multi-byte UTF-8 characters', () {
      const str = 'Привет, мир!';
      final encoded = utf8.encode(str);
      final reader = BinaryReader(Uint8List.fromList(encoded));
      expect(reader.readString(encoded.length), equals(str));
    });

    group('Malformed UTF-8', () {
      test('readString with allowMalformed=true handles invalid UTF-8', () {
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
        final buffer = Uint8List.fromList([0xFF, 0xFE]);
        final reader = BinaryReader(buffer);
        expect(() => reader.readString(2), throwsA(isA<FormatException>()));
      });
    });

    group('Lone surrogate pairs', () {
      test('readString handles lone high surrogate', () {
        // Surrogate in isolation is malformed UTF-8 when encoded/decoded
        final buffer = Uint8List.fromList([0xED, 0xA0, 0x80]); // U+D800
        final reader = BinaryReader(buffer);
        final result = reader.readString(buffer.length, allowMalformed: true);
        expect(result, isNotEmpty);
      });
    });
  });
}
