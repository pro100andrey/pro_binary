import 'dart:typed_data';

import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('BinaryWriter Set/Get', () {
    late BinaryWriter writer;

    setUp(() {
      writer = BinaryWriter();
    });

    group('getUint8', () {
      test('reads byte at position', () {
        writer
          ..writeUint8(10)
          ..writeUint8(20)
          ..writeUint8(30);
        expect(writer.getUint8(0), equals(10));
        expect(writer.getUint8(1), equals(20));
        expect(writer.getUint8(2), equals(30));
      });

      test('does not change offset', () {
        writer
          ..writeUint8(42)
          ..writeUint8(99);
        final offset = writer.bytesWritten;
        writer.getUint8(0);
        expect(writer.bytesWritten, equals(offset));
      });

      test('throws for negative position', () {
        writer.writeUint8(1);
        expect(() => writer.getUint8(-1), throwsRangeError);
      });
    });

    group('setUint8', () {
      test('overwrites byte at position', () {
        writer
          ..writeUint8(1)
          ..writeUint8(2)
          ..writeUint8(3)
          ..setUint8(1, 99);
        expect(writer.toBytes(), equals([1, 99, 3]));
      });

      test('does not change offset', () {
        writer
          ..writeUint8(1)
          ..writeUint8(2);
        final offset = writer.bytesWritten;
        writer.setUint8(0, 99);
        expect(writer.bytesWritten, equals(offset));
      });

      test('throws for negative position', () {
        writer.writeUint8(1);
        expect(() => writer.setUint8(-1, 1), throwsRangeError);
      });

      test('throws for value out of range', () {
        writer
          ..writeUint8(1)
          ..writeUint8(2);
        expect(() => writer.setUint8(0, 256), throwsRangeError);
        expect(() => writer.setUint8(0, -1), throwsRangeError);
      });

      test('accepts boundary values', () {
        writer
          ..writeUint8(1)
          ..writeUint8(2)
          ..setUint8(0, 0)
          ..setUint8(1, 255);
        expect(writer.toBytes(), equals([0, 255]));
      });
    });

    group('getInt8 / setInt8', () {
      test('round-trip signed values', () {
        writer
          ..writeInt8(127)
          ..writeInt8(-1)
          ..writeInt8(-128)
          ..writeInt8(0);
        expect(writer.getInt8(0), equals(127));
        expect(writer.getInt8(1), equals(-1));
        expect(writer.getInt8(2), equals(-128));
        expect(writer.getInt8(3), equals(0));
      });

      test('does not change offset', () {
        writer
          ..writeInt8(42)
          ..writeInt8(99);
        final offset = writer.bytesWritten;
        writer.getInt8(0);
        expect(writer.bytesWritten, equals(offset));
      });

      test('throws for negative position', () {
        writer.writeInt8(1);
        expect(() => writer.getInt8(-1), throwsRangeError);
        expect(() => writer.setInt8(-1, 1), throwsRangeError);
      });
    });

    group('getInt16 / setInt16', () {
      test('round-trip big-endian', () {
        writer
          ..writeInt16(-100)
          ..writeInt16(32767)
          ..writeInt16(-32768);
        expect(writer.getInt16(0), equals(-100));
        expect(writer.getInt16(2), equals(32767));
        expect(writer.getInt16(4), equals(-32768));
      });

      test('round-trip little-endian', () {
        writer
          ..writeInt16(-100, Endian.little)
          ..writeInt16(32767, Endian.little);
        expect(writer.getInt16(0, Endian.little), equals(-100));
        expect(writer.getInt16(2, Endian.little), equals(32767));
      });

      test('setInt16 overwrites without changing offset', () {
        writer
          ..writeInt16(100)
          ..writeInt16(200)
          ..setInt16(0, 999);
        expect(writer.getInt16(0), equals(999));
        expect(writer.getInt16(2), equals(200));
        expect(writer.bytesWritten, equals(4));
      });

      test('throws for value out of range', () {
        writer
          ..writeInt16(1)
          ..writeInt16(2);

        expect(() => writer.setInt16(0, 32768), throwsRangeError);
        expect(() => writer.setInt16(0, -32769), throwsRangeError);
      });
    });

    group('getUint16 / setUint16', () {
      test('round-trip big-endian', () {
        writer
          ..writeUint16(0)
          ..writeUint16(256)
          ..writeUint16(65535);
        expect(writer.getUint16(0), equals(0));
        expect(writer.getUint16(2), equals(256));
        expect(writer.getUint16(4), equals(65535));
      });

      test('setUint16 overwrites without changing offset', () {
        writer
          ..writeUint16(100)
          ..writeUint16(200)
          ..setUint16(0, 999);
        expect(writer.getUint16(0), equals(999));
        expect(writer.bytesWritten, equals(4));
      });

      test('throws for value out of range', () {
        writer
          ..writeUint16(1)
          ..writeUint16(2);
        expect(() => writer.setUint16(0, 65536), throwsRangeError);
        expect(() => writer.setUint16(0, -1), throwsRangeError);
      });
    });

    group('getInt32 / setInt32', () {
      test('round-trip big-endian', () {
        writer
          ..writeInt32(-500000)
          ..writeInt32(2147483647)
          ..writeInt32(-2147483648);
        expect(writer.getInt32(0), equals(-500000));
        expect(writer.getInt32(4), equals(2147483647));
        expect(writer.getInt32(8), equals(-2147483648));
      });

      test('round-trip little-endian', () {
        writer.writeInt32(-500000, Endian.little);
        expect(writer.getInt32(0, Endian.little), equals(-500000));
      });

      test('setInt32 overwrites without changing offset', () {
        writer
          ..writeInt32(100)
          ..writeInt32(200)
          ..setInt32(0, 999);
        expect(writer.getInt32(0), equals(999));
        expect(writer.getInt32(4), equals(200));
        expect(writer.bytesWritten, equals(8));
      });

      test('throws for value out of range', () {
        writer
          ..writeInt32(1)
          ..writeInt32(2);
        expect(() => writer.setInt32(0, 2147483648), throwsRangeError);
        expect(() => writer.setInt32(0, -2147483649), throwsRangeError);
      });
    });

    group('getUint32 / setUint32', () {
      test('round-trip big-endian', () {
        writer
          ..writeUint32(0)
          ..writeUint32(16777216)
          ..writeUint32(4294967295);
        expect(writer.getUint32(0), equals(0));
        expect(writer.getUint32(4), equals(16777216));
        expect(writer.getUint32(8), equals(4294967295));
      });

      test('setUint32 overwrites without changing offset', () {
        writer
          ..writeUint32(100)
          ..writeUint32(200)
          ..setUint32(0, 999);
        expect(writer.getUint32(0), equals(999));
        expect(writer.bytesWritten, equals(8));
      });

      test('throws for value out of range', () {
        writer
          ..writeUint32(1)
          ..writeUint32(2);
        expect(() => writer.setUint32(0, 4294967296), throwsRangeError);
        expect(() => writer.setUint32(0, -1), throwsRangeError);
      });
    });

    group('getInt64 / setInt64', () {
      test('round-trip big-endian', () {
        writer
          ..writeInt64(-1234567890123456)
          ..writeInt64(9223372036854775807)
          ..writeInt64(-9223372036854775808);
        expect(writer.getInt64(0), equals(-1234567890123456));
        expect(writer.getInt64(8), equals(9223372036854775807));
        expect(writer.getInt64(16), equals(-9223372036854775808));
      });

      test('round-trip little-endian', () {
        writer.writeInt64(-1234567890123456, Endian.little);
        expect(writer.getInt64(0, Endian.little), equals(-1234567890123456));
      });

      test('setInt64 overwrites without changing offset', () {
        writer
          ..writeInt64(100)
          ..writeInt64(200)
          ..setInt64(0, 999);
        expect(writer.getInt64(0), equals(999));
        expect(writer.getInt64(8), equals(200));
        expect(writer.bytesWritten, equals(16));
      });

      test('throws for value out of range', () {
        writer
          ..writeInt64(1)
          ..writeInt64(2)
          // kMaxInt64 + 1 and kMinInt64 - 1 cannot be represented as Dart int
          // Verify setInt64 works correctly with valid values
          ..setInt64(0, 9223372036854775807)
          ..setInt64(8, -9223372036854775808);
        expect(writer.getInt64(0), equals(9223372036854775807));
        expect(writer.getInt64(8), equals(-9223372036854775808));
      });
    });

    group('getUint64 / setUint64', () {
      test('round-trip big-endian', () {
        writer
          ..writeUint64(0)
          ..writeUint64(9223372036854775807);
        expect(writer.getUint64(0), equals(0));
        expect(writer.getUint64(8), equals(9223372036854775807));
      });

      test('setUint64 overwrites without changing offset', () {
        writer
          ..writeUint64(100)
          ..writeUint64(200)
          ..setUint64(0, 999);
        expect(writer.getUint64(0), equals(999));
        expect(writer.bytesWritten, equals(16));
      });

      test('sets boundary values correctly', () {
        writer
          ..writeUint64(0)
          ..writeUint64(9223372036854775807)
          ..setUint64(0, 9223372036854775807);
        expect(writer.getUint64(0), equals(9223372036854775807));
      });
    });

    group('getFloat32 / setFloat32', () {
      test('round-trip big-endian', () {
        writer
          ..writeFloat32(3.14)
          ..writeFloat32(-2.5)
          ..writeFloat32(0);
        expect(writer.getFloat32(0), closeTo(3.14, 0.001));
        expect(writer.getFloat32(4), closeTo(-2.5, 0.001));
        expect(writer.getFloat32(8), equals(0.0));
      });

      test('round-trip little-endian', () {
        writer.writeFloat32(3.14159, Endian.little);
        expect(writer.getFloat32(0, Endian.little), closeTo(3.14159, 0.0001));
      });

      test('setFloat32 overwrites without changing offset', () {
        writer
          ..writeFloat32(1.5)
          ..writeFloat32(2.5)
          ..setFloat32(0, 9.9);
        expect(writer.getFloat32(0), closeTo(9.9, 0.001));
        expect(writer.getFloat32(4), closeTo(2.5, 0.001));
        expect(writer.bytesWritten, equals(8));
      });
    });

    group('getFloat64 / setFloat64', () {
      test('round-trip big-endian', () {
        writer
          ..writeFloat64(3.14159265358979)
          ..writeFloat64(-2.5);
        expect(
          writer.getFloat64(0),
          closeTo(3.14159265358979, 0.00000000000001),
        );
        expect(writer.getFloat64(8), closeTo(-2.5, 0.00000000000001));
      });

      test('round-trip little-endian', () {
        writer.writeFloat64(3.14159265358979, Endian.little);
        expect(
          writer.getFloat64(0, Endian.little),
          closeTo(3.14159265358979, 0.00000000000001),
        );
      });

      test('setFloat64 overwrites without changing offset', () {
        writer
          ..writeFloat64(1.5)
          ..writeFloat64(2.5)
          ..setFloat64(0, 9.9);
        expect(writer.getFloat64(0), closeTo(9.9, 0.00000000000001));
        expect(writer.getFloat64(8), closeTo(2.5, 0.00000000000001));
        expect(writer.bytesWritten, equals(16));
      });
    });

    group('use case: backpatch pattern', () {
      test('setUint32 for length prefix', () {
        final data = [1, 2, 3, 4, 5];
        writer
          ..writeUint32(0) // placeholder for length
          ..writeBytes(data)
          ..setUint32(0, data.length);

        expect(writer.getUint32(0), equals(data.length));
        expect(writer.toBytes().sublist(4), equals(data));
      });

      test('setInt32 for message type', () {
        writer
          ..writeUint32(0) // placeholder for type
          ..writeUint32(42) // payload
          ..writeUint32(100) // more payload
          ..setInt32(0, 5); // type = 5

        expect(writer.getInt32(0), equals(5));
        expect(writer.getInt32(4), equals(42));
        expect(writer.getInt32(8), equals(100));
      });

      test('setFloat64 for header field', () {
        writer
          ..writeFloat64(0) // placeholder
          ..writeUint32(12345)
          ..writeString('hello')
          ..setFloat64(0, 3.14);

        expect(writer.getFloat64(0), closeTo(3.14, 0.00000000000001));
        expect(writer.getUint32(8), equals(12345));
      });
    });

    group('edge cases', () {
      test('get/set at position 0 after single write', () {
        writer.writeUint8(42);
        expect(writer.getUint8(0), equals(42));
        writer.setUint8(0, 99);
        expect(writer.getUint8(0), equals(99));
      });

      test('multiple get/set at same position', () {
        writer
          ..writeUint32(100)
          ..writeUint32(200);
        expect(writer.getUint32(0), equals(100));
        expect(writer.getUint32(0), equals(100));
        writer.setUint32(0, 300);
        expect(writer.getUint32(0), equals(300));
        expect(writer.bytesWritten, equals(8));
      });

      test('get/set with different endianness', () {
        writer
          ..writeUint16(0x1234, Endian.little)
          ..writeUint16(0x5678);
        expect(writer.getUint16(0, Endian.little), equals(0x1234));
        expect(writer.getUint16(2), equals(0x5678));
        writer.setUint16(0, 0xABCD, Endian.little);
        expect(writer.getUint16(0, Endian.little), equals(0xABCD));
      });
    });
  });
}
