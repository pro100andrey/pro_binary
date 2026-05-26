import 'dart:typed_data';

import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('Integrated Types Tests', () {
    group('String handling', () {
      test('write and read mixed Unicode string', () {
        final writer = BinaryWriter();
        const str = 'ASCII_Юникод_中文_🌍';
        writer.writeString(str);
        final reader = BinaryReader(writer.takeBytes());
        expect(reader.readString(reader.availableBytes), equals(str));
      });
    });

    group('Float special values', () {
      test('write and read special floats', () {
        final writer = BinaryWriter()
          ..writeFloat32(double.nan)
          ..writeFloat64(double.infinity);
        final reader = BinaryReader(writer.takeBytes());
        expect(reader.readFloat32().isNaN, isTrue);
        expect(reader.readFloat64(), equals(double.infinity));
      });
    });

    group('Variable-length types', () {
      test('write and read VarUint and VarInt', () {
        final writer = BinaryWriter()
          ..writeVarUint(300)
          ..writeVarInt(-100);
        final reader = BinaryReader(writer.takeBytes());
        expect(reader.readVarUint(), equals(300));
        expect(reader.readVarInt(), equals(-100));
      });

      test('write and read VarBytes and VarString', () {
        final writer = BinaryWriter()
          ..writeVarBytes([1, 2, 3])
          ..writeVarString('Hello');
        final reader = BinaryReader(writer.takeBytes());
        expect(reader.readVarBytes(), equals([1, 2, 3]));
        expect(reader.readVarString(), equals('Hello'));
      });
    });

    group('Boolean operations', () {
      test('write and read multiple booleans', () {
        final writer = BinaryWriter()
          ..writeBool(true)
          ..writeBool(false)
          ..writeBool(true);
        final reader = BinaryReader(writer.takeBytes());
        expect(reader.readBool(), isTrue);
        expect(reader.readBool(), isFalse);
        expect(reader.readBool(), isTrue);
      });
    });

    group('Large data cycles', () {
      test('write and read large data set', () {
        final writer = BinaryWriter();
        final data = Uint8List.fromList(List.generate(1000, (i) => i % 256));
        writer.writeBytes(data);
        final reader = BinaryReader(writer.takeBytes());
        expect(reader.readBytes(1000), equals(data));
      });
    });
  });
}
