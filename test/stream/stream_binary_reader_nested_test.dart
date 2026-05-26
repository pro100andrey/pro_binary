import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('StreamBinaryReader - Nested Bookmarks', () {
    late StreamBinaryReader reader;

    setUp(() {
      reader = StreamBinaryReader();
    });

    test('nested bookmarks and rollbacks', () {
      reader
        ..addChunk([1, 2, 3, 4])
        ..bookmark(); // B1
      expect(reader.readUint8(), equals(1));

      reader.bookmark(); // B2
      expect(reader.readUint8(), equals(2));

      reader.rollback(); // back to after 1
      expect(reader.readUint8(), equals(2));

      reader.rollback(); // back to start
      expect(reader.readUint8(), equals(1));
    });

    test('commit and rollback mix', () {
      reader
        ..addChunk([1, 2, 3])
        ..bookmark()
        ..readUint8() // 1
        ..commit()
        ..bookmark()
        ..readUint8() // 2
        ..rollback();

      expect(reader.readUint8(), equals(2));
      expect(reader.readUint8(), equals(3));
    });
  });
}
