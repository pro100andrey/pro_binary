import 'dart:typed_data';

import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('BinaryReader Variable-Length Types', () {
    group('VarInt and VarUint', () {
      test('readVarUint basic values', () {
        expect(BinaryReader(Uint8List.fromList([0])).readVarUint(), equals(0));
        expect(
          BinaryReader(Uint8List.fromList([127])).readVarUint(),
          equals(127),
        );
        expect(
          BinaryReader(Uint8List.fromList([0x80, 0x01])).readVarUint(),
          equals(128),
        );
      });

      test('readVarInt (ZigZag) basic values', () {
        expect(BinaryReader(Uint8List.fromList([0])).readVarInt(), equals(0));
        expect(BinaryReader(Uint8List.fromList([2])).readVarInt(), equals(1));
        expect(BinaryReader(Uint8List.fromList([1])).readVarInt(), equals(-1));
      });

      test('readVarUint throws on truncated varint', () {
        final buffer = Uint8List.fromList([0x80]);
        final reader = BinaryReader(buffer);
        expect(reader.readVarUint, throwsA(isA<RangeError>()));
      });

      test('readVarUint throws FormatException on too long varint', () {
        final buffer = Uint8List.fromList(List.filled(11, 0x80));
        final reader = BinaryReader(buffer);
        expect(reader.readVarUint, throwsA(isA<FormatException>()));
      });
    });

    group('VarBytes', () {
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

      test('readVarBytes throws on truncated length', () {
        final bytes = Uint8List.fromList([0x85]);
        final reader = BinaryReader(bytes);
        expect(reader.readVarBytes, throwsA(isA<RangeError>()));
      });
    });

    group('VarString', () {
      test('readVarString basic usage', () {
        final writer = BinaryWriter()..writeVarString('Hello');
        final reader = BinaryReader(writer.takeBytes());
        expect(reader.readVarString(), equals('Hello'));
      });

      test('readVarString with empty string', () {
        final writer = BinaryWriter()..writeVarString('');
        final reader = BinaryReader(writer.takeBytes());
        expect(reader.readVarString(), equals(''));
      });

      test('readVarString throws when not enough data for string', () {
        final bytes = Uint8List.fromList([5, 65, 66]); // Length 5, only 2 bytes
        final reader = BinaryReader(bytes);
        expect(reader.readVarString, throwsA(isA<RangeError>()));
      });
    });
  });
}
