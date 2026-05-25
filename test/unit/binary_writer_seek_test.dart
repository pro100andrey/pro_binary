import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('BinaryWriter.seek', () {
    late BinaryWriter writer;

    setUp(() {
      writer = BinaryWriter();
    });

    test('seeks to position 0', () {
      writer
        ..writeUint8(1)
        ..writeUint8(2)
        ..writeUint8(3);
      writer.seek(0);
      expect(writer.bytesWritten, equals(0));
      expect(writer.toBytes(), isEmpty);
    });

    test('seeks to middle position', () {
      writer
        ..writeUint8(1)
        ..writeUint8(2)
        ..writeUint8(3)
        ..writeUint8(4);
      writer.seek(2);
      writer.writeUint8(99);
      expect(writer.toBytes(), equals([1, 2, 99]));
    });

    test('seeks to end (bytesWritten)', () {
      writer
        ..writeUint8(1)
        ..writeUint8(2);
      writer.seek(2);
      writer.writeUint8(3);
      expect(writer.toBytes(), equals([1, 2, 3]));
    });

    test('throws RangeError for negative position', () {
      expect(() => writer.seek(-1), throwsA(isA<RangeError>()));
    });

    test('throws RangeError for position beyond bytesWritten', () {
      writer.writeUint8(1);
      expect(() => writer.seek(2), throwsA(isA<RangeError>()));
    });

    test('seek and overwrite at beginning', () {
      writer
        ..writeUint32(0x11223344)
        ..writeUint32(0xAABBCCDD);
      writer.seek(0);
      writer.writeUint32(0x99887766);
      expect(writer.toBytes(), equals([0x99, 0x88, 0x77, 0x66]));
    });

    test('seek preserves bytesWritten after overwrite', () {
      writer
        ..writeUint8(1)
        ..writeUint8(2)
        ..writeUint8(3);
      writer.seek(1);
      writer.writeUint8(99);
      expect(writer.bytesWritten, equals(2));
    });
  });

  group('BinaryWriter.writeUint8At', () {
    late BinaryWriter writer;

    setUp(() {
      writer = BinaryWriter();
    });

    test('overwrites byte at position 0', () {
      writer
        ..writeUint8(1)
        ..writeUint8(2)
        ..writeUint8(3);
      writer.writeUint8At(0, 99);
      expect(writer.toBytes(), equals([99, 2, 3]));
    });

    test('overwrites byte at middle position', () {
      writer
        ..writeUint8(1)
        ..writeUint8(2)
        ..writeUint8(3);
      writer.writeUint8At(1, 99);
      expect(writer.toBytes(), equals([1, 99, 3]));
    });

    test('overwrites byte at last position', () {
      writer
        ..writeUint8(1)
        ..writeUint8(2)
        ..writeUint8(3);
      writer.writeUint8At(2, 99);
      expect(writer.toBytes(), equals([1, 2, 99]));
    });

    test('does not change bytesWritten', () {
      writer
        ..writeUint8(1)
        ..writeUint8(2);
      writer.writeUint8At(0, 99);
      expect(writer.bytesWritten, equals(2));
    });

    test('does not change current write position', () {
      writer
        ..writeUint8(1)
        ..writeUint8(2)
        ..writeUint8(3);
      writer.writeUint8At(1, 99);
      writer.writeUint8(4);
      expect(writer.toBytes(), equals([1, 99, 3, 4]));
    });

    test('throws RangeError for negative position', () {
      writer.writeUint8(1);
      expect(() => writer.writeUint8At(-1, 0), throwsA(isA<RangeError>()));
    });

    test('throws RangeError for position beyond bytesWritten', () {
      writer.writeUint8(1);
      expect(() => writer.writeUint8At(2, 0), throwsA(isA<RangeError>()));
    });

    test('throws RangeError for value exceeding 255', () {
      expect(() => writer.writeUint8At(0, 256), throwsA(isA<RangeError>()));
    });

    test('throws RangeError for negative value', () {
      expect(() => writer.writeUint8At(0, -1), throwsA(isA<RangeError>()));
    });

    test('works on empty writer at position 0', () {
      writer.writeUint8At(0, 42);
      expect(writer.bytesWritten, equals(1));
      expect(writer.toBytes(), equals([42]));
    });
  });

  group('BinaryWriter.seek + writeVarString integration', () {
    late BinaryWriter writer;

    setUp(() {
      writer = BinaryWriter();
    });

    test('writeVarString uses seek internally', () {
      writer.writeVarString('hello');
      final bytes = writer.takeBytes();
      final reader = BinaryReader(bytes);
      expect(reader.readVarString(), equals('hello'));
    });

    test('writeVarString with non-ASCII uses seek for VarInt rewrite', () {
      writer.writeVarString('Привет');
      final bytes = writer.takeBytes();
      final reader = BinaryReader(bytes);
      expect(reader.readVarString(), equals('Привет'));
    });

    test('writeVarString with emoji uses seek for VarInt rewrite', () {
      writer.writeVarString('🚀🌍');
      final bytes = writer.takeBytes();
      final reader = BinaryReader(bytes);
      expect(reader.readVarString(), equals('🚀🌍'));
    });
  });
}
