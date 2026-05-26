import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('Basic Integration Tests', () {
    test('write and read single Uint8', () {
      final writer = BinaryWriter()..writeUint8(42);
      final reader = BinaryReader(writer.takeBytes());
      expect(reader.readUint8(), equals(42));
    });

    test('write and read single Int8', () {
      final writer = BinaryWriter()..writeInt8(-42);
      final reader = BinaryReader(writer.takeBytes());
      expect(reader.readInt8(), equals(-42));
    });

    test('write and read Uint16 with big-endian', () {
      final writer = BinaryWriter()..writeUint16(65535);
      final reader = BinaryReader(writer.takeBytes());
      expect(reader.readUint16(), equals(65535));
    });

    test('write and read Float32', () {
      final writer = BinaryWriter()..writeFloat32(3.14159);
      final reader = BinaryReader(writer.takeBytes());
      expect(reader.readFloat32(), closeTo(3.14159, 0.00001));
    });

    test('write and read basic cycles for all fixed types', () {
      final writer = BinaryWriter()
        ..writeUint8(1)
        ..writeInt8(-1)
        ..writeUint16(1000)
        ..writeInt16(-1000)
        ..writeUint32(100000)
        ..writeInt32(-100000)
        ..writeUint64(1000000000)
        ..writeInt64(-1000000000)
        ..writeFloat32(1.5)
        ..writeFloat64(2.718);

      final reader = BinaryReader(writer.takeBytes());
      expect(reader.readUint8(), equals(1));
      expect(reader.readInt8(), equals(-1));
      expect(reader.readUint16(), equals(1000));
      expect(reader.readInt16(), equals(-1000));
      expect(reader.readUint32(), equals(100000));
      expect(reader.readInt32(), equals(-100000));
      expect(reader.readUint64(), equals(1000000000));
      expect(reader.readInt64(), equals(-1000000000));
      expect(reader.readFloat32(), equals(1.5));
      expect(reader.readFloat64(), equals(2.718));
    });
  });
}
