import 'dart:typed_data';

import 'package:pro_binary/src/binary_writer.dart';
import 'package:test/test.dart';

void main() {
  group('BinaryWriterImpl', () {
    test('writeUint8 should write a single byte', () {
      final writer = BinaryWriter()..writeUint8(42);
      expect(writer.takeBytes(), equals([42]));
    });

    test('writeInt8 should write a single signed byte', () {
      final writer = BinaryWriter()..writeInt8(-42);
      expect(writer.takeBytes(), equals([214]));
    });

    test('writeUint16 should write a 16-bit unsigned integer', () {
      final writer = BinaryWriter()..writeUint16(65535);
      expect(writer.takeBytes(), equals([255, 255]));
    });

    test('writeInt16 should write a 16-bit signed integer', () {
      final writer = BinaryWriter()..writeInt16(-32768);
      expect(writer.takeBytes(), equals([128, 0]));
    });

    test('writeUint32 should write a 32-bit unsigned integer', () {
      final writer = BinaryWriter()..writeUint32(4294967295);
      expect(writer.takeBytes(), equals([255, 255, 255, 255]));
    });

    test('writeInt32 should write a 32-bit signed integer', () {
      final writer = BinaryWriter()..writeInt32(-2147483648);
      expect(writer.takeBytes(), equals([128, 0, 0, 0]));
    });

    test('writeUint64 should write a 64-bit unsigned integer', () {
      ///

      final writer = BinaryWriter()..writeUint64(9223372036854775807);
      expect(
        writer.takeBytes(),
        equals([127, 255, 255, 255, 255, 255, 255, 255]),
      );
    });

    test('writeInt64 should write a 64-bit signed integer', () {
      final writer = BinaryWriter()..writeInt64(-9223372036854775808);
      expect(writer.takeBytes(), equals([128, 0, 0, 0, 0, 0, 0, 0]));
    });

    test('writeFloat32 should write a 32-bit floating-point number', () {
      final writer = BinaryWriter()..writeFloat32(3.14);
      expect(writer.takeBytes(), equals([64, 72, 245, 195]));
    });

    test('writeFloat64 should write a 64-bit floating-point number', () {
      final writer = BinaryWriter()..writeFloat64(3.141592653589793);
      expect(writer.takeBytes(), equals([64, 9, 33, 251, 84, 68, 45, 24]));
    });

    test('writeBytes should write a list of bytes', () {
      final writer = BinaryWriter()..writeBytes([1, 2, 3, 4, 5]);
      expect(writer.takeBytes(), equals([1, 2, 3, 4, 5]));
    });

    test('writeBytes should write a very large list of bytes', () {
      final writer = BinaryWriter()..writeBytes(List.filled(10000, 0));
      expect(writer.takeBytes(), equals(List.filled(10000, 0)));
    });

    test('writeBytes should handle empty list of bytes', () {
      final writer = BinaryWriter()..writeBytes([]);
      expect(writer.takeBytes(), equals([]));
    });

    test('complex endian bing', () {
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
    test('complex endian little', () {
      final writer = BinaryWriter()
        ..writeUint8(42)
        ..writeInt8(-42)
        ..writeUint16(65535, Endian.little)
        ..writeInt16(-32768, Endian.little)
        ..writeUint32(4294967295, Endian.little)
        ..writeInt32(-2147483648, Endian.little)
        ..writeUint64(9223372036854775807, Endian.little)
        ..writeInt64(-9223372036854775808, Endian.little)
        ..writeFloat32(3.14, Endian.little)
        ..writeFloat64(3.141592653589793, Endian.little)
        ..writeBytes([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 100, 200, 255]);

      final bytes = writer.takeBytes();

      final expectedBytes = [
        42, // Uint8
        214, // Int8 (two's complement of -42 is 214)
        255, 255, // Uint16 (65535 in little endian)
        0, 128, // Int16 (-32768 in little endian)
        255, 255, 255, 255, // Uint32 (4294967295 in little endian)
        0, 0, 0, 128, // Int32 (-2147483648 in little endian)
        255, 255, 255, 255, 255, 255, 255,
        127, // Uint64 (9223372036854775807 in little endian)
        0, 0, 0, 0, 0, 0, 0,
        128, // Int64 (-9223372036854775808 in little endian)
        195, 245, 72, 64, // Float32 (3.14 in IEEE 754 format, little endian)
        24, 45, 68, 84, 251, 33, 9,
        64, // Float64 (3.141592653589793 in IEEE 754 format, little endian)
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 100, 200, 255, // Bytes
      ];

      expect(bytes, equals(expectedBytes));
    });
  });
}
