import 'dart:typed_data';

import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('BinaryWriter', () {
    late BinaryWriter writer;

    setUp(() {
      writer = BinaryWriter();
    });

    test('takeBytes for empty', () {
      expect(writer.takeBytes(), isEmpty);
    });

    test('writeUint8', () {
      writer.writeUint8(1);
      expect(writer.takeBytes(), [1]);
    });

    test('writeInt8 negative value', () {
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

    test('buffer should expand when size exceeds initial allocation', () {
      for (var i = 0; i < 100; i++) {
        writer.writeUint8(i);
      }

      final result = writer.takeBytes();
      expect(result.length, equals(100));
      for (var i = 0; i < 100; i++) {
        expect(result[i], equals(i));
      }
    });

    test('reuse writer after takeBytes', () {
      writer.writeUint8(1);
      expect(writer.takeBytes(), [1]);

      writer.writeUint8(2);
      expect(writer.takeBytes(), [2]);
    });

    test('write large data set', () {
      final largeData = Uint8List.fromList(
        List.generate(10000, (i) => i % 256),
      );

      writer.writeBytes(largeData);

      final result = writer.takeBytes();

      expect(result.length, equals(10000));
      expect(result, equals(largeData));
    });

    test('bytesWritten returns correct number of bytes', () {
      writer.writeUint8(1);
      expect(writer.bytesWritten, equals(1));

      writer.writeUint16(258);
      expect(writer.bytesWritten, equals(3));

      writer.writeBytes([1, 2, 3, 4]);
      expect(writer.bytesWritten, equals(7));

      // Test with a large amount of data written
      final largeData = Uint8List.fromList(
        List.generate(10000, (i) => i % 256),
      );
      writer.writeBytes(largeData);
      expect(writer.bytesWritten, equals(10007));
    });

    group('Range validation', () {
      test('writeUint8 throws when value is negative', () {
        expect(() => writer.writeUint8(-1), throwsRangeError);
      });

      test('writeUint8 throws when value exceeds 255', () {
        expect(() => writer.writeUint8(256), throwsRangeError);
      });

      test('writeInt8 throws when value is less than -128', () {
        expect(() => writer.writeInt8(-129), throwsRangeError);
      });

      test('writeInt8 throws when value exceeds 127', () {
        expect(() => writer.writeInt8(128), throwsRangeError);
      });

      test('writeUint16 throws when value is negative', () {
        expect(() => writer.writeUint16(-1), throwsRangeError);
      });

      test('writeUint16 throws when value exceeds 65535', () {
        expect(() => writer.writeUint16(65536), throwsRangeError);
      });

      test('writeInt16 throws when value is less than -32768', () {
        expect(() => writer.writeInt16(-32769), throwsRangeError);
      });

      test('writeInt16 throws when value exceeds 32767', () {
        expect(() => writer.writeInt16(32768), throwsRangeError);
      });

      test('writeUint32 throws when value is negative', () {
        expect(() => writer.writeUint32(-1), throwsRangeError);
      });

      test('writeUint32 throws when value exceeds 4294967295', () {
        expect(() => writer.writeUint32(4294967296), throwsRangeError);
      });

      test('writeInt32 throws when value is less than -2147483648', () {
        expect(() => writer.writeInt32(-2147483649), throwsRangeError);
      });

      test('writeInt32 throws when value exceeds 2147483647', () {
        expect(() => writer.writeInt32(2147483648), throwsRangeError);
      });
    });

    group('toBytes method', () {
      test('toBytes returns current buffer without resetting', () {
        writer
          ..writeUint8(42)
          ..writeUint8(100);

        final bytes1 = writer.toBytes();
        expect(bytes1, equals([42, 100]));

        // Should not reset, can continue writing
        writer.writeUint8(200);
        final bytes2 = writer.toBytes();
        expect(bytes2, equals([42, 100, 200]));
      });

      test('toBytes vs takeBytes behavior', () {
        writer
          ..writeUint8(1)
          ..writeUint8(2);

        final bytes1 = writer.toBytes();
        expect(bytes1, equals([1, 2]));

        // takeBytes should reset
        final bytes2 = writer.takeBytes();
        expect(bytes2, equals([1, 2]));

        // After takeBytes, should be empty
        final bytes3 = writer.toBytes();
        expect(bytes3, isEmpty);
      });

      test('toBytes on empty writer returns empty list', () {
        final bytes = writer.toBytes();
        expect(bytes, isEmpty);
      });
    });

    group('clear method', () {
      test('clear resets writer without returning bytes', () {
        writer
          ..writeUint8(42)
          ..writeUint8(100)
          ..clear();

        expect(writer.bytesWritten, equals(0));
        expect(writer.toBytes(), isEmpty);
      });

      test('clear allows writing new data after reset', () {
        writer
          ..writeUint8(42)
          ..clear()
          ..writeUint8(100);

        expect(writer.toBytes(), equals([100]));
      });

      test('clear on empty writer does nothing', () {
        writer.clear();
        expect(writer.bytesWritten, equals(0));
      });
    });
  });
}
