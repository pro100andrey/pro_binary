import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('StreamBinaryReader', () {
    late StreamBinaryReader reader;

    setUp(() {
      reader = StreamBinaryReader();
    });

    test('readUint8 across chunks', () {
      reader
        ..addChunk([1])
        ..addChunk([2]);
      expect(reader.readUint8(), equals(1));
      expect(reader.readUint8(), equals(2));
      expect(reader.availableBytes, equals(0));
    });

    test('readUint32 across chunks', () {
      reader
        ..addChunk([0, 0])
        ..addChunk([0, 42]);
      expect(reader.readUint32(), equals(42));
    });

    test('readVarUint across chunks', () {
      // 300 is [0xAC, 0x02]
      reader
        ..addChunk([0xAC])
        ..addChunk([0x02]);
      expect(reader.readVarUint(), equals(300));
    });

    test('readString across chunks', () {
      reader
        ..addChunk([72, 101]) // 'He'
        ..addChunk([108, 108, 111]); // 'llo'
      expect(reader.readString(5), equals('Hello'));
    });

    test('bookmark and rollback', () {
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

    test('NotEnoughDataException', () {
      reader.addChunk([1, 2]);
      expect(() => reader.readUint32(), throwsA(isA<NotEnoughDataException>()));
    });

    test('skip across chunks', () {
      reader
        ..addChunk([1, 2])
        ..addChunk([3, 4])
        ..skip(3);
      expect(reader.readUint8(), equals(4));
    });

    test('readVarString across chunks', () {
      final writer = BinaryWriter()..writeVarString('Stream');
      final bytes = writer.takeBytes();

      reader
        ..addChunk(bytes.sublist(0, 3))
        ..addChunk(bytes.sublist(3));

      expect(reader.readVarString(), equals('Stream'));
    });
  });
}
