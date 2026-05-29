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
        expect(writer.bytesWritten, equals(3));
      });

      test('does not change current write position', () {
        writer
          ..writeUint8(1)
          ..writeUint8(2)
          ..writeUint8At(0, 99)
          ..writeUint8(3);

        expect(writer.toBytes(), equals([99, 2, 3]));
        expect(writer.bytesWritten, equals(3));
      });

      test('throws for position at the end', () {
        writer.writeUint8(1);
        expect(() => writer.writeUint8At(1, 99), throwsRangeError);
      });
    });

    group('index operators', () {
      test('operator [] returns byte at absolute position', () {
        writer
          ..writeUint8(10)
          ..writeUint8(20)
          ..writeUint8(30);

        expect(writer[0], equals(10));
        expect(writer[1], equals(20));
        expect(writer[2], equals(30));
      });

      test('operator [] throws for invalid indices', () {
        writer.writeUint8(10);
        expect(() => writer[-1], throwsRangeError);
        expect(() => writer[1], throwsRangeError);
      });

      test('operator []= overwrites existing byte', () {
        writer
          ..writeUint8(1)
          ..writeUint8(2)
          ..writeUint8(3);

        final initialOffset = writer.bytesWritten;
        writer[1] = 99;
        expect(writer.toBytes(), equals([1, 99, 3]));
        expect(writer[1], equals(99));
        expect(writer.bytesWritten, equals(initialOffset));
      });

      test('operator []= throws even when writing at the end', () {
        writer.writeUint8(1); // [1], offset 1
        expect(() => writer[1] = 2, throwsRangeError);
      });

      test('operator []= throws for invalid indices', () {
        writer.writeUint8(10);
        expect(() => writer[-1] = 20, throwsRangeError);
        expect(() => writer[2] = 20, throwsRangeError);
      });
    });
  });
}
