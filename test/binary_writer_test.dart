import 'dart:convert';
import 'dart:typed_data';

import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('BinaryWriter', () {
    late BinaryWriter writer;

    setUp(() {
      writer = BinaryWriter();
    });

    test('return empty list when takeBytes called on empty writer', () {
      expect(writer.takeBytes(), isEmpty);
    });

    test('write single Uint8 value correctly', () {
      writer.writeUint8(1);
      expect(writer.takeBytes(), [1]);
    });

    test('write negative Int8 value correctly', () {
      writer.writeInt8(-1);
      expect(writer.takeBytes(), [255]);
    });

    test('write Uint16 in big-endian format', () {
      writer.writeUint16(256);
      expect(writer.takeBytes(), [1, 0]);
    });

    test('write Uint16 in little-endian format', () {
      writer.writeUint16(256, .little);
      expect(writer.takeBytes(), [0, 1]);
    });

    test('write Int16 in big-endian format', () {
      writer.writeInt16(-1);
      expect(writer.takeBytes(), [255, 255]);
    });

    test('write Int16 in little-endian format', () {
      writer.writeInt16(-32768, .little);
      expect(writer.takeBytes(), [0, 128]);
    });

    test('write Uint32 in big-endian format', () {
      writer.writeUint32(65536);
      expect(writer.takeBytes(), [0, 1, 0, 0]);
    });

    test('write Uint32 in little-endian format', () {
      writer.writeUint32(65536, .little);
      expect(writer.takeBytes(), [0, 0, 1, 0]);
    });

    test('write Int32 in big-endian format', () {
      writer.writeInt32(-1);
      expect(writer.takeBytes(), [255, 255, 255, 255]);
    });

    test('write Int32 in little-endian format', () {
      writer.writeInt32(-2147483648, .little);
      expect(writer.takeBytes(), [0, 0, 0, 128]);
    });

    test('write Uint64 in big-endian format', () {
      writer.writeUint64(4294967296);
      expect(writer.takeBytes(), [0, 0, 0, 1, 0, 0, 0, 0]);
    });

    test('write Uint64 in little-endian format', () {
      writer.writeUint64(4294967296, .little);
      expect(writer.takeBytes(), [0, 0, 0, 0, 1, 0, 0, 0]);
    });

    test('write Int64 in big-endian format', () {
      writer.writeInt64(-1);
      expect(writer.takeBytes(), [255, 255, 255, 255, 255, 255, 255, 255]);
    });

    test('write Int64 in little-endian format', () {
      writer.writeInt64(-9223372036854775808, .little);
      expect(writer.takeBytes(), [0, 0, 0, 0, 0, 0, 0, 128]);
    });

    test('write Float32 in big-endian format', () {
      writer.writeFloat32(3.1415927);
      expect(writer.takeBytes(), [64, 73, 15, 219]);
    });

    test('write Float32 in little-endian format', () {
      writer.writeFloat32(3.1415927, .little);
      expect(writer.takeBytes(), [219, 15, 73, 64]);
    });

    test('write Float64 in big-endian format', () {
      writer.writeFloat64(3.141592653589793);
      expect(writer.takeBytes(), [64, 9, 33, 251, 84, 68, 45, 24]);
    });

    test('write Float64 in little-endian format', () {
      writer.writeFloat64(3.141592653589793, .little);
      expect(writer.takeBytes(), [24, 45, 68, 84, 251, 33, 9, 64]);
    });

    test('write VarInt single byte (0)', () {
      writer.writeVarUint(0);
      expect(writer.takeBytes(), [0]);
    });

    test('write VarInt single byte (127)', () {
      writer.writeVarUint(127);
      expect(writer.takeBytes(), [127]);
    });

    test('write VarInt two bytes (128)', () {
      writer.writeVarUint(128);
      expect(writer.takeBytes(), [0x80, 0x01]);
    });

    test('write VarInt two bytes (300)', () {
      writer.writeVarUint(300);
      expect(writer.takeBytes(), [0xAC, 0x02]);
    });

    test('write VarInt three bytes (16384)', () {
      writer.writeVarUint(16384);
      expect(writer.takeBytes(), [0x80, 0x80, 0x01]);
    });

    test('write VarInt four bytes (2097151)', () {
      writer.writeVarUint(2097151);
      expect(writer.takeBytes(), [0xFF, 0xFF, 0x7F]);
    });

    test('write VarInt five bytes (268435455)', () {
      writer.writeVarUint(268435455);
      expect(writer.takeBytes(), [0xFF, 0xFF, 0xFF, 0x7F]);
    });

    test('write VarInt large value', () {
      writer.writeVarUint(1 << 30);
      expect(writer.takeBytes(), [0x80, 0x80, 0x80, 0x80, 0x04]);
    });

    test('write ZigZag encoding for positive values', () {
      writer.writeVarInt(0);
      expect(writer.takeBytes(), [0]);
    });

    test('write ZigZag encoding for positive value 1', () {
      writer.writeVarInt(1);
      expect(writer.takeBytes(), [2]);
    });

    test('write ZigZag encoding for negative value -1', () {
      writer.writeVarInt(-1);
      expect(writer.takeBytes(), [1]);
    });

    test('write ZigZag encoding for positive value 2', () {
      writer.writeVarInt(2);
      expect(writer.takeBytes(), [4]);
    });

    test('write ZigZag encoding for negative value -2', () {
      writer.writeVarInt(-2);
      expect(writer.takeBytes(), [3]);
    });

    test('write ZigZag encoding for large positive value', () {
      writer.writeVarInt(2147483647);
      expect(writer.takeBytes(), [0xFE, 0xFF, 0xFF, 0xFF, 0x0F]);
    });

    test('write ZigZag encoding for large negative value', () {
      writer.writeVarInt(-2147483648);
      expect(writer.takeBytes(), [0xFF, 0xFF, 0xFF, 0xFF, 0x0F]);
    });

    test('writeVarUint fast path boundary: 0', () {
      // 0 is unsigned and should use fast path (single byte)
      writer.writeVarUint(0);
      expect(writer.takeBytes(), [0]);
    });

    test('writeVarUint fast path boundary: 127 (max single byte)', () {
      // 127 (0x7F) is the last value where MSB is not set
      writer.writeVarUint(127);
      expect(writer.takeBytes(), [127]);
    });

    test('writeVarUint multi-byte boundary: 128 (min two bytes)', () {
      // 128 (0x80) requires 2 bytes because MSB is set
      writer.writeVarUint(128);
      expect(writer.takeBytes(), [0x80, 0x01]);
    });

    test('writeVarInt fast path: ZigZag encodes small values correctly', () {
      // ZigZag(0) = 0 → single byte
      writer.writeVarInt(0);
      expect(writer.toBytes(), [0]);

      writer
        ..reset()
        // ZigZag(1) = 2 → single byte
        ..writeVarInt(1);
      expect(writer.toBytes(), [2]);

      writer
        ..reset()
        // ZigZag(-1) = 1 → single byte
        ..writeVarInt(-1);
      expect(writer.toBytes(), [1]);
    });

    test('writeVarInt multi-byte: ZigZag crosses boundary correctly', () {
      // ZigZag(64) = 128 → requires 2 bytes (MSB set)
      writer.writeVarInt(64);
      expect(writer.takeBytes(), [0x80, 0x01]);

      // ZigZag(-64) = 127 → single byte
      writer.writeVarInt(-64);
      expect(writer.takeBytes(), [127]);

      // ZigZag(-65) = 129 → requires 2 bytes
      writer.writeVarInt(-65);
      expect(writer.takeBytes(), [0x81, 0x01]);
    });

    test(
      'writeVarUint with negative value must not use fast path '
      '(regression test)',
      () {
        // CRITICAL: writeVarUint(-1) must NOT use fast path
        // Negative numbers: -1 as bits = 0xFFFFFFFF...
        // -1 < 0x80 is FALSE, so it should use slow path
        // This verifies the `value >= 0` check is necessary

        writer.writeVarUint(-1);
        final bytes = writer.takeBytes();

        // Without `value >= 0` check, -1 might be incorrectly encoded as 1 byte
        // With check: -1 triggers slow path and encodes as 10 bytes
        expect(
          bytes.length,
          10,
          reason: 'Negative number should use multi-byte path',
        );
        expect(
          bytes[0],
          0xFF,
          reason: 'First byte should have continuation bit set',
        );
        expect(bytes[9], 0x01, reason: 'Last byte should be continuation end');
      },
    );

    test('write byte array correctly', () {
      writer.writeBytes([1, 2, 3, 4, 5]);
      expect(writer.takeBytes(), [1, 2, 3, 4, 5]);
    });

    test('encode string to UTF-8 bytes correctly', () {
      writer.writeString('Hello, World!');
      expect(writer.takeBytes(), [
        72, 101, 108, 108, 111, 44, 32, 87, 111, 114, 108, 100, 33, // ASCII
      ]);
    });

    test('handle complex sequence of different data types', () {
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

    test('allow reusing writer after takeBytes', () {
      writer.writeUint8(1);
      expect(writer.takeBytes(), [1]);

      writer.writeUint8(2);
      expect(writer.takeBytes(), [2]);
    });

    test('handle writing large data sets efficiently', () {
      final largeData = Uint8List.fromList(
        List.generate(10000, (i) => i % 256),
      );

      writer.writeBytes(largeData);

      final result = writer.takeBytes();

      expect(result.length, equals(10000));
      expect(result, equals(largeData));
    });

    test('track bytesWritten correctly', () {
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
      test('throw AssertionError when Uint8 value is negative', () {
        expect(
          () => writer.writeUint8(-1),
          throwsA(
            isA<RangeError>()
                .having((e) => e.name, 'name', 'Uint8')
                .having((e) => e.start, 'start', 0)
                .having((e) => e.end, 'end', 255),
          ),
        );
      });

      test('throw AssertionError when Uint8 value exceeds 255', () {
        expect(
          () => writer.writeUint8(256),
          throwsA(
            isA<RangeError>()
                .having((e) => e.name, 'name', 'Uint8')
                .having((e) => e.start, 'start', 0)
                .having((e) => e.end, 'end', 255),
          ),
        );
      });

      test('throw AssertionError when Int8 value is less than -128', () {
        expect(
          () => writer.writeInt8(-129),
          throwsA(
            isA<RangeError>()
                .having((e) => e.name, 'name', 'Int8')
                .having((e) => e.start, 'start', -128)
                .having((e) => e.end, 'end', 127),
          ),
        );
      });

      test('throw AssertionError when Int8 value exceeds 127', () {
        expect(
          () => writer.writeInt8(128),
          throwsA(
            isA<RangeError>()
                .having((e) => e.name, 'name', 'Int8')
                .having((e) => e.start, 'start', -128)
                .having((e) => e.end, 'end', 127),
          ),
        );
      });

      test('throw AssertionError when Uint16 value is negative', () {
        expect(
          () => writer.writeUint16(-1),
          throwsA(
            isA<RangeError>()
                .having((e) => e.name, 'name', 'Uint16')
                .having((e) => e.start, 'start', 0)
                .having((e) => e.end, 'end', 65535),
          ),
        );
      });

      test('throw AssertionError when Uint16 value exceeds 65535', () {
        expect(
          () => writer.writeUint16(65536),
          throwsA(
            isA<RangeError>()
                .having((e) => e.name, 'name', 'Uint16')
                .having((e) => e.start, 'start', 0)
                .having((e) => e.end, 'end', 65535),
          ),
        );
      });

      test(
        'should throw AssertionError when Int16 value is less than -32768',
        () {
          expect(
            () => writer.writeInt16(-32769),
            throwsA(
              isA<RangeError>()
                  .having((e) => e.name, 'name', 'Int16')
                  .having((e) => e.start, 'start', -32768)
                  .having((e) => e.end, 'end', 32767),
            ),
          );
        },
      );

      test('throw AssertionError when Int16 value exceeds 32767', () {
        expect(
          () => writer.writeInt16(32768),
          throwsA(
            isA<RangeError>()
                .having((e) => e.name, 'name', 'Int16')
                .having((e) => e.start, 'start', -32768)
                .having((e) => e.end, 'end', 32767),
          ),
        );
      });

      test('throw AssertionError when Uint32 value is negative', () {
        expect(
          () => writer.writeUint32(-1),
          throwsA(
            isA<RangeError>()
                .having((e) => e.name, 'name', 'Uint32')
                .having((e) => e.start, 'start', 0)
                .having((e) => e.end, 'end', 4294967295),
          ),
        );
      });

      test(
        'should throw AssertionError when Uint32 value exceeds 4294967295',
        () {
          expect(
            () => writer.writeUint32(4294967296),
            throwsA(
              isA<RangeError>()
                  .having((e) => e.name, 'name', 'Uint32')
                  .having((e) => e.start, 'start', 0)
                  .having((e) => e.end, 'end', 4294967295),
            ),
          );
        },
      );

      test(
        'should throw AssertionError when Int32 value is less than -2147483648',
        () {
          expect(
            () => writer.writeInt32(-2147483649),
            throwsA(
              isA<RangeError>()
                  .having((e) => e.name, 'name', 'Int32')
                  .having((e) => e.start, 'start', -2147483648)
                  .having((e) => e.end, 'end', 2147483647),
            ),
          );
        },
      );

      test(
        'should throw AssertionError when Int32 value exceeds 2147483647',
        () {
          expect(
            () => writer.writeInt32(2147483648),
            throwsA(
              isA<RangeError>()
                  .having((e) => e.name, 'name', 'Int32')
                  .having((e) => e.start, 'start', -2147483648)
                  .having((e) => e.end, 'end', 2147483647),
            ),
          );
        },
      );
    });

    group('toBytes', () {
      test('return current buffer without resetting writer state', () {
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

      test('return empty list when called on empty writer', () {
        final bytes = writer.toBytes();
        expect(bytes, isEmpty);
      });
    });

    group('clear', () {
      test('reset writer state without returning bytes', () {
        writer
          ..writeUint8(42)
          ..writeUint8(100)
          ..reset();

        expect(writer.bytesWritten, equals(0));
        expect(writer.toBytes(), isEmpty);
      });

      test('allow writing new data after reset', () {
        writer
          ..writeUint8(42)
          ..reset()
          ..writeUint8(100);

        expect(writer.toBytes(), equals([100]));
      });

      test('be safe to call on empty writer', () {
        writer.reset();
        expect(writer.bytesWritten, equals(0));
      });
    });

    group('Edge cases', () {
      test('handle empty string correctly', () {
        writer.writeString('');
        expect(writer.bytesWritten, equals(0));
        expect(writer.toBytes(), isEmpty);
      });

      test('handle empty byte array correctly', () {
        writer.writeBytes([]);
        expect(writer.bytesWritten, equals(0));
        expect(writer.toBytes(), isEmpty);
      });

      test('encode emoji characters correctly', () {
        const str = '🚀👨‍👩‍👧‍👦';
        writer.writeString(str);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readString(bytes.length), equals(str));
      });

      test('handle Float32 NaN value correctly', () {
        writer.writeFloat32(double.nan);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readFloat32().isNaN, isTrue);
      });

      test('handle Float32 positive Infinity correctly', () {
        writer.writeFloat32(double.infinity);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readFloat32(), equals(double.infinity));
      });

      test('handle Float32 negative Infinity correctly', () {
        writer.writeFloat32(double.negativeInfinity);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readFloat32(), equals(double.negativeInfinity));
      });

      test('handle Float64 NaN value correctly', () {
        writer.writeFloat64(double.nan);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readFloat64().isNaN, isTrue);
      });

      test('handle Float64 positive Infinity correctly', () {
        writer.writeFloat64(double.infinity);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readFloat64(), equals(double.infinity));
      });

      test('handle Float64 negative Infinity correctly', () {
        writer.writeFloat64(double.negativeInfinity);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readFloat64(), equals(double.negativeInfinity));
      });

      test('preserve negative zero in Float64', () {
        writer.writeFloat64(-0);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        final value = reader.readFloat64();
        expect(value, equals(0.0));
        expect(value.isNegative, isTrue);
      });

      test('throw AssertionError when Uint64 value is negative', () {
        expect(
          () => writer.writeUint64(-1),
          throwsA(
            isA<RangeError>()
                .having((e) => e.name, 'name', 'Uint64')
                .having((e) => e.start, 'start', 0)
                .having((e) => e.end, 'end', 9223372036854775807),
          ),
        );
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

      test('handle multiple consecutive reset calls', () {
        writer
          ..writeUint8(42)
          ..reset()
          ..reset()
          ..reset();

        expect(writer.bytesWritten, equals(0));
      });

      test('support method chaining after reset', () {
        writer
          ..writeUint8(1)
          ..reset()
          ..writeUint8(2)
          ..writeUint8(3);

        expect(writer.toBytes(), equals([2, 3]));
      });
    });

    group('Boundary values - Maximum', () {
      test('handle Uint8 maximum value (255)', () {
        writer.writeUint8(255);
        expect(writer.takeBytes(), equals([255]));
      });

      test('handle Int8 maximum positive value (127)', () {
        writer.writeInt8(127);
        expect(writer.takeBytes(), equals([127]));
      });

      test('handle Int8 minimum negative value (-128)', () {
        writer.writeInt8(-128);
        expect(writer.takeBytes(), equals([128]));
      });

      test('handle Uint16 maximum value (65535)', () {
        writer.writeUint16(65535);
        expect(writer.takeBytes(), equals([255, 255]));
      });

      test('handle Int16 maximum positive value (32767)', () {
        writer.writeInt16(32767);
        expect(writer.takeBytes(), equals([127, 255]));
      });

      test('handle Uint32 maximum value (4294967295)', () {
        writer.writeUint32(4294967295);
        expect(writer.takeBytes(), equals([255, 255, 255, 255]));
      });

      test('handle Int32 maximum positive value (2147483647)', () {
        writer.writeInt32(2147483647);
        expect(writer.takeBytes(), equals([127, 255, 255, 255]));
      });

      test('handle Uint64 maximum value (9223372036854775807)', () {
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
      test('handle Uint8 minimum value (0)', () {
        writer.writeUint8(0);
        expect(writer.takeBytes(), equals([0]));
      });

      test('handle Int8 zero value', () {
        writer.writeInt8(0);
        expect(writer.takeBytes(), equals([0]));
      });

      test('handle Uint16 minimum value (0)', () {
        writer.writeUint16(0);
        expect(writer.takeBytes(), equals([0, 0]));
      });

      test('handle Int16 zero value', () {
        writer.writeInt16(0);
        expect(writer.takeBytes(), equals([0, 0]));
      });

      test('handle Uint32 minimum value (0)', () {
        writer.writeUint32(0);
        expect(writer.takeBytes(), equals([0, 0, 0, 0]));
      });

      test('handle Int32 zero value', () {
        writer.writeInt32(0);
        expect(writer.takeBytes(), equals([0, 0, 0, 0]));
      });

      test('handle Uint64 minimum value (0)', () {
        writer.writeUint64(0);
        expect(writer.takeBytes(), equals([0, 0, 0, 0, 0, 0, 0, 0]));
      });

      test('handle Int64 zero value', () {
        writer.writeInt64(0);
        expect(writer.takeBytes(), equals([0, 0, 0, 0, 0, 0, 0, 0]));
      });
    });

    group('Multiple operations', () {
      test('handle multiple consecutive takeBytes calls', () {
        writer.writeUint8(1);
        expect(writer.takeBytes(), equals([1]));

        writer.writeUint8(2);
        expect(writer.takeBytes(), equals([2]));

        writer.writeUint8(3);
        expect(writer.takeBytes(), equals([3]));
      });

      test('handle toBytes followed by reset', () {
        writer
          ..writeUint8(42)
          ..writeUint8(100);

        final bytes1 = writer.toBytes();
        expect(bytes1, equals([42, 100]));

        writer.reset();
        expect(writer.toBytes(), isEmpty);
        expect(writer.bytesWritten, equals(0));
      });

      test('handle multiple toBytes calls without modification', () {
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
      test('accept Uint8List in writeBytes', () {
        final data = Uint8List.fromList([1, 2, 3, 4, 5]);
        writer.writeBytes(data);
        expect(writer.takeBytes(), equals([1, 2, 3, 4, 5]));
      });

      test('accept regular List<int> in writeBytes', () {
        final data = <int>[10, 20, 30, 40, 50];
        writer.writeBytes(data);
        expect(writer.takeBytes(), equals([10, 20, 30, 40, 50]));
      });

      test('handle mixed types in sequence', () {
        writer
          ..writeBytes(Uint8List.fromList([1, 2]))
          ..writeBytes([3, 4])
          ..writeUint8(5);

        expect(writer.takeBytes(), equals([1, 2, 3, 4, 5]));
      });

      test('writeBytes with offset parameter', () {
        final data = [1, 2, 3, 4, 5];
        writer.writeBytes(data, 2); // Write from index 2: [3, 4, 5]
        expect(writer.takeBytes(), equals([3, 4, 5]));
      });

      test('writeBytes with offset and length parameters', () {
        final data = [1, 2, 3, 4, 5];
        writer.writeBytes(data, 1, 3); // Write [2, 3, 4]
        expect(writer.takeBytes(), equals([2, 3, 4]));
      });

      test('writeBytes with offset at end', () {
        final data = [1, 2, 3, 4, 5];
        writer.writeBytes(data, 5); // Write from end (empty)
        expect(writer.takeBytes(), equals([]));
      });

      test('writeBytes with zero length', () {
        final data = [1, 2, 3, 4, 5];
        writer.writeBytes(data, 0, 0); // Write 0 bytes
        expect(writer.takeBytes(), equals([]));
      });

      test('writeBytes throws on negative offset', () {
        final data = [1, 2, 3, 4, 5];
        expect(
          () => writer.writeBytes(data, -1),
          throwsA(isA<AssertionError>()),
        );
      });

      test('writeBytes throws on negative length', () {
        final data = [1, 2, 3, 4, 5];
        expect(
          () => writer.writeBytes(data, 0, -1),
          throwsA(isA<AssertionError>()),
        );
      });

      test('writeBytes throws when offset exceeds list length', () {
        final data = [1, 2, 3];
        expect(
          () => writer.writeBytes(data, 4),
          throwsA(isA<AssertionError>()),
        );
      });

      test('writeBytes throws when offset + length exceeds list', () {
        final data = [1, 2, 3, 4, 5];
        expect(
          // offset 2 + length 5 > list length 5
          () => writer.writeBytes(data, 2, 5),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('Float precision', () {
      test('handle Float32 minimum positive subnormal value', () {
        const minFloat32 = 1.4e-45; // Approximate minimum positive Float32
        writer.writeFloat32(minFloat32);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        final value = reader.readFloat32();
        expect(value, greaterThan(0));
      });

      test('handle Float64 minimum positive subnormal value', () {
        const minFloat64 = 5e-324; // Approximate minimum positive Float64
        writer.writeFloat64(minFloat64);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        final value = reader.readFloat64();
        expect(value, greaterThan(0));
      });

      test('handle Float32 maximum value', () {
        const maxFloat32 = 3.4028235e38; // Approximate maximum Float32
        writer.writeFloat32(maxFloat32);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readFloat32(), closeTo(maxFloat32, maxFloat32 * 0.01));
      });

      test('handle Float64 maximum value', () {
        const maxFloat64 = 1.7976931348623157e308; // Maximum Float64
        writer.writeFloat64(maxFloat64);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readFloat64(), equals(maxFloat64));
      });
    });

    group('UTF-8 encoding', () {
      test('encode ASCII characters correctly', () {
        writer.writeString('ABC123');
        expect(writer.takeBytes(), equals([65, 66, 67, 49, 50, 51]));
      });

      test('encode Cyrillic characters correctly', () {
        writer.writeString('Привет');
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readString(bytes.length), equals('Привет'));
      });

      test('encode Chinese characters correctly', () {
        const str = '你好世界';
        writer.writeString(str);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readString(bytes.length), equals(str));
      });

      test('encode mixed Unicode string correctly', () {
        const str = 'Hello мир 世界 🌍';
        writer.writeString(str);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readString(bytes.length), equals(str));
      });
    });

    group('Buffer growth strategy', () {
      test('use 1.5x growth strategy', () {
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
      test('preserve written data across toBytes calls', () {
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

    group('Lone surrogate pairs', () {
      test(
        'writeString handles lone high surrogate with allowMalformed=true',
        () {
          const testStr = 'Before\uD800After';
          writer.writeString(testStr);
          final bytes = writer.takeBytes();

          final reader = BinaryReader(bytes);
          final result = reader.readString(bytes.length, allowMalformed: true);
          expect(result, isNotEmpty);
          expect(result, contains('Before'));
          expect(result, contains('After'));
          expect(result.contains('\uFFFD') || result.contains('�'), isTrue);
        },
      );

      test(
        'writeString throws on lone high surrogate with allowMalformed=false',
        () {
          const testStr = 'Before\uD800After';
          expect(
            () => writer.writeString(testStr, allowMalformed: false),
            throwsA(isA<FormatException>()),
          );
        },
      );

      test(
        'writeString handles lone low surrogate with allowMalformed=true',
        () {
          const testStr = 'Before\uDC00After';
          writer.writeString(testStr);
          final bytes = writer.takeBytes();

          final reader = BinaryReader(bytes);
          final result = reader.readString(bytes.length, allowMalformed: true);
          expect(result, isNotEmpty);
          expect(result, contains('Before'));
          expect(result, contains('After'));
          expect(result.contains('\uFFFD') || result.contains('�'), isTrue);
        },
      );

      test(
        'writeString throws on lone low surrogate with allowMalformed=false',
        () {
          const testStr = 'Before\uDC00After';
          expect(
            () => writer.writeString(testStr, allowMalformed: false),
            throwsA(isA<FormatException>()),
          );
        },
      );

      test('writeString handles valid surrogate pair', () {
        const testStr = 'Test\u{1F600}End';
        writer.writeString(testStr);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        final result = reader.readString(bytes.length);
        expect(result, equals(testStr));
      });

      test('writeString handles mixed valid and invalid surrogates', () {
        const testStr = 'A\u{1F600}B\uD800C';
        writer.writeString(testStr);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        final result = reader.readString(bytes.length, allowMalformed: true);
        expect(result, contains('A'));
        expect(result, contains('B'));
        expect(result, contains('C'));
        expect(result.contains('\uFFFD') || result.contains('�'), isTrue);
      });

      test(
        'writeString throws on mixed surrogates with allowMalformed=false',
        () {
          const testStr = 'A\u{1F600}B\uD800C';
          expect(
            () => writer.writeString(testStr, allowMalformed: false),
            throwsA(isA<FormatException>()),
          );
        },
      );
    });

    group('Very large strings', () {
      test('writeString with string exceeding initial buffer size', () {
        final writer = BinaryWriter(initialBufferSize: 8);
        const largeString =
            'This is a very long string that exceeds initial'
            ' buffer size and should trigger buffer expansion properly';

        writer.writeString(largeString);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        final result = reader.readString(bytes.length);
        expect(result, equals(largeString));
      });

      test('writeString with string requiring more than 1.5x growth', () {
        final writer = BinaryWriter(initialBufferSize: 4);
        const str = 'Very long string to force larger growth';

        writer.writeString(str);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        final result = reader.readString(bytes.length);
        expect(result, equals(str));
      });

      test('writeString with multi-byte UTF-8 characters exceeding buffer', () {
        final writer = BinaryWriter(initialBufferSize: 8);
        const str = 'Привет мир! Это длинная строка для теста';

        writer.writeString(str);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        final result = reader.readString(bytes.length);
        expect(result, equals(str));
      });

      test('writeString with Chinese characters requiring buffer growth', () {
        final writer = BinaryWriter(initialBufferSize: 16);
        const str = '这是一个非常长的中文字符串用于测试缓冲区扩展功能是否正常工作';

        writer.writeString(str);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        final result = reader.readString(bytes.length);
        expect(result, equals(str));
      });
    });

    group('Uint64 maximum values', () {
      test('writeUint64 with maximum safe integer', () {
        const maxSafeInt = 9223372036854775807;
        writer.writeUint64(maxSafeInt);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readUint64(), equals(maxSafeInt));
      });

      test('writeUint64 with value 0', () {
        writer.writeUint64(0);
        final bytes = writer.takeBytes();
        expect(bytes, equals([0, 0, 0, 0, 0, 0, 0, 0]));
      });

      test('writeUint64 with large value in little-endian', () {
        const largeValue = 123456789012345; // Safe for JS: < 2^53
        writer.writeUint64(largeValue, .little);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readUint64(.little), equals(largeValue));
      });
    });

    group('Buffer growth advanced', () {
      test('exact buffer capacity boundary', () {
        final writer = BinaryWriter(initialBufferSize: 8)..writeUint64(12345);
        expect(writer.bytesWritten, equals(8));

        writer.writeUint8(1);
        expect(writer.bytesWritten, equals(9));

        final bytes = writer.takeBytes();
        expect(bytes.length, equals(9));
      });

      test('multiple expansions in sequence', () {
        final writer = BinaryWriter(initialBufferSize: 4)
          ..writeUint32(0x12345678);
        expect(writer.bytesWritten, equals(4));

        writer.writeUint8(0xAB);
        expect(writer.bytesWritten, equals(5));

        for (var i = 0; i < 20; i++) {
          writer.writeUint8(i);
        }

        expect(writer.bytesWritten, equals(25));
      });

      test('large single write triggering immediate large expansion', () {
        final writer = BinaryWriter(initialBufferSize: 8);
        final largeData = Uint8List(1000);
        for (var i = 0; i < 1000; i++) {
          largeData[i] = i % 256;
        }

        writer.writeBytes(largeData);
        expect(writer.bytesWritten, equals(1000));

        final bytes = writer.takeBytes();
        expect(bytes, equals(largeData));
      });

      test('alternating small and large writes', () {
        final writer = BinaryWriter(initialBufferSize: 16)
          ..writeUint8(1)
          ..writeBytes(Uint8List(100))
          ..writeUint8(2)
          ..writeBytes(Uint8List(50))
          ..writeUint8(3);

        expect(writer.bytesWritten, equals(153));
      });
    });

    group('Thread-safety verification', () {
      test('float conversion uses instance buffers', () {
        final writer1 = BinaryWriter();
        final writer2 = BinaryWriter();

        writer1.writeFloat32(1.23);
        writer2.writeFloat32(4.56);

        final bytes1 = writer1.takeBytes();
        final bytes2 = writer2.takeBytes();

        final reader1 = BinaryReader(bytes1);
        final reader2 = BinaryReader(bytes2);

        expect(reader1.readFloat32(), closeTo(1.23, 0.01));
        expect(reader2.readFloat32(), closeTo(4.56, 0.01));
      });

      test('concurrent writers produce independent results', () {
        final writer1 = BinaryWriter();
        final writer2 = BinaryWriter();

        writer1.writeUint32(0x11111111);
        writer2.writeUint32(0x22222222);
        writer1.writeFloat64(3.14159);
        writer2.writeFloat64(2.71828);

        final bytes1 = writer1.takeBytes();
        final bytes2 = writer2.takeBytes();

        expect(bytes1.length, equals(12));
        expect(bytes2.length, equals(12));

        final reader1 = BinaryReader(bytes1);
        final reader2 = BinaryReader(bytes2);

        expect(reader1.readUint32(), equals(0x11111111));
        expect(reader2.readUint32(), equals(0x22222222));
        expect(reader1.readFloat64(), closeTo(3.14159, 0.00001));
        expect(reader2.readFloat64(), closeTo(2.71828, 0.00001));
      });
    });

    group('State preservation advanced', () {
      test('toBytes does not affect subsequent writes', () {
        writer.writeUint32(0x12345678);
        final snapshot1 = writer.toBytes();

        writer.writeUint32(0xABCDEF00);
        final snapshot2 = writer.toBytes();

        expect(snapshot1.length, equals(4));
        expect(snapshot2.length, equals(8));

        final reader1 = BinaryReader(snapshot1);
        final reader2 = BinaryReader(snapshot2);

        expect(reader1.readUint32(), equals(0x12345678));
        expect(reader2.readUint32(), equals(0x12345678));
        expect(reader2.readUint32(), equals(0xABCDEF00));
      });

      test('multiple toBytes calls return equivalent data', () {
        writer
          ..writeUint16(100)
          ..writeUint16(200)
          ..writeUint16(300);

        final snap1 = writer.toBytes();
        final snap2 = writer.toBytes();
        final snap3 = writer.toBytes();

        expect(snap1, equals(snap2));
        expect(snap2, equals(snap3));
      });

      test('reset after toBytes properly clears buffer', () {
        writer
          ..writeUint64(1234567890123456) // Safe for JS: < 2^53
          ..toBytes()
          ..reset();
        expect(writer.bytesWritten, equals(0));
        expect(writer.toBytes(), isEmpty);

        writer.writeUint8(42);
        expect(writer.toBytes(), equals([42]));
      });
    });

    group('Complex integration scenarios', () {
      test('full write-read cycle with all types and mixed endianness', () {
        writer
          ..writeUint8(255)
          ..writeInt8(-128)
          ..writeUint16(65535)
          ..writeInt16(-32768, .little)
          ..writeUint32(4294967295, .little)
          ..writeInt32(-2147483648)
          ..writeUint64(9223372036854775807)
          ..writeInt64(-9223372036854775808, .little)
          ..writeFloat32(3.14159, .little)
          ..writeFloat64(2.718281828)
          ..writeString('Hello, 世界! 🌍')
          ..writeBytes([1, 2, 3, 4, 5]);

        final bytes = writer.takeBytes();
        final reader = BinaryReader(bytes);

        expect(reader.readUint8(), equals(255));
        expect(reader.readInt8(), equals(-128));
        expect(reader.readUint16(), equals(65535));
        expect(reader.readInt16(.little), equals(-32768));
        expect(reader.readUint32(.little), equals(4294967295));
        expect(reader.readInt32(), equals(-2147483648));
        expect(reader.readUint64(), equals(9223372036854775807));
        expect(reader.readInt64(.little), equals(-9223372036854775808));
        expect(reader.readFloat32(.little), closeTo(3.14159, 0.00001));
        expect(reader.readFloat64(), closeTo(2.718281828, 0.000000001));

        reader.skip(reader.availableBytes - 5);
        expect(reader.readBytes(5), equals([1, 2, 3, 4, 5]));
      });

      test('writer reuse with takeBytes between operations', () {
        writer
          ..writeUint32(100)
          ..writeString('First');
        final bytes1 = writer.takeBytes();

        writer
          ..writeUint32(200)
          ..writeString('Second');
        final bytes2 = writer.takeBytes();

        writer
          ..writeUint32(300)
          ..writeString('Third');
        final bytes3 = writer.takeBytes();

        var reader = BinaryReader(bytes1);
        expect(reader.readUint32(), equals(100));

        reader = BinaryReader(bytes2);
        expect(reader.readUint32(), equals(200));

        reader = BinaryReader(bytes3);
        expect(reader.readUint32(), equals(300));
      });

      test('large mixed data write with buffer expansions', () {
        final writer = BinaryWriter(initialBufferSize: 32);

        for (var i = 0; i < 100; i++) {
          writer
            ..writeUint8(i % 256)
            ..writeUint16(i * 2)
            ..writeUint32(i * 1000)
            ..writeFloat32(i * 1.5);
        }

        writer.writeString('Final string at the end');

        final bytes = writer.takeBytes();
        expect(bytes.length, greaterThan(32));
        expect(bytes.length, greaterThan(1000));

        final reader = BinaryReader(bytes);
        expect(reader.readUint8(), equals(0));
        expect(reader.readUint16(), equals(0));
        expect(reader.readUint32(), equals(0));
        expect(reader.readFloat32(), closeTo(0, 0.01));
      });
    });

    group('Memory efficiency', () {
      test('takeBytes creates view not copy', () {
        writer.writeUint32(0x12345678);
        final bytes = writer.takeBytes();

        expect(bytes, isA<Uint8List>());
        expect(bytes.length, equals(4));
      });

      test('toBytes creates view not copy', () {
        writer.writeUint64(9876543210123); // Safe for JS: < 2^53
        final bytes = writer.toBytes();

        expect(bytes, isA<Uint8List>());
        expect(bytes.length, equals(8));
      });

      test('buffer only grows when necessary', () {
        final writer = BinaryWriter(initialBufferSize: 100);

        for (var i = 0; i < 50; i++) {
          writer.writeUint8(i);
        }

        expect(writer.bytesWritten, equals(50));
        final bytes = writer.toBytes();
        expect(bytes.length, equals(50));
      });
    });

    group('VarBytes operations', () {
      test('writeVarBytes with empty array', () {
        final writer = BinaryWriter()..writeVarBytes([]);
        final bytes = writer.takeBytes();

        expect(bytes, equals([0])); // Just length 0
      });

      test('writeVarBytes with small array', () {
        final writer = BinaryWriter()..writeVarBytes([1, 2, 3, 4]);
        final bytes = writer.takeBytes();

        expect(bytes[0], equals(4)); // VarUint length
        expect(bytes.sublist(1), equals([1, 2, 3, 4]));
      });

      test('writeVarBytes with 127 bytes (single-byte VarUint)', () {
        final writer = BinaryWriter();
        final data = List.generate(127, (i) => i);
        writer.writeVarBytes(data);
        final bytes = writer.takeBytes();

        expect(bytes[0], equals(127)); // Single-byte VarUint
        expect(bytes.length, equals(128)); // 1 (length) + 127 (data)
      });

      test('writeVarBytes with 128 bytes (two-byte VarUint)', () {
        final writer = BinaryWriter();
        final data = List.generate(128, (i) => i & 0xFF);
        writer.writeVarBytes(data);
        final bytes = writer.takeBytes();

        expect(bytes[0], equals(0x80)); // First byte of VarUint 128
        expect(bytes[1], equals(0x01)); // Second byte of VarUint 128
        expect(bytes.length, equals(130)); // 2 (length) + 128 (data)
      });

      test('writeVarBytes with large array', () {
        final writer = BinaryWriter();
        final data = List.generate(1000, (i) => (i * 7) & 0xFF);
        writer.writeVarBytes(data);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        final length = reader.readVarUint();
        expect(length, equals(1000));

        final readData = reader.readBytes(1000);
        expect(readData, equals(data));
      });

      test('writeVarBytes multiple arrays', () {
        final writer = BinaryWriter()
          ..writeVarBytes([1, 2])
          ..writeVarBytes([3, 4, 5])
          ..writeVarBytes([6]);

        final reader = BinaryReader(writer.toBytes());
        expect(reader.readVarBytes(), equals([1, 2]));
        expect(reader.readVarBytes(), equals([3, 4, 5]));
        expect(reader.readVarBytes(), equals([6]));
      });

      test('writeVarBytes round-trip', () {
        final writer = BinaryWriter();
        final original = List.generate(256, (i) => i);
        writer.writeVarBytes(original);

        final reader = BinaryReader(writer.takeBytes());
        final result = reader.readVarBytes();

        expect(result, equals(original));
      });
    });

    group('VarString operations', () {
      test('writeVarString with ASCII string', () {
        final writer = BinaryWriter()..writeVarString('Hello');
        final bytes = writer.takeBytes();

        expect(bytes[0], equals(5)); // VarUint length
        expect(bytes.sublist(1), equals([72, 101, 108, 108, 111])); // 'Hello'
      });

      test('writeVarString with UTF-8 multi-byte characters', () {
        final writer = BinaryWriter()
          ..writeVarString('世界'); // 2 characters, 6 bytes in UTF-8
        final bytes = writer.takeBytes();

        expect(bytes[0], equals(6)); // VarUint length (6 bytes)
        expect(bytes.length, equals(7)); // 1 (length) + 6 (data)
      });

      test('writeVarString with emoji', () {
        final writer = BinaryWriter()
          ..writeVarString('🌍'); // 1 character, 4 bytes in UTF-8
        final bytes = writer.takeBytes();

        expect(bytes[0], equals(4)); // VarUint length
        expect(bytes.length, equals(5)); // 1 (length) + 4 (data)
      });

      test('writeVarString with empty string', () {
        final writer = BinaryWriter()..writeVarString('');
        final bytes = writer.takeBytes();

        expect(bytes, equals([0])); // Just length 0
      });

      test('writeVarString with mixed content', () {
        final writer = BinaryWriter()..writeVarString('Hi 世界 🌍!');
        final bytes = writer.takeBytes();

        // 'Hi ' = 3, '世界' = 6, ' ' = 1, '🌍' = 4, '!' = 1 => 15 bytes
        expect(bytes[0], equals(15)); // VarUint length
        expect(bytes.length, equals(16)); // 1 + 15
      });

      test('writeVarString round-trip with reader', () {
        final writer = BinaryWriter();
        const testString = 'Test 测试 🎉';
        writer.writeVarString(testString);

        final reader = BinaryReader(writer.toBytes());
        final result = reader.readVarString();

        expect(result, equals(testString));
      });

      test('writeVarString with malformed handling', () {
        final writer = BinaryWriter();
        // Lone high surrogate (U+D800)
        final malformed = String.fromCharCode(0xD800);

        // Default allowMalformed=true should handle it
        expect(
          () => writer.writeVarString(malformed),
          returnsNormally,
        );
      });
    });

    group('getUtf8Length function', () {
      test('with ASCII only', () {
        expect(getUtf8Length('Hello'), equals(5));
        expect(getUtf8Length('ABCDEFGH'), equals(8)); // Fast path
      });

      test('with empty string', () {
        expect(getUtf8Length(''), equals(0));
      });

      test('with 2-byte UTF-8 chars', () {
        expect(getUtf8Length('café'), equals(5)); // 'caf' = 3, 'é' = 2
        expect(getUtf8Length('Привет'), equals(12)); // Each Cyrillic = 2 bytes
      });

      test('with 3-byte UTF-8 chars', () {
        expect(getUtf8Length('世界'), equals(6)); // Each Chinese = 3 bytes
        expect(getUtf8Length('你好'), equals(6));
      });

      test('with 4-byte UTF-8 chars (emoji)', () {
        expect(getUtf8Length('🌍'), equals(4));
        expect(getUtf8Length('🎉'), equals(4));
        expect(getUtf8Length('😀'), equals(4));
      });

      test('with mixed content', () {
        // 'Hello' = 5, ', ' = 2, '世界' = 6, '! ' = 2, '🌍' = 4
        expect(getUtf8Length('Hello, 世界! 🌍'), equals(19));
      });

      test('matches actual UTF-8 encoding', () {
        final strings = [
          'Test',
          'Тест',
          '测试',
          '🧪',
          'Mix テスト 123',
          'A' * 100, // Long ASCII for fast path
        ];

        for (final str in strings) {
          final calculated = getUtf8Length(str);
          final actual = utf8.encode(str).length;
          expect(
            calculated,
            equals(actual),
            reason: 'Failed for string: "$str"',
          );
        }
      });

      test('with surrogate pairs', () {
        // Valid surrogate pair forms emoji
        final emoji = String.fromCharCodes([0xD83C, 0xDF0D]); // 🌍
        expect(getUtf8Length(emoji), equals(4));
      });

      test('with malformed high surrogate', () {
        // High surrogate (0xD800-0xDBFF) not followed by low surrogate
        // This triggers the malformed surrogate pair path in getUtf8Length
        final malformed = String.fromCharCodes([
          0xD800,
          0x0041,
        ]); // High surrogate + 'A'
        expect(
          getUtf8Length(malformed),
          equals(4),
        ); // 3 bytes (replacement) + 1 byte (A)
      });

      test('with lone high surrogate at end', () {
        // High surrogate at the end of string (also malformed)
        final malformed = String.fromCharCodes([
          0x0041,
          0xD800,
        ]); // 'A' + high surrogate
        expect(
          getUtf8Length(malformed),
          equals(4),
        ); // 1 byte (A) + 3 bytes (replacement)
      });
    });

    group('Special UTF-8 cases', () {
      test('writeString with only ASCII (fast path)', () {
        const str = 'OnlyASCII123';
        writer.writeString(str);
        final bytes = writer.takeBytes();

        expect(bytes.length, equals(str.length));
      });

      test('writeString with mixed ASCII and multi-byte', () {
        const str = 'ASCII_Юникод_中文';
        writer.writeString(str);
        final bytes = writer.takeBytes();

        expect(bytes.length, greaterThan(str.length));
        final reader = BinaryReader(bytes);
        expect(reader.readString(bytes.length), equals(str));
      });

      test('writeString with only 4-byte characters (emojis)', () {
        const str = '🚀🌟💻🎉🔥';
        writer.writeString(str);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readString(bytes.length), equals(str));
      });

      test('writeString empty string after previous writes', () {
        writer
          ..writeUint8(42)
          ..writeString('')
          ..writeUint8(43);

        final bytes = writer.takeBytes();
        expect(bytes, equals([42, 43]));
      });
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

      test('writes multiple boolean values correctly', () {
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

      test('updates bytesWritten correctly', () {
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
          ..writeUint16(1000)
          ..writeBool(false)
          ..writeInt32(-500);

        final bytes = writer.takeBytes();
        final reader = BinaryReader(bytes);

        expect(reader.readUint8(), equals(42));
        expect(reader.readBool(), isTrue);
        expect(reader.readUint16(), equals(1000));
        expect(reader.readBool(), isFalse);
        expect(reader.readInt32(), equals(-500));
      });

      test('expands buffer when needed', () {
        // Write many booleans to trigger buffer expansion
        for (var i = 0; i < 200; i++) {
          writer.writeBool(i.isEven);
        }

        final bytes = writer.takeBytes();
        expect(bytes.length, equals(200));

        final reader = BinaryReader(bytes);
        for (var i = 0; i < 200; i++) {
          expect(reader.readBool(), equals(i.isEven));
        }
      });

      test('resets correctly after takeBytes', () {
        writer
          ..writeBool(true)
          ..takeBytes()
          ..writeBool(false);
        expect(writer.takeBytes(), equals([0x00]));
      });

      test('works correctly with toBytes', () {
        writer.writeBool(true);
        final snapshot1 = writer.toBytes();
        expect(snapshot1, equals([0x01]));

        writer.writeBool(false);
        final snapshot2 = writer.toBytes();
        expect(snapshot2, equals([0x01, 0x00]));
      });

      test('works correctly with reset', () {
        writer
          ..writeBool(true)
          ..writeBool(false)
          ..reset()
          ..writeBool(false)
          ..writeBool(true);

        expect(writer.toBytes(), equals([0x00, 0x01]));
      });
    });
  });
}
