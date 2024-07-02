import 'package:pro_binary/src/binary_writer.dart';
import 'package:test/test.dart';

void main() {
  group('BinaryWriterImpl', () {
    test('writeUint8 should write a single byte', () {
      final writer = BinaryWriter()..writeUint8(42);

      // Verify that the byte was written correctly
      expect(writer.takeBytes(), equals([42]));
    });

    // Add more tests here for other methods in BinaryWriterImpl
  });
}
