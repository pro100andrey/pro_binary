import 'dart:typed_data';

import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('BinaryWriter', () {
    late BinaryWriter writer;

    setUp(() {
      writer = BinaryWriter();
    });

    test('should return empty list when takeBytes called on empty writer', () {
      expect(writer.takeBytes(), isEmpty);
    });

    test('should write single Uint8 value correctly', () {
      writer.writeUint8(1);
      expect(writer.takeBytes(), [1]);
    });

    test('should write negative Int8 value correctly', () {
      writer.writeInt8(-1);
      expect(writer.takeBytes(), [255]);
    });

    test('should write Uint16 in big-endian format', () {
      writer.writeUint16(256);
      expect(writer.takeBytes(), [1, 0]);
    });

    test('should write Uint16 in little-endian format', () {
      writer.writeUint16(256, Endian.little);
      expect(writer.takeBytes(), [0, 1]);
    });

    test('should write Int16 in big-endian format', () {
      writer.writeInt16(-1);
      expect(writer.takeBytes(), [255, 255]);
    });

    test('should write Int16 in little-endian format', () {
      writer.writeInt16(-32768, Endian.little);
      expect(writer.takeBytes(), [0, 128]);
    });

    test('should write Uint32 in big-endian format', () {
      writer.writeUint32(65536);
      expect(writer.takeBytes(), [0, 1, 0, 0]);
    });

    test('should write Uint32 in little-endian format', () {
      writer.writeUint32(65536, Endian.little);
      expect(writer.takeBytes(), [0, 0, 1, 0]);
    });

    test('should write Int32 in big-endian format', () {
      writer.writeInt32(-1);
      expect(writer.takeBytes(), [255, 255, 255, 255]);
    });

    test('should write Int32 in little-endian format', () {
      writer.writeInt32(-2147483648, Endian.little);
      expect(writer.takeBytes(), [0, 0, 0, 128]);
    });

    test('should write Uint64 in big-endian format', () {
      writer.writeUint64(4294967296);
      expect(writer.takeBytes(), [0, 0, 0, 1, 0, 0, 0, 0]);
    });

    test('should write Uint64 in little-endian format', () {
      writer.writeUint64(4294967296, Endian.little);
      expect(writer.takeBytes(), [0, 0, 0, 0, 1, 0, 0, 0]);
    });

    test('should write Int64 in big-endian format', () {
      writer.writeInt64(-1);
      expect(writer.takeBytes(), [255, 255, 255, 255, 255, 255, 255, 255]);
    });

    test('should write Int64 in little-endian format', () {
      writer.writeInt64(-9223372036854775808, Endian.little);
      expect(writer.takeBytes(), [0, 0, 0, 0, 0, 0, 0, 128]);
    });

    test('should write Float32 in big-endian format', () {
      writer.writeFloat32(3.1415927);
      expect(writer.takeBytes(), [64, 73, 15, 219]);
    });

    test('should write Float32 in little-endian format', () {
      writer.writeFloat32(3.1415927, Endian.little);
      expect(writer.takeBytes(), [219, 15, 73, 64]);
    });

    test('should write Float64 in big-endian format', () {
      writer.writeFloat64(3.141592653589793);
      expect(writer.takeBytes(), [64, 9, 33, 251, 84, 68, 45, 24]);
    });

    test('should write Float64 in little-endian format', () {
      writer.writeFloat64(3.141592653589793, Endian.little);
      expect(writer.takeBytes(), [24, 45, 68, 84, 251, 33, 9, 64]);
    });

    test('should write byte array correctly', () {
      writer.writeBytes([1, 2, 3, 4, 5]);
      expect(writer.takeBytes(), [1, 2, 3, 4, 5]);
    });

    test('should encode string to UTF-8 bytes correctly', () {
      writer.writeString('Hello, World!');
      expect(writer.takeBytes(), [
        72, 101, 108, 108, 111, 44, 32, 87, 111, 114, 108, 100, 33, // ASCII
      ]);
    });

    test('should handle complex sequence of different data types', () {
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

    test(
      'should automatically expand buffer when size exceeds initial capacity',
      () {
        for (var i = 0; i < 100; i++) {
          writer.writeUint8(i);
        }

        final result = writer.takeBytes();
        expect(result.length, equals(100));
        for (var i = 0; i < 100; i++) {
          expect(result[i], equals(i));
        }
      },
    );

    test('should allow reusing writer after takeBytes', () {
      writer.writeUint8(1);
      expect(writer.takeBytes(), [1]);

      writer.writeUint8(2);
      expect(writer.takeBytes(), [2]);
    });

    test('should handle writing large data sets efficiently', () {
      final largeData = Uint8List.fromList(
        List.generate(10000, (i) => i % 256),
      );

      writer.writeBytes(largeData);

      final result = writer.takeBytes();

      expect(result.length, equals(10000));
      expect(result, equals(largeData));
    });

    test('should track bytesWritten correctly', () {
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

    group('Input validation', () {
      test('should throw AssertionError when Uint8 value is negative', () {
        expect(() => writer.writeUint8(-1), throwsA(isA<AssertionError>()));
      });

      test('should throw AssertionError when Uint8 value exceeds 255', () {
        expect(() => writer.writeUint8(256), throwsA(isA<AssertionError>()));
      });

      test('should throw AssertionError when Int8 value is less than -128', () {
        expect(() => writer.writeInt8(-129), throwsA(isA<AssertionError>()));
      });

      test('should throw AssertionError when Int8 value exceeds 127', () {
        expect(() => writer.writeInt8(128), throwsA(isA<AssertionError>()));
      });

      test('should throw AssertionError when Uint16 value is negative', () {
        expect(() => writer.writeUint16(-1), throwsA(isA<AssertionError>()));
      });

      test('should throw AssertionError when Uint16 value exceeds 65535', () {
        expect(() => writer.writeUint16(65536), throwsA(isA<AssertionError>()));
      });

      test(
        'should throw AssertionError when Int16 value is less than -32768',
        () {
          expect(
            () => writer.writeInt16(-32769),
            throwsA(isA<AssertionError>()),
          );
        },
      );

      test('should throw AssertionError when Int16 value exceeds 32767', () {
        expect(() => writer.writeInt16(32768), throwsA(isA<AssertionError>()));
      });

      test('should throw AssertionError when Uint32 value is negative', () {
        expect(() => writer.writeUint32(-1), throwsA(isA<AssertionError>()));
      });

      test(
        'should throw AssertionError when Uint32 value exceeds 4294967295',
        () {
          expect(
            () => writer.writeUint32(4294967296),
            throwsA(isA<AssertionError>()),
          );
        },
      );

      test(
        'should throw AssertionError when Int32 value is less than -2147483648',
        () {
          expect(
            () => writer.writeInt32(-2147483649),
            throwsA(isA<AssertionError>()),
          );
        },
      );

      test(
        'should throw AssertionError when Int32 value exceeds 2147483647',
        () {
          expect(
            () => writer.writeInt32(2147483648),
            throwsA(isA<AssertionError>()),
          );
        },
      );
    });

    group('toBytes', () {
      test('should return current buffer without resetting writer state', () {
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

      test(
        'should behave differently from takeBytes '
        '(toBytes preserves state, takeBytes resets)',
        () {
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
        },
      );

      test('should return empty list when called on empty writer', () {
        final bytes = writer.toBytes();
        expect(bytes, isEmpty);
      });
    });

    group('clear', () {
      test('should reset writer state without returning bytes', () {
        writer
          ..writeUint8(42)
          ..writeUint8(100)
          ..clear();

        expect(writer.bytesWritten, equals(0));
        expect(writer.toBytes(), isEmpty);
      });

      test('should allow writing new data after reset', () {
        writer
          ..writeUint8(42)
          ..clear()
          ..writeUint8(100);

        expect(writer.toBytes(), equals([100]));
      });

      test('should be safe to call on empty writer', () {
        writer.clear();
        expect(writer.bytesWritten, equals(0));
      });
    });

    group('Edge cases', () {
      test('should handle empty string correctly', () {
        writer.writeString('');
        expect(writer.bytesWritten, equals(0));
        expect(writer.toBytes(), isEmpty);
      });

      test('should handle empty byte array correctly', () {
        writer.writeBytes([]);
        expect(writer.bytesWritten, equals(0));
        expect(writer.toBytes(), isEmpty);
      });

      test('should encode emoji characters correctly', () {
        const str = '🚀👨‍👩‍👧‍👦';
        writer.writeString(str);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readString(bytes.length), equals(str));
      });

      test('should handle Float32 NaN value correctly', () {
        writer.writeFloat32(double.nan);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readFloat32().isNaN, isTrue);
      });

      test('should handle Float32 positive Infinity correctly', () {
        writer.writeFloat32(double.infinity);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readFloat32(), equals(double.infinity));
      });

      test('should handle Float32 negative Infinity correctly', () {
        writer.writeFloat32(double.negativeInfinity);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readFloat32(), equals(double.negativeInfinity));
      });

      test('should handle Float64 NaN value correctly', () {
        writer.writeFloat64(double.nan);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readFloat64().isNaN, isTrue);
      });

      test('should handle Float64 positive Infinity correctly', () {
        writer.writeFloat64(double.infinity);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readFloat64(), equals(double.infinity));
      });

      test('should handle Float64 negative Infinity correctly', () {
        writer.writeFloat64(double.negativeInfinity);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readFloat64(), equals(double.negativeInfinity));
      });

      test('should preserve negative zero in Float64', () {
        writer.writeFloat64(-0);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        final value = reader.readFloat64();
        expect(value, equals(0.0));
        expect(value.isNegative, isTrue);
      });

      test('should throw AssertionError when Uint64 value is negative', () {
        expect(() => writer.writeUint64(-1), throwsA(isA<AssertionError>()));
      });

      test(
        'should correctly expand buffer when exceeding initial capacity by '
        'one byte',
        () {
          final writer = BinaryWriter(initialBufferSize: 8)
            // Write exactly 8 bytes
            ..writeUint64(42);
          expect(writer.bytesWritten, equals(8));

          // Writing one more byte should trigger expansion
          writer.writeUint8(1);
          expect(writer.bytesWritten, equals(9));

          final bytes = writer.takeBytes();
          expect(bytes.length, equals(9));
        },
      );

      test('should handle multiple consecutive clear calls', () {
        writer
          ..writeUint8(42)
          ..clear()
          ..clear()
          ..clear();

        expect(writer.bytesWritten, equals(0));
      });

      test('should support method chaining after clear', () {
        writer
          ..writeUint8(1)
          ..clear()
          ..writeUint8(2)
          ..writeUint8(3);

        expect(writer.toBytes(), equals([2, 3]));
      });
    });

    group('Boundary values - Maximum', () {
      test('should handle Uint8 maximum value (255)', () {
        writer.writeUint8(255);
        expect(writer.takeBytes(), equals([255]));
      });

      test('should handle Int8 maximum positive value (127)', () {
        writer.writeInt8(127);
        expect(writer.takeBytes(), equals([127]));
      });

      test('should handle Int8 minimum negative value (-128)', () {
        writer.writeInt8(-128);
        expect(writer.takeBytes(), equals([128]));
      });

      test('should handle Uint16 maximum value (65535)', () {
        writer.writeUint16(65535);
        expect(writer.takeBytes(), equals([255, 255]));
      });

      test('should handle Int16 maximum positive value (32767)', () {
        writer.writeInt16(32767);
        expect(writer.takeBytes(), equals([127, 255]));
      });

      test('should handle Uint32 maximum value (4294967295)', () {
        writer.writeUint32(4294967295);
        expect(writer.takeBytes(), equals([255, 255, 255, 255]));
      });

      test('should handle Int32 maximum positive value (2147483647)', () {
        writer.writeInt32(2147483647);
        expect(writer.takeBytes(), equals([127, 255, 255, 255]));
      });

      test('should handle Uint64 maximum value (9223372036854775807)', () {
        writer.writeUint64(9223372036854775807);
        expect(
          writer.takeBytes(),
          equals([127, 255, 255, 255, 255, 255, 255, 255]),
        );
      });

      test(
        'should handle Int64 maximum positive value (9223372036854775807)',
        () {
          writer.writeInt64(9223372036854775807);
          expect(
            writer.takeBytes(),
            equals([127, 255, 255, 255, 255, 255, 255, 255]),
          );
        },
      );
    });

    group('Boundary values - Minimum', () {
      test('should handle Uint8 minimum value (0)', () {
        writer.writeUint8(0);
        expect(writer.takeBytes(), equals([0]));
      });

      test('should handle Int8 zero value', () {
        writer.writeInt8(0);
        expect(writer.takeBytes(), equals([0]));
      });

      test('should handle Uint16 minimum value (0)', () {
        writer.writeUint16(0);
        expect(writer.takeBytes(), equals([0, 0]));
      });

      test('should handle Int16 zero value', () {
        writer.writeInt16(0);
        expect(writer.takeBytes(), equals([0, 0]));
      });

      test('should handle Uint32 minimum value (0)', () {
        writer.writeUint32(0);
        expect(writer.takeBytes(), equals([0, 0, 0, 0]));
      });

      test('should handle Int32 zero value', () {
        writer.writeInt32(0);
        expect(writer.takeBytes(), equals([0, 0, 0, 0]));
      });

      test('should handle Uint64 minimum value (0)', () {
        writer.writeUint64(0);
        expect(writer.takeBytes(), equals([0, 0, 0, 0, 0, 0, 0, 0]));
      });

      test('should handle Int64 zero value', () {
        writer.writeInt64(0);
        expect(writer.takeBytes(), equals([0, 0, 0, 0, 0, 0, 0, 0]));
      });
    });

    group('Multiple operations', () {
      test('should handle multiple consecutive takeBytes calls', () {
        writer.writeUint8(1);
        expect(writer.takeBytes(), equals([1]));

        writer.writeUint8(2);
        expect(writer.takeBytes(), equals([2]));

        writer.writeUint8(3);
        expect(writer.takeBytes(), equals([3]));
      });

      test('should handle toBytes followed by clear', () {
        writer
          ..writeUint8(42)
          ..writeUint8(100);

        final bytes1 = writer.toBytes();
        expect(bytes1, equals([42, 100]));

        writer.clear();
        expect(writer.toBytes(), isEmpty);
        expect(writer.bytesWritten, equals(0));
      });

      test('should handle multiple toBytes calls without modification', () {
        writer
          ..writeUint8(1)
          ..writeUint8(2);

        final bytes1 = writer.toBytes();
        final bytes2 = writer.toBytes();
        final bytes3 = writer.toBytes();

        expect(bytes1, equals([1, 2]));
        expect(bytes2, equals([1, 2]));
        expect(bytes3, equals([1, 2]));
      });
    });

    group('Byte array types', () {
      test('should accept Uint8List in writeBytes', () {
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);
        writer.writeBytes(data);
        expect(writer.takeBytes(), equals([1, 2, 3, 4, 5]));
      });

      test('should accept regular List<int> in writeBytes', () {
        final data = <int>[10, 20, 30, 40, 50];
        writer.writeBytes(data);
        expect(writer.takeBytes(), equals([10, 20, 30, 40, 50]));
      });

      test('should handle mixed types in sequence', () {
        writer
          ..writeBytes(Uint8List.fromList([1, 2]))
          ..writeBytes([3, 4])
          ..writeUint8(5);

        expect(writer.takeBytes(), equals([1, 2, 3, 4, 5]));
      });
    });

    group('Float precision', () {
      test('should handle Float32 minimum positive subnormal value', () {
        const minFloat32 = 1.4e-45; // Approximate minimum positive Float32
        writer.writeFloat32(minFloat32);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        final value = reader.readFloat32();
        expect(value, greaterThan(0));
      });

      test('should handle Float64 minimum positive subnormal value', () {
        const minFloat64 = 5e-324; // Approximate minimum positive Float64
        writer.writeFloat64(minFloat64);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        final value = reader.readFloat64();
        expect(value, greaterThan(0));
      });

      test('should handle Float32 maximum value', () {
        const maxFloat32 = 3.4028235e38; // Approximate maximum Float32
        writer.writeFloat32(maxFloat32);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readFloat32(), closeTo(maxFloat32, maxFloat32 * 0.01));
      });

      test('should handle Float64 maximum value', () {
        const maxFloat64 = 1.7976931348623157e308; // Maximum Float64
        writer.writeFloat64(maxFloat64);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readFloat64(), equals(maxFloat64));
      });
    });

    group('UTF-8 encoding', () {
      test('should encode ASCII characters correctly', () {
        writer.writeString('ABC123');
        expect(writer.takeBytes(), equals([65, 66, 67, 49, 50, 51]));
      });

      test('should encode Cyrillic characters correctly', () {
        writer.writeString('Привет');
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readString(bytes.length), equals('Привет'));
      });

      test('should encode Chinese characters correctly', () {
        const str = '你好世界';
        writer.writeString(str);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readString(bytes.length), equals(str));
      });

      test('should encode mixed Unicode string correctly', () {
        const str = 'Hello мир 世界 🌍';
        writer.writeString(str);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readString(bytes.length), equals(str));
      });
    });

    group('Buffer growth strategy', () {
      test('should use 1.5x growth strategy', () {
        final writer = BinaryWriter(initialBufferSize: 4)
          // Fill initial 4 bytes
          ..writeUint32(0);
        expect(writer.bytesWritten, equals(4));

        // Trigger expansion by writing one more byte
        writer.writeUint8(1);
        expect(writer.bytesWritten, equals(5));

        // Should be able to write more without issues
        writer
          ..writeUint8(2)
          ..writeUint8(3);
        expect(writer.bytesWritten, equals(7));
      });

      test(
        'should grow buffer to exact required size when 1.5x is insufficient',
        () {
          final writer = BinaryWriter(initialBufferSize: 4);

          // Write a large block that requires more than 1.5x growth
          final largeData = Uint8List(100);
          writer.writeBytes(largeData);

          expect(writer.bytesWritten, equals(100));
        },
      );
    });

    group('State preservation', () {
      test('should preserve written data across toBytes calls', () {
        writer.writeUint32(0x12345678);

        final bytes1 = writer.toBytes();
        expect(bytes1, equals([0x12, 0x34, 0x56, 0x78]));

        // Write more data
        writer.writeUint32(0xABCDEF00);

        final bytes2 = writer.toBytes();
        expect(
          bytes2,
          equals([0x12, 0x34, 0x56, 0x78, 0xAB, 0xCD, 0xEF, 0x00]),
        );
      });

      test(
        'should not affect data when calling bytesWritten multiple times',
        () {
          writer
            ..writeUint8(1)
            ..writeUint8(2)
            ..writeUint8(3);

          expect(writer.bytesWritten, equals(3));
          expect(writer.bytesWritten, equals(3));
          expect(writer.bytesWritten, equals(3));

          expect(writer.toBytes(), equals([1, 2, 3]));
        },
      );
    });
  });
}
