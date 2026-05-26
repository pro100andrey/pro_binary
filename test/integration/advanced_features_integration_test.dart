import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('Advanced Features Integration Tests', () {
    test('reader navigation after complex write', () {
      final writer = BinaryWriter()
        ..writeUint32(1)
        ..writeUint32(2)
        ..writeUint32(3);
      final reader = BinaryReader(writer.takeBytes())..seek(4);
      expect(reader.readUint32(), equals(2));

      reader.rewind(4);
      expect(reader.readUint32(), equals(2));
    });

    test('multiple readers on same data', () {
      final writer = BinaryWriter()
        ..writeUint32(100)
        ..writeUint32(200);
      final bytes = writer.takeBytes();

      final reader1 = BinaryReader(bytes);
      final reader2 = BinaryReader(bytes);

      expect(reader1.readUint32(), equals(100));
      expect(reader2.readUint32(), equals(100));
      expect(reader1.readUint32(), equals(200));
      expect(reader2.readUint32(), equals(200));
    });

    test('writer buffer management - toBytes preserves state', () {
      final writer = BinaryWriter()..writeUint32(100);
      final bytes1 = writer.toBytes();
      expect(bytes1, equals([0, 0, 0, 100]));

      writer.writeUint32(200);
      final bytes2 = writer.toBytes();
      expect(bytes2, equals([0, 0, 0, 100, 0, 0, 0, 200]));
    });
  });
}
