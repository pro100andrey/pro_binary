import 'dart:typed_data';

import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('BinaryWriter', () {
    late BinaryWriter writer;

    setUp(() {
      writer = BinaryWriter();
    });

    test('writeUint8', () {
      writer.writeUint8(1);
      expect(writer.takeBytes(), [1]);
    });

    test('writeInt8', () {
      writer.writeInt8(-1);
      expect(writer.takeBytes(), [255]);
    });

    test('writeUint16 big-endian', () {
      writer.writeUint16(256);
      expect(writer.takeBytes(), [1, 0]);
    });

    test('writeUint16 little-endian', () {
      writer.writeUint16(256, Endian.little);
      expect(writer.takeBytes(), [0, 1]);
    });

    test('writeInt16 big-endian', () {
      writer.writeInt16(-1);
      expect(writer.takeBytes(), [255, 255]);
    });

    test('writeInt16 little-endian', () {
      writer.writeInt16(-32768, Endian.little);
      expect(writer.takeBytes(), [0, 128]);
    });

    test('writeUint32 big-endian', () {
      writer.writeUint32(65536);
      expect(writer.takeBytes(), [0, 1, 0, 0]);
    });

    test('writeUint32 little-endian', () {
      writer.writeUint32(65536, Endian.little);
      expect(writer.takeBytes(), [0, 0, 1, 0]);
    });

    test('writeInt32 big-endian', () {
      writer.writeInt32(-1);
      expect(writer.takeBytes(), [255, 255, 255, 255]);
    });

    test('writeInt32 little-endian', () {
      writer.writeInt32(-2147483648, Endian.little);
      expect(writer.takeBytes(), [0, 0, 0, 128]);
    });

    test('writeUint64 big-endian', () {
      writer.writeUint64(4294967296);
      expect(writer.takeBytes(), [0, 0, 0, 1, 0, 0, 0, 0]);
    });

    test('writeUint64 little-endian', () {
      writer.writeUint64(4294967296, Endian.little);
      expect(writer.takeBytes(), [0, 0, 0, 0, 1, 0, 0, 0]);
    });

    test('writeInt64 big-endian', () {
      writer.writeInt64(-1);
      expect(writer.takeBytes(), [255, 255, 255, 255, 255, 255, 255, 255]);
    });

    test('writeInt64 little-endian', () {
      writer.writeInt64(-9223372036854775808, Endian.little);
      expect(writer.takeBytes(), [0, 0, 0, 0, 0, 0, 0, 128]);
    });

    test('writeFloat32 big-endian', () {
      writer.writeFloat32(3.1415927);
      expect(writer.takeBytes(), [64, 73, 15, 219]);
    });

    test('writeFloat32 little-endian', () {
      writer.writeFloat32(3.1415927, Endian.little);
      expect(writer.takeBytes(), [219, 15, 73, 64]);
    });

    test('writeFloat64 big-endian', () {
      writer.writeFloat64(3.141592653589793);
      expect(writer.takeBytes(), [64, 9, 33, 251, 84, 68, 45, 24]);
    });

    test('writeFloat64 little-endian', () {
      writer.writeFloat64(3.141592653589793, Endian.little);
      expect(writer.takeBytes(), [24, 45, 68, 84, 251, 33, 9, 64]);
    });

    test('writeBytes', () {
      writer.writeBytes([1, 2, 3, 4, 5]);
      expect(writer.takeBytes(), [1, 2, 3, 4, 5]);
    });

    test('writeString', () {
      writer.writeString('Hello, World!');
      expect(writer.takeBytes(), [
        72, 101, 108, 108, 111, 44, 32, 87, 111, 114, 108, 100, 33, // ASCII
      ]);
    });

    test('complex memory allocation test', () {
      final writer = BinaryWriter()
        ..writeUint8(42)
        ..writeInt8(-42)
        ..writeUint16(65535)
        ..writeInt16(-32768)
        ..writeUint32(4294967295)
        ..writeInt32(-2147483648)
        ..writeUint64(9223372036854775807)
        ..writeInt64(-9223372036854775808)
        ..writeFloat32(3.14)
        ..writeFloat64(3.141592653589793)
        ..writeBytes([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 100, 200, 255]);

      final bytes = writer.takeBytes();

      final expectedBytes = [
        42, // Uint8
        214, // Int8 (two's complement of -42 is 214)
        255, 255, // Uint16 (65535 in big endian)
        128, 0, // Int16 (-32768 in big endian)
        255, 255, 255, 255, // Uint32 (4294967295 in big endian)
        128, 0, 0, 0, // Int32 (-2147483648 in big endian)
        127, 255, 255, 255, 255, 255, 255,
        255, // Uint64 (9223372036854775807 in big endian)
        128, 0, 0, 0, 0, 0, 0, 0, // Int64 (-9223372036854775808 in big endian)
        64, 72, 245, 195, // Float32 (3.14 in IEEE 754 format, big endian)
        64, 9, 33, 251, 84, 68, 45,
        24, // Float64 (3.141592653589793 in IEEE 754 format, big endian)
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 100, 200, 255, // Bytes
      ];

      expect(bytes, equals(expectedBytes));
    });
  });
}
