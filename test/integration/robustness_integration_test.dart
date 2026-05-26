import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('Integration Robustness', () {
    test('validates round-trip for all types', () {
      final writer = BinaryWriter()
        ..writeUint8(255)
        ..writeInt16(-32768)
        ..writeUint32(4294967295)
        ..writeFloat64(3.14159)
        ..writeVarString('Round-trip')
        ..writeBool(true);

      final reader = BinaryReader(writer.takeBytes());
      expect(reader.readUint8(), equals(255));
      expect(reader.readInt16(), equals(-32768));
      expect(reader.readUint32(), equals(4294967295));
      expect(reader.readFloat64(), equals(3.14159));
      expect(reader.readVarString(), equals('Round-trip'));
      expect(reader.readBool(), isTrue);
    });

    test('handles stress test with many small operations', () {
      final writer = BinaryWriter();
      for (var i = 0; i < 1000; i++) {
        writer.writeUint8(i % 256);
      }

      final reader = BinaryReader(writer.takeBytes());
      for (var i = 0; i < 1000; i++) {
        expect(reader.readUint8(), equals(i % 256));
      }
    });

    test('handles boundary conditions writing exactly to buffer boundary', () {
      final writer = BinaryWriter(initialBufferSize: 8)
        //
        // ignore: avoid_js_rounded_ints
        ..writeUint64(0x1122334455667788); // Exactly 8 bytes

      expect(writer.bytesWritten, equals(8));
      final reader = BinaryReader(writer.takeBytes());
      //
      // ignore: avoid_js_rounded_ints
      expect(reader.readUint64(), equals(0x1122334455667788));
    });
  });
}
