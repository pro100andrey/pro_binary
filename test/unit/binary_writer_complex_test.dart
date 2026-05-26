import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('BinaryWriter Complex Scenarios', () {
    late BinaryWriter writer;

    setUp(() {
      writer = BinaryWriter();
    });

    test('handle complex sequence of different data types', () {
      final writer = BinaryWriter()
        ..writeUint8(42)
        ..writeInt8(-42)
        ..writeUint16(65535)
        ..writeUint32(4294967295)
        ..writeFloat32(3.14)
        ..writeBytes([1, 2, 3]);

      final bytes = writer.takeBytes();
      expect(bytes, isNotEmpty);
      expect(bytes[0], equals(42));
    });

    test('full write-read cycle with all types and mixed endianness', () {
      writer
        ..writeUint8(255)
        ..writeInt8(-128)
        ..writeUint16(65535)
        ..writeInt16(-32768, .little)
        ..writeUint32(4294967295, .little)
        ..writeInt32(-2147483648)
        ..writeFloat32(3.14159, .little)
        ..writeString('Hello, 世界! 🌍')
        ..writeBytes([1, 2, 3, 4, 5]);

      final bytes = writer.takeBytes();
      final reader = BinaryReader(bytes);

      expect(reader.readUint8(), equals(255));
      expect(reader.readInt8(), equals(-128));
      expect(reader.readUint16(), equals(65535));
      expect(reader.readInt16(.little), equals(-32768));
      expect(reader.readUint32(.little), equals(4294967295));
      expect(reader.readInt32(), equals(-2147483648));
      expect(reader.readFloat32(.little), closeTo(3.14159, 0.00001));
      expect(reader.readString(19), equals('Hello, 世界! 🌍'));
      expect(reader.readBytes(5), equals([1, 2, 3, 4, 5]));
    });

    test('complex interleaved writes maintain correct offsets', () {
      final writer = BinaryWriter()
        ..writeUint8(1)
        ..writeVarUint(300)
        ..writeUint16(1000)
        ..writeVarInt(-500)
        ..writeUint32(0xDEADBEEF)
        ..writeVarString('Test')
        ..writeBool(true)
        ..writeVarBytes([1, 2, 3, 4, 5])
        ..writeFloat32(3.14)
        ..writeUint64(123456789);

      final bytes = writer.takeBytes();
      final reader = BinaryReader(bytes);

      expect(reader.readUint8(), equals(1));
      expect(reader.readVarUint(), equals(300));
      expect(reader.readUint16(), equals(1000));
      expect(reader.readVarInt(), equals(-500));
      expect(reader.readUint32(), equals(0xDEADBEEF));
      expect(reader.readVarString(), equals('Test'));
      expect(reader.readBool(), isTrue);
      expect(reader.readVarBytes(), equals([1, 2, 3, 4, 5]));
      expect(reader.readFloat32(), closeTo(3.14, 0.01));
      expect(reader.readUint64(), equals(123456789));
      expect(reader.availableBytes, equals(0));
    });
  });
}
