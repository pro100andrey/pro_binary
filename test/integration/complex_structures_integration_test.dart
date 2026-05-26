import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('Complex Structures Integration Tests', () {
    test('write and read sequence of different types', () {
      final writer = BinaryWriter()
        ..writeUint8(255)
        ..writeInt8(-128)
        ..writeUint16(65535)
        ..writeInt16(-32768)
        ..writeUint32(4294967295)
        ..writeInt32(-2147483648)
        ..writeUint64(9223372036854775807)
        ..writeInt64(-9223372036854775808)
        ..writeFloat32(1.5)
        ..writeFloat64(2.718281828);

      final reader = BinaryReader(writer.takeBytes());
      expect(reader.readUint8(), equals(255));
      expect(reader.readInt8(), equals(-128));
      expect(reader.readUint16(), equals(65535));
      expect(reader.readInt16(), equals(-32768));
      expect(reader.readUint32(), equals(4294967295));
      expect(reader.readInt32(), equals(-2147483648));
      expect(reader.readUint64(), equals(9223372036854775807));
      expect(reader.readInt64(), equals(-9223372036854775808));
      expect(reader.readFloat32(), closeTo(1.5, 0.01));
      expect(reader.readFloat64(), closeTo(2.718281828, 0.000000001));
    });

    group('Real-world message format simulation', () {
      test('protocol with header and payload', () {
        final writer = BinaryWriter()
          // Header
          ..writeUint8(1) // version
          ..writeUint8(42) // message type
          ..writeUint32(123456) // message id
          // Payload
          ..writeVarString('user@example.com')
          ..writeVarUint(1000)
          ..writeBool(true);

        final reader = BinaryReader(writer.takeBytes());

        // Read header
        expect(reader.readUint8(), equals(1));
        expect(reader.readUint8(), equals(42));
        expect(reader.readUint32(), equals(123456));

        // Read payload
        expect(reader.readVarString(), equals('user@example.com'));
        expect(reader.readVarUint(), equals(1000));
        expect(reader.readBool(), isTrue);
      });
    });
  });
}
