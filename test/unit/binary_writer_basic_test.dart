import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('BinaryWriter Basic Types', () {
    late BinaryWriter writer;

    setUp(() {
      writer = BinaryWriter();
    });

    test('initial state is correct', () {
      expect(writer.bytesWritten, equals(0));
      expect(writer.takeBytes(), isEmpty);
    });

    test('writes single Uint8 value to buffer', () {
      writer.writeUint8(1);
      expect(writer.takeBytes(), [1]);
    });

    test("writes negative Int8 value as two's complement", () {
      writer.writeInt8(-1);
      expect(writer.takeBytes(), [255]);
    });

    test('writes Uint16 in big-endian format', () {
      writer.writeUint16(256);
      expect(writer.takeBytes(), [1, 0]);
    });

    test('writes Uint16 in little-endian format', () {
      writer.writeUint16(256, .little);
      expect(writer.takeBytes(), [0, 1]);
    });

    test('writes Int16 in big-endian format', () {
      writer.writeInt16(-1);
      expect(writer.takeBytes(), [255, 255]);
    });

    test('writes Int16 in little-endian format', () {
      writer.writeInt16(-32768, .little);
      expect(writer.takeBytes(), [0, 128]);
    });

    test('writes Uint32 in big-endian format', () {
      writer.writeUint32(65536);
      expect(writer.takeBytes(), [0, 1, 0, 0]);
    });

    test('writes Uint32 in little-endian format', () {
      writer.writeUint32(65536, .little);
      expect(writer.takeBytes(), [0, 0, 1, 0]);
    });

    test('writes Int32 in big-endian format', () {
      writer.writeInt32(-1);
      expect(writer.takeBytes(), [255, 255, 255, 255]);
    });

    test('writes Int32 in little-endian format', () {
      writer.writeInt32(-2147483648, .little);
      expect(writer.takeBytes(), [0, 0, 0, 128]);
    });

    test('writes Uint64 in big-endian format', () {
      writer.writeUint64(4294967296);
      expect(writer.takeBytes(), [0, 0, 0, 1, 0, 0, 0, 0]);
    });

    test('writes Uint64 in little-endian format', () {
      writer.writeUint64(4294967296, .little);
      expect(writer.takeBytes(), [0, 0, 0, 0, 1, 0, 0, 0]);
    });

    test('writes Int64 in big-endian format', () {
      writer.writeInt64(-1);
      expect(writer.takeBytes(), [255, 255, 255, 255, 255, 255, 255, 255]);
    });

    test('writes Int64 in little-endian format', () {
      writer.writeInt64(-9223372036854775808, .little);
      expect(writer.takeBytes(), [0, 0, 0, 0, 0, 0, 0, 128]);
    });

    test('writes Float32 in big-endian format', () {
      writer.writeFloat32(3.1415927);
      expect(writer.takeBytes(), [64, 73, 15, 219]);
    });

    test('writes Float32 in little-endian format', () {
      writer.writeFloat32(3.1415927, .little);
      expect(writer.takeBytes(), [219, 15, 73, 64]);
    });

    test('writes Float64 in big-endian format', () {
      writer.writeFloat64(3.141592653589793);
      expect(writer.takeBytes(), [64, 9, 33, 251, 84, 68, 45, 24]);
    });

    test('writes Float64 in little-endian format', () {
      writer.writeFloat64(3.141592653589793, .little);
      expect(writer.takeBytes(), [24, 45, 68, 84, 251, 33, 9, 64]);
    });

    group('writeBool', () {
      test('writes true as 0x01', () {
        writer.writeBool(true);
        expect(writer.takeBytes(), equals([0x01]));
      });

      test('writes false as 0x00', () {
        writer.writeBool(false);
        expect(writer.takeBytes(), equals([0x00]));
      });

      test('writes multiple boolean values to buffer', () {
        writer
          ..writeBool(true)
          ..writeBool(false)
          ..writeBool(true)
          ..writeBool(true)
          ..writeBool(false);

        expect(writer.takeBytes(), equals([0x01, 0x00, 0x01, 0x01, 0x00]));
      });

      test('can be read back with readBool', () {
        writer
          ..writeBool(true)
          ..writeBool(false)
          ..writeBool(true);

        final bytes = writer.takeBytes();
        final reader = BinaryReader(bytes);

        expect(reader.readBool(), isTrue);
        expect(reader.readBool(), isFalse);
        expect(reader.readBool(), isTrue);
      });

      test('increments bytesWritten for each boolean write', () {
        expect(writer.bytesWritten, equals(0));

        writer.writeBool(true);
        expect(writer.bytesWritten, equals(1));

        writer.writeBool(false);
        expect(writer.bytesWritten, equals(2));

        writer.writeBool(true);
        expect(writer.bytesWritten, equals(3));
      });

      test('can be mixed with other write operations', () {
        writer
          ..writeUint8(42)
          ..writeBool(true)
          ..writeUint16(258)
          ..writeBool(false);

        expect(writer.takeBytes(), equals([42, 0x01, 0x01, 0x02, 0x00]));
      });
    });

    test('allow reusing writer after takeBytes', () {
      writer.writeUint8(1);
      expect(writer.takeBytes(), [1]);

      writer.writeUint8(2);
      expect(writer.takeBytes(), [2]);
    });

    test('tracks bytesWritten for mixed type writes', () {
      writer.writeUint8(1);
      expect(writer.bytesWritten, equals(1));

      writer.writeUint16(258);
      expect(writer.bytesWritten, equals(3));

      writer.writeBool(true);
      expect(writer.bytesWritten, equals(4));
    });
  });
}
