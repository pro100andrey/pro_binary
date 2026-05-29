import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('StreamBinaryReader Chunk Operations', () {
    late StreamBinaryReader reader;

    setUp(() {
      reader = StreamBinaryReader();
    });

    test('readUint8 handles chunk boundary', () {
      reader
        ..addChunk([1])
        ..addChunk([2]);
      expect(reader.readUint8(), equals(1));
      expect(reader.readUint8(), equals(2));
      expect(reader.availableBytes, equals(0));
    });

    test('readUint32 handles chunk boundary', () {
      reader
        ..addChunk([0, 0])
        ..addChunk([0, 42]);
      expect(reader.readUint32(), equals(42));
    });

    test('readVarUint handles chunk boundary', () {
      // 300 is [0xAC, 0x02]
      reader
        ..addChunk([0xAC])
        ..addChunk([0x02]);
      expect(reader.readVarUint(), equals(300));
    });

    test('readString handles chunk boundary', () {
      reader
        ..addChunk([72, 101]) // 'He'
        ..addChunk([108, 108, 111]); // 'llo'
      expect(reader.readString(5), equals('Hello'));
    });

    test('bookmark and rollback preserves state', () {
      reader
        ..addChunk([1, 2, 3])
        ..bookmark();
      expect(reader.readUint8(), equals(1));
      expect(reader.readUint8(), equals(2));
      reader.rollback();
      expect(reader.readUint8(), equals(1));
      expect(reader.readUint8(), equals(2));
      expect(reader.readUint8(), equals(3));
    });

    test('NotEnoughDataException thrown when insufficient data', () {
      reader.addChunk([1, 2]);
      expect(() => reader.readUint32(), throwsA(isA<NotEnoughDataException>()));
    });

    test('skip handles chunk boundary', () {
      reader
        ..addChunk([1, 2])
        ..addChunk([3, 4])
        ..skip(3);
      expect(reader.readUint8(), equals(4));
    });

    test('readVarString handles chunk boundary', () {
      final writer = BinaryWriter()..writeVarString('Stream');
      final bytes = writer.takeBytes();

      reader
        ..addChunk(bytes.sublist(0, 3))
        ..addChunk(bytes.sublist(3));

      expect(reader.readVarString(), equals('Stream'));
    });

    test('readStringFixed handles chunk boundary', () {
      final writer = BinaryWriter()
        ..writeStringFixed('Streaming', lengthEncoding: .u16);
      final bytes = writer.takeBytes();

      reader
        ..addChunk(bytes.sublist(0, 5))
        ..addChunk(bytes.sublist(5));

      expect(
        reader.readStringFixed(lengthEncoding: .u16),
        equals('Streaming'),
      );
    });
  });
}
