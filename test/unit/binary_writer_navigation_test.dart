import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('BinaryWriter Navigation', () {
    late BinaryWriter writer;

    setUp(() {
      writer = BinaryWriter();
    });

    group('seek', () {
      test('seeks to position 0', () {
        writer
          ..writeUint8(1)
          ..writeUint8(2)
          ..seek(0);
        expect(writer.bytesWritten, equals(0));
        expect(writer.toBytes(), isEmpty);
      });

      test('seeks to middle position and overwrites', () {
        writer
          ..writeUint8(1)
          ..writeUint8(2)
          ..writeUint8(3)
          ..seek(1)
          ..writeUint8(99);
        expect(writer.toBytes(), equals([1, 99]));
      });

      test('throws RangeError for position beyond bytesWritten', () {
        writer.writeUint8(1);
        expect(() => writer.seek(2), throwsRangeError);
      });
    });

    group('writeUint8At', () {
      test('overwrites byte at middle position', () {
        writer
          ..writeUint8(1)
          ..writeUint8(2)
          ..writeUint8(3)
          ..writeUint8At(1, 99);
        expect(writer.toBytes(), equals([1, 99, 3]));
      });

      test('does not change current write position', () {
        writer
          ..writeUint8(1)
          ..writeUint8(2)
          ..writeUint8At(0, 99)
          ..writeUint8(3);
        expect(writer.toBytes(), equals([99, 2, 3]));
      });
    });
  });
}
