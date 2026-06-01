import 'dart:typed_data';

import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('BinaryReader Get Random Access', () {
    late BinaryReader reader;

    setUp(() {
      // 32 bytes to support all tests including 64-bit reads
      final buffer = Uint8List.fromList(List.generate(32, (i) => i));
      reader = BinaryReader(buffer);
    });

    group('getUint8', () {
      test('reads byte at position', () {
        expect(reader.getUint8(0), equals(0x00));
        expect(reader.getUint8(5), equals(0x05));
        expect(reader.getUint8(31), equals(0x1F));
      });

      test('does not change offset', () {
        reader
          ..seek(5)
          ..getUint8(0);
        expect(reader.offset, equals(5));
      });

      test('throws for negative position', () {
        expect(() => reader.getUint8(-1), throwsRangeError);
      });

      test('throws for position at end', () {
        expect(() => reader.getUint8(32), throwsRangeError);
      });
    });

    group('getInt8', () {
      test('reads signed Int8 byte at position', () {
        final buffer = Uint8List.fromList([0x80, 0x7F, 0x00, 0xFF, 0x01]);
        final reader = BinaryReader(buffer);
        expect(reader.getInt8(0), equals(-128));
        expect(reader.getInt8(1), equals(127));
        expect(reader.getInt8(2), equals(0));
        expect(reader.getInt8(3), equals(-1));
        expect(reader.getInt8(4), equals(1));
      });

      test('does not change offset', () {
        reader
          ..seek(5)
          ..getInt8(0);
        expect(reader.offset, equals(5));
      });

      test('throws for negative position', () {
        expect(() => reader.getInt8(-1), throwsRangeError);
      });

      test('throws for position at end', () {
        expect(() => reader.getInt8(32), throwsRangeError);
      });

      test('signed round-trip', () {
        final buffer = Uint8List.fromList([0xFF, 0x80, 0x00, 0x7F]);
        final reader = BinaryReader(buffer);
        expect(reader.getInt8(0), equals(-1));
        expect(reader.getInt8(1), equals(-128));
        expect(reader.getInt8(2), equals(0));
        expect(reader.getInt8(3), equals(127));
      });
    });

    group('getInt16 / getUint16', () {
      test('getUint16 big-endian round-trip', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03, 0x04, 0x05, 0x06]);
        reader = BinaryReader(buffer);
        expect(reader.getUint16(0), equals(0x0102));
        expect(reader.getUint16(2), equals(0x0304));
        expect(reader.getUint16(4), equals(0x0506));
      });

      test('getUint16 little-endian round-trip', () {
        final buffer = Uint8List.fromList([0x01, 0x02, 0x03, 0x04]);
        reader = BinaryReader(buffer);
        expect(reader.getUint16(0, Endian.little), equals(0x0201));
        expect(reader.getUint16(2, Endian.little), equals(0x0403));
      });

      test('getInt16 big-endian round-trip', () {
        final buffer = Uint8List.fromList([
          0xFF, 0xFF, // -1
          0x7F, 0xFF, // 32767
          0x80, 0x00, // -32768
        ]);
        reader = BinaryReader(buffer);
        expect(reader.getInt16(0), equals(-1));
        expect(reader.getInt16(2), equals(32767));
        expect(reader.getInt16(4), equals(-32768));
      });

      test('getUint16 does not change offset', () {
        reader
          ..seek(5)
          ..getUint16(0);
        expect(reader.offset, equals(5));
      });

      test('throws for position out of bounds', () {
        // 32-byte buffer: getUint16(31) needs bytes 31-32, but 32 is out of
        // bounds
        expect(() => reader.getUint16(31), throwsRangeError);
      });

      test('throws for negative position', () {
        expect(() => reader.getUint16(-1), throwsRangeError);
      });
    });

    group('getInt32 / getUint32', () {
      test('getUint32 big-endian round-trip', () {
        final buffer = Uint8List.fromList([
          0x00, 0x00, 0x00, 0x01, // 1
          0x00, 0x01, 0x00, 0x00, // 65536
          0x01, 0x00, 0x00, 0x00, // 16777216
        ]);
        reader = BinaryReader(buffer);
        expect(reader.getUint32(0), equals(1));
        expect(reader.getUint32(4), equals(65536));
        expect(reader.getUint32(8), equals(16777216));
      });

      test('getUint32 little-endian round-trip', () {
        final buffer = Uint8List.fromList([0x01, 0x00, 0x00, 0x00]);
        reader = BinaryReader(buffer);
        expect(reader.getUint32(0, Endian.little), equals(1));
      });

      test('getInt32 big-endian round-trip', () {
        final buffer = Uint8List.fromList([
          0x00, 0x00, 0x01, 0x00, // 256
          0x7F, 0xFF, 0xFF, 0xFF, // max int32
          0xFF, 0xFF, 0xFF, 0xFF, // -1
        ]);
        reader = BinaryReader(buffer);
        expect(reader.getInt32(0), equals(256));
        expect(reader.getInt32(4), equals(2147483647));
        expect(reader.getInt32(8), equals(-1));
      });

      test('getInt32 little-endian round-trip', () {
        final buffer = Uint8List.fromList([
          0x00, 0x00, 0x01, 0x00, // 65536 in little-endian
        ]);
        reader = BinaryReader(buffer);
        expect(reader.getInt32(0, Endian.little), equals(65536));
      });

      test('getUint32 does not change offset', () {
        reader
          ..seek(10)
          ..getUint32(0);
        expect(reader.offset, equals(10));
      });

      test('throws for position out of bounds', () {
        // 32-byte buffer: getUint32(29) needs bytes 29-32, but 32 is out of
        // bounds
        expect(() => reader.getUint32(29), throwsRangeError);
      });

      test('throws for negative position', () {
        expect(() => reader.getUint32(-1), throwsRangeError);
      });
    });

    group('getInt64 / getUint64', () {
      test('getUint64 big-endian round-trip', () {
        final buffer = Uint8List.fromList([
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x01,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x01,
          0x00,
          0x00,
        ]);
        reader = BinaryReader(buffer);
        expect(reader.getUint64(0), equals(1));
        expect(reader.getUint64(8), equals(65536));
      });

      test('getUint64 little-endian round-trip', () {
        final buffer = Uint8List.fromList([
          0x01,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
        ]);
        reader = BinaryReader(buffer);
        expect(reader.getUint64(0, Endian.little), equals(1));
      });

      test('getInt64 big-endian round-trip', () {
        final buffer = Uint8List.fromList([
          0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x00, // 256
          0x7F, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, // max int64
          0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, // -1
        ]);
        reader = BinaryReader(buffer);
        expect(reader.getInt64(0), equals(256));
        expect(reader.getInt64(8), equals(9223372036854775807));
        expect(reader.getInt64(16), equals(-1));
      });

      test('getInt64 little-endian round-trip', () {
        final buffer = Uint8List.fromList([
          // 65536 in little-endian
          0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00,
        ]);
        reader = BinaryReader(buffer);
        expect(reader.getInt64(0, Endian.little), equals(65536));
      });

      test('getUint64 does not change offset', () {
        reader
          ..seek(10)
          ..getUint64(0);
        expect(reader.offset, equals(10));
      });

      test('throws for position out of bounds', () {
        // 32-byte buffer: getUint64(25) needs bytes 25-32, but 32 is out of
        // bounds
        expect(() => reader.getUint64(25), throwsRangeError);
      });

      test('throws for negative position', () {
        expect(() => reader.getUint64(-1), throwsRangeError);
      });
    });

    group('getFloat32 / getFloat64', () {
      test('getFloat32 big-endian round-trip', () {
        final buffer = Uint8List.fromList([
          0x40, 0x48, 0x00, 0x00, // 3.125
          0xC0, 0x00, 0x00, 0x00, // -2.0
          0x00, 0x00, 0x00, 0x00, // 0.0
        ]);
        reader = BinaryReader(buffer);
        expect(reader.getFloat32(0), closeTo(3.125, 0.001));
        expect(reader.getFloat32(4), closeTo(-2.0, 0.001));
        expect(reader.getFloat32(8), equals(0.0));
      });

      test('getFloat32 little-endian round-trip', () {
        final buffer = Uint8List.fromList([
          0x00, 0x00, 0x48, 0x40, // 3.125 in little-endian
        ]);
        reader = BinaryReader(buffer);
        expect(reader.getFloat32(0, Endian.little), closeTo(3.125, 0.001));
      });

      test('getFloat64 big-endian round-trip', () {
        final buffer = Uint8List.fromList([
          0x40, 0x09, 0x21, 0xF9, 0xF0, 0x1B, 0x86, 0x6E, // 3.14159
          0xC0, 0x09, 0x21, 0xF9, 0xF0, 0x1B, 0x86, 0x6E, // -3.14159
        ]);
        reader = BinaryReader(buffer);
        expect(reader.getFloat64(0), closeTo(3.14159, 0.00001));
        expect(reader.getFloat64(8), closeTo(-3.14159, 0.00001));
      });

      test('getFloat64 little-endian round-trip', () {
        final buffer = Uint8List.fromList([
          0x6E,
          0x86,
          0x1B,
          0xF0,
          0xF9,
          0x21,
          0x09,
          0x40, // 3.14159 little-endian
        ]);
        reader = BinaryReader(buffer);
        expect(reader.getFloat64(0, Endian.little), closeTo(3.14159, 0.00001));
      });

      test('getFloat32 does not change offset', () {
        reader
          ..seek(10)
          ..getFloat32(0);
        expect(reader.offset, equals(10));
      });

      test('getFloat64 does not change offset', () {
        reader
          ..seek(10)
          ..getFloat64(0);
        expect(reader.offset, equals(10));
      });

      test('throws for position out of bounds', () {
        // 32-byte buffer
        expect(() => reader.getFloat32(29), throwsRangeError);
        expect(() => reader.getFloat64(25), throwsRangeError);
      });

      test('throws for negative position', () {
        expect(() => reader.getFloat32(-1), throwsRangeError);
        expect(() => reader.getFloat64(-1), throwsRangeError);
      });
    });

    group('use case: parsing header fields', () {
      test('read fixed-size header without consuming', () {
        // Simulate a packet: [version(1), type(1), length(4), payload...]
        final buffer = Uint8List.fromList([
          0x02, // version 2
          0x05, // type = 5
          0x00, 0x00, 0x00, 0x0A, // length = 10
          0x48, 0x65, 0x6C, 0x6C, 0x6F, // "Hello"
          0x20, 0x57, 0x6F, 0x72, 0x6C, // " Worl"
          0x64, 0x21, // "d!"
        ]);
        reader = BinaryReader(buffer);

        final version = reader.getUint8(0);
        final type = reader.getUint8(1);
        final length = reader.getUint32(2);

        expect(version, equals(2));
        expect(type, equals(5));
        expect(length, equals(10));
        expect(reader.offset, equals(0));
      });

      test('read mixed-endian header', () {
        // Network byte order (big-endian) for most fields
        final buffer = Uint8List.fromList([
          0x00, 0x01, // sequence number (big-endian)
          0x00, 0x00, 0x00, 0x64, // length (big-endian)
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x00,
          0x01,
          0x00, // timestamp (big-endian)
        ]);
        reader = BinaryReader(buffer);

        expect(reader.getUint16(0), equals(1));
        expect(reader.getUint32(2), equals(100));
        expect(reader.getUint64(6), equals(256));
      });

      test('read floating-point metadata', () {
        final buffer = Uint8List.fromList([
          0x40, 0x09, 0x21, 0xF9, 0xF0, 0x1B, 0x86, 0x6E, // lat: 3.14159
          0xC0, 0x09, 0x21, 0xF9, 0xF0, 0x1B, 0x86, 0x6E, // lon: -3.14159
          0x41, 0x20, 0x00, 0x00, // altitude: 10.0
        ]);
        reader = BinaryReader(buffer);

        expect(reader.getFloat64(0), closeTo(3.14159, 0.00001));
        expect(reader.getFloat64(8), closeTo(-3.14159, 0.00001));
        expect(reader.getFloat32(16), closeTo(10.0, 0.001));
      });
    });

    group('edge cases', () {
      test('read from empty buffer', () {
        final emptyBuffer = Uint8List(0);
        final emptyReader = BinaryReader(emptyBuffer);
        expect(() => emptyReader.getUint8(0), throwsRangeError);
      });

      test('read from single byte buffer', () {
        final buffer = Uint8List.fromList([0x42]);
        final reader = BinaryReader(buffer);
        expect(reader.getUint8(0), equals(0x42));
        expect(() => reader.getUint16(0), throwsRangeError);
      });

      test('multiple reads at same position', () {
        final buffer = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);
        reader = BinaryReader(buffer);
        expect(reader.getUint16(0), equals(0x0001));
        expect(reader.getUint16(0), equals(0x0001));
        expect(reader.getUint16(0), equals(0x0001));
      });

      test('interleaved reads at different positions', () {
        final buffer = Uint8List.fromList([
          0x00,
          0x01,
          0x02,
          0x03,
          0x04,
          0x05,
          0x06,
          0x07,
        ]);
        reader = BinaryReader(buffer);
        expect(reader.getUint16(0), equals(0x0001));
        expect(reader.getUint32(2), equals(0x02030405));
        expect(reader.getUint16(6), equals(0x0607));
        expect(reader.getUint16(0), equals(0x0001));
      });

      test('works after partial read', () {
        final buffer = Uint8List.fromList([
          0x00,
          0x01,
          0x02,
          0x03,
          0x04,
          0x05,
          0x06,
          0x07,
        ]);
        reader = BinaryReader(buffer)
          ..readUint16(); // reads 2 bytes, offset = 2
        expect(reader.getUint32(0), equals(0x00010203));
        expect(reader.getUint32(4), equals(0x04050607));
        expect(reader.offset, equals(2));
      });
    });
  });
}
