import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('BinaryWriter Edge Cases and Validation', () {
    late BinaryWriter writer;

    setUp(() {
      writer = BinaryWriter();
    });

    group('Input validation', () {
      test('throw RangeError when Uint8 value is negative', () {
        expect(() => writer.writeUint8(-1), throwsRangeError);
      });

      test('throw RangeError when Uint8 value exceeds 255', () {
        expect(() => writer.writeUint8(256), throwsRangeError);
      });

      test('throw RangeError when Int8 value is out of range', () {
        expect(() => writer.writeInt8(-129), throwsRangeError);
        expect(() => writer.writeInt8(128), throwsRangeError);
      });

      test('throw RangeError when Uint16 value is out of range', () {
        expect(() => writer.writeUint16(-1), throwsRangeError);
        expect(() => writer.writeUint16(65536), throwsRangeError);
      });

      test('throw RangeError when Uint32 value is out of range', () {
        expect(() => writer.writeUint32(-1), throwsRangeError);
        expect(() => writer.writeUint32(4294967296), throwsRangeError);
      });
    });

    group('Edge cases', () {
      test('writes empty string with zero bytes', () {
        writer.writeString('');
        expect(writer.bytesWritten, equals(0));
      });

      test('writes empty byte array with zero bytes', () {
        writer.writeBytes([]);
        expect(writer.bytesWritten, equals(0));
      });

      test('writes Float32 NaN and infinity values', () {
        writer
          ..writeFloat32(double.nan)
          ..writeFloat32(double.infinity)
          ..writeFloat32(double.negativeInfinity);

        final reader = BinaryReader(writer.takeBytes());
        expect(reader.readFloat32().isNaN, isTrue);
        expect(reader.readFloat32(), equals(double.infinity));
        expect(reader.readFloat32(), equals(double.negativeInfinity));
      });

      test('preserve negative zero in Float64', () {
        writer.writeFloat64(-0);
        final value = BinaryReader(writer.takeBytes()).readFloat64();
        expect(value, equals(0.0));
        expect(value.isNegative, isTrue);
      });
    });

    group('Boundary values', () {
      test('handle maximum values', () {
        writer
          ..writeUint8(255)
          ..writeInt8(127)
          ..writeInt8(-128)
          ..writeUint16(65535)
          ..writeInt32(2147483647);

        final reader = BinaryReader(writer.takeBytes());
        expect(reader.readUint8(), equals(255));
        expect(reader.readInt8(), equals(127));
        expect(reader.readInt8(), equals(-128));
        expect(reader.readUint16(), equals(65535));
        expect(reader.readInt32(), equals(2147483647));
      });
    });

    group('Concise API', () {
      test('call() is an alias for writeBytes', () {
        writer([10, 20, 30]);
        expect(writer.takeBytes(), equals([10, 20, 30]));
      });
    });
  });
}
