import 'dart:typed_data';

import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('Integration Types', () {
    group('String handling', () {
      test('round-trip writes and reads mixed Unicode string', () {
        final writer = BinaryWriter();
        const str = 'ASCII_Юникод_中文_🌍';
        writer.writeString(str);
        final reader = BinaryReader(writer.takeBytes());
        expect(reader.readString(reader.availableBytes), equals(str));
      });
    });

    group('Float special values', () {
      test('round-trip writes and reads special floats', () {
        final writer = BinaryWriter()
          ..writeFloat32(double.nan)
          ..writeFloat64(double.infinity);
        final reader = BinaryReader(writer.takeBytes());
        expect(reader.readFloat32().isNaN, isTrue);
        expect(reader.readFloat64(), equals(double.infinity));
      });
    });

    group('Variable-length types', () {
      test('round-trip writes and reads VarUint and VarInt', () {
        final writer = BinaryWriter()
          ..writeVarUint(300)
          ..writeVarInt(-100);
        final reader = BinaryReader(writer.takeBytes());
        expect(reader.readVarUint(), equals(300));
        expect(reader.readVarInt(), equals(-100));
      });

      test('round-trip writes and reads VarBytes and VarString', () {
        final writer = BinaryWriter()
          ..writeVarBytes([1, 2, 3])
          ..writeVarString('Hello');
        final reader = BinaryReader(writer.takeBytes());
        expect(reader.readVarBytes(), equals([1, 2, 3]));
        expect(reader.readVarString(), equals('Hello'));
      });
    });

    group('Boolean operations', () {
      test('round-trip writes and reads multiple booleans', () {
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
      test('round-trip writes and reads large data set', () {
        final writer = BinaryWriter();
        final data = Uint8List.fromList(List.generate(1000, (i) => i % 256));
        writer.writeBytes(data);
        final reader = BinaryReader(writer.takeBytes());
        expect(reader.readBytes(1000), equals(data));
      });
    });
  });
}
