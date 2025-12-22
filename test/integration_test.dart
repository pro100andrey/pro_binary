import 'dart:convert';
import 'dart:typed_data';

import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('Integration Tests - BinaryReader and BinaryWriter', () {
    group('Basic read-write cycles', () {
      test('write and read single Uint8', () {
        final writer = BinaryWriter();
        const value = 42;

        writer.writeUint8(value);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readUint8(), equals(value));
        expect(reader.availableBytes, equals(0));
      });

      test('write and read single Int8', () {
        final writer = BinaryWriter();
        const value = -42;

        writer.writeInt8(value);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readInt8(), equals(value));
      });

      test('write and read Uint16 with big-endian', () {
        final writer = BinaryWriter();
        const value = 65535;

        writer.writeUint16(value);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readUint16(), equals(value));
      });

      test('write and read Uint16 with little-endian', () {
        final writer = BinaryWriter();
        const value = 65535;

        writer.writeUint16(value, .little);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readUint16(.little), equals(value));
      });

      test('write and read Int16 with big-endian', () {
        final writer = BinaryWriter();
        const value = -32768;

        writer.writeInt16(value);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readInt16(), equals(value));
      });

      test('write and read Int16 with little-endian', () {
        final writer = BinaryWriter();
        const value = -32768;

        writer.writeInt16(value, .little);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readInt16(.little), equals(value));
      });

      test('write and read Uint32 with big-endian', () {
        final writer = BinaryWriter();
        const value = 4294967295;

        writer.writeUint32(value);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readUint32(), equals(value));
      });

      test('write and read Uint32 with little-endian', () {
        final writer = BinaryWriter();
        const value = 4294967295;

        writer.writeUint32(value, .little);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readUint32(.little), equals(value));
      });

      test('write and read Int32 with big-endian', () {
        final writer = BinaryWriter();
        const value = -2147483648;

        writer.writeInt32(value);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readInt32(), equals(value));
      });

      test('write and read Int32 with little-endian', () {
        final writer = BinaryWriter();
        const value = -2147483648;

        writer.writeInt32(value, .little);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readInt32(.little), equals(value));
      });

      test('write and read Uint64 with big-endian', () {
        final writer = BinaryWriter();
        const value = 9223372036854775807;

        writer.writeUint64(value);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readUint64(), equals(value));
      });

      test('write and read Uint64 with little-endian', () {
        final writer = BinaryWriter();
        const value = 9223372036854775807;

        writer.writeUint64(value, .little);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readUint64(.little), equals(value));
      });

      test('write and read Int64 with big-endian', () {
        final writer = BinaryWriter();
        const value = -9223372036854775808;

        writer.writeInt64(value);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readInt64(), equals(value));
      });

      test('write and read Int64 with little-endian', () {
        final writer = BinaryWriter();
        const value = -9223372036854775808;

        writer.writeInt64(value, .little);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readInt64(.little), equals(value));
      });

      test('write and read Float32 with big-endian', () {
        final writer = BinaryWriter();
        const value = 3.14159;

        writer.writeFloat32(value);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readFloat32(), closeTo(value, 0.00001));
      });

      test('write and read Float32 with little-endian', () {
        final writer = BinaryWriter();
        const value = 3.14159;

        writer.writeFloat32(value, .little);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readFloat32(.little), closeTo(value, 0.00001));
      });

      test('write and read Float64 with big-endian', () {
        final writer = BinaryWriter();
        const value = 3.141592653589793;

        writer.writeFloat64(value);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readFloat64(), closeTo(value, 0.000000000000001));
      });

      test('write and read Float64 with little-endian', () {
        final writer = BinaryWriter();
        const value = 3.141592653589793;

        writer.writeFloat64(value, .little);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(
          reader.readFloat64(.little),
          closeTo(value, 0.000000000000001),
        );
      });
    });

    group('Complex data structures', () {
      test('write and read sequence of different types', () {
        final writer = BinaryWriter()
          ..writeUint8(255)
          ..writeInt8(-128)
          ..writeUint16(65535)
          ..writeInt16(-32768)
          ..writeUint32(4294967295)
          ..writeInt32(-2147483648)
          ..writeUint64(9223372036854775807)
          ..writeInt64(-9223372036854775808)
          ..writeFloat32(1.5)
          ..writeFloat64(2.718281828);

        final bytes = writer.takeBytes();
        final reader = BinaryReader(bytes);

        expect(reader.readUint8(), equals(255));
        expect(reader.readInt8(), equals(-128));
        expect(reader.readUint16(), equals(65535));
        expect(reader.readInt16(), equals(-32768));
        expect(reader.readUint32(), equals(4294967295));
        expect(reader.readInt32(), equals(-2147483648));
        expect(reader.readUint64(), equals(9223372036854775807));
        expect(reader.readInt64(), equals(-9223372036854775808));
        expect(reader.readFloat32(), closeTo(1.5, 0.01));
        expect(reader.readFloat64(), closeTo(2.718281828, 0.000000001));
        expect(reader.availableBytes, equals(0));
      });

      test('write and read with mixed endianness', () {
        final writer = BinaryWriter()
          ..writeUint16(0x1234)
          ..writeUint16(0x5678, .little)
          ..writeUint32(0x9ABCDEF0)
          ..writeUint32(0x11223344, .little)
          ..writeFloat32(3.14)
          ..writeFloat32(2.71, .little)
          ..writeFloat64(1.414)
          ..writeFloat64(1.732, .little);

        final bytes = writer.takeBytes();
        final reader = BinaryReader(bytes);

        expect(reader.readUint16(), equals(0x1234));
        expect(reader.readUint16(.little), equals(0x5678));
        expect(reader.readUint32(), equals(0x9ABCDEF0));
        expect(reader.readUint32(.little), equals(0x11223344));
        expect(reader.readFloat32(), closeTo(3.14, 0.01));
        expect(reader.readFloat32(.little), closeTo(2.71, 0.01));
        expect(reader.readFloat64(), closeTo(1.414, 0.001));
        expect(reader.readFloat64(.little), closeTo(1.732, 0.001));
      });

      test('write and read bytes array', () {
        final writer = BinaryWriter();
        final data = Uint8List.fromList([1, 2, 3, 4, 5, 100, 200, 255]);

        writer.writeBytes(data);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        final readData = reader.readBytes(data.length);

        expect(readData, equals(data));
        expect(reader.availableBytes, equals(0));
      });

      test('write and read string in UTF-8', () {
        final writer = BinaryWriter();
        const str = 'Hello, World!';

        writer.writeString(str);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        final result = reader.readString(bytes.length);

        expect(result, equals(str));
      });

      test('write and read multi-byte UTF-8 string', () {
        final writer = BinaryWriter();
        const str = 'Привет, мир! 你好世界 🚀';

        writer.writeString(str);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        final result = reader.readString(bytes.length);

        expect(result, equals(str));
      });

      test('write and read alternating string and numeric data', () {
        final writer = BinaryWriter()
          ..writeString('Start')
          ..writeUint32(42)
          ..writeString('Middle')
          ..writeFloat64(3.14159)
          ..writeString('End');

        final bytes = writer.takeBytes();
        final reader = BinaryReader(bytes);

        expect(reader.readString(5), equals('Start'));
        expect(reader.readUint32(), equals(42));
        expect(reader.readString(6), equals('Middle'));
        expect(reader.readFloat64(), closeTo(3.14159, 0.00001));
        expect(reader.readString(3), equals('End'));
        expect(reader.availableBytes, equals(0));
      });

      test('write and read nested numeric values', () {
        final writer = BinaryWriter();
        final values = [
          255,
          127,
          65535,
          32767,
          4294967295,
          2147483647,
          9223372036854775807,
        ];

        for (final _ in values) {
          writer
            ..writeUint8(255)
            ..writeInt8(127)
            ..writeUint16(65535)
            ..writeInt16(32767)
            ..writeUint32(4294967295)
            ..writeInt32(2147483647)
            ..writeUint64(9223372036854775807);
        }

        final bytes = writer.takeBytes();
        final reader = BinaryReader(bytes);

        for (var i = 0; i < values.length; i++) {
          expect(reader.readUint8(), equals(255));
          expect(reader.readInt8(), equals(127));
          expect(reader.readUint16(), equals(65535));
          expect(reader.readInt16(), equals(32767));
          expect(reader.readUint32(), equals(4294967295));
          expect(reader.readInt32(), equals(2147483647));
          expect(reader.readUint64(), equals(9223372036854775807));
        }

        expect(reader.availableBytes, equals(0));
      });
    });

    group('String handling integration', () {
      test('write and read ASCII strings', () {
        final writer = BinaryWriter();
        const str = 'ASCII123!@#';

        writer.writeString(str);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readString(bytes.length), equals(str));
      });

      test('write and read Cyrillic strings', () {
        final writer = BinaryWriter();
        const str = 'Привет, мир!';

        writer.writeString(str);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readString(bytes.length), equals(str));
      });

      test('write and read Chinese characters', () {
        final writer = BinaryWriter();
        const str = '你好世界';

        writer.writeString(str);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readString(bytes.length), equals(str));
      });

      test('write and read emoji characters', () {
        final writer = BinaryWriter();
        const str = '🚀🌟💻🎉🔥';

        writer.writeString(str);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readString(bytes.length), equals(str));
      });

      test('write and read mixed Unicode string', () {
        final writer = BinaryWriter();
        const str = 'ASCII_Юникод_中文_🌍';

        writer.writeString(str);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readString(bytes.length), equals(str));
      });

      test('write and read empty string', () {
        final writer = BinaryWriter()..writeString('');
        final bytes = writer.takeBytes();

        expect(bytes, isEmpty);
      });

      test('write multiple strings and read them back', () {
        final writer = BinaryWriter();
        final strings = ['Hello', 'Привет', '你好', '🌍']
          ..forEach(writer.writeString);

        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        for (final str in strings) {
          final strBytes = utf8.encode(str);
          final readStr = reader.readString(strBytes.length);
          expect(readStr, equals(str));
        }

        expect(reader.availableBytes, equals(0));
      });
    });

    group('Float special values', () {
      test('write and read Float32 NaN', () {
        final writer = BinaryWriter()..writeFloat32(double.nan);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readFloat32().isNaN, isTrue);
      });

      test('write and read Float32 positive Infinity', () {
        final writer = BinaryWriter()..writeFloat32(double.infinity);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readFloat32(), equals(double.infinity));
      });

      test('write and read Float32 negative Infinity', () {
        final writer = BinaryWriter()..writeFloat32(double.negativeInfinity);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readFloat32(), equals(double.negativeInfinity));
      });

      test('write and read Float64 NaN', () {
        final writer = BinaryWriter()..writeFloat64(double.nan);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readFloat64().isNaN, isTrue);
      });

      test('write and read Float64 positive Infinity', () {
        final writer = BinaryWriter()..writeFloat64(double.infinity);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readFloat64(), equals(double.infinity));
      });

      test('write and read Float64 negative Infinity', () {
        final writer = BinaryWriter()..writeFloat64(double.negativeInfinity);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readFloat64(), equals(double.negativeInfinity));
      });

      test('write and read Float64 negative zero', () {
        final writer = BinaryWriter()..writeFloat64(-0);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        final value = reader.readFloat64();
        expect(value, equals(0.0));
        expect(value.isNegative, isTrue);
      });

      test(
        'write and read multiple special float values together',
        () {
          final writer = BinaryWriter()
            ..writeFloat32(double.nan)
            ..writeFloat32(double.infinity)
            ..writeFloat32(double.negativeInfinity)
            ..writeFloat64(double.nan)
            ..writeFloat64(double.infinity)
            ..writeFloat64(double.negativeInfinity);

          final bytes = writer.takeBytes();
          final reader = BinaryReader(bytes);

          expect(reader.readFloat32().isNaN, isTrue);
          expect(reader.readFloat32(), equals(double.infinity));
          expect(reader.readFloat32(), equals(double.negativeInfinity));
          expect(reader.readFloat64().isNaN, isTrue);
          expect(reader.readFloat64(), equals(double.infinity));
          expect(reader.readFloat64(), equals(double.negativeInfinity));
        },
      );
    });

    group('Reader operations after write', () {
      test('peek and then read same bytes', () {
        final writer = BinaryWriter()..writeBytes([1, 2, 3, 4, 5]);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        final peeked = reader.peekBytes(3);
        final read = reader.readBytes(3);

        expect(peeked, equals(read));
        expect(peeked, equals([1, 2, 3]));
      });

      test('skip and then read remaining bytes', () {
        final writer = BinaryWriter()
          ..writeBytes([1, 2, 3, 4, 5])
          ..writeUint32(42);

        final bytes = writer.takeBytes();
        final reader = BinaryReader(bytes)..skip(5);
        expect(reader.readUint32(), equals(42));
      });

      test('reset reader after partial read', () {
        final writer = BinaryWriter()
          ..writeUint32(100)
          ..writeUint32(200)
          ..writeUint32(300);

        final bytes = writer.takeBytes();
        final reader = BinaryReader(bytes);

        expect(reader.readUint32(), equals(100));
        expect(reader.usedBytes, equals(4));

        reader.reset();
        expect(reader.usedBytes, equals(0));
        expect(reader.readUint32(), equals(100));
      });

      test('offset tracking during read', () {
        final writer = BinaryWriter()
          ..writeUint8(1)
          ..writeUint16(2)
          ..writeUint32(3);

        final bytes = writer.takeBytes();
        final reader = BinaryReader(bytes);

        expect(reader.offset, equals(0));
        reader.readUint8();
        expect(reader.offset, equals(1));
        reader.readUint16();
        expect(reader.offset, equals(3));
        reader.readUint32();
        expect(reader.offset, equals(7));
      });

      test('availableBytes tracking', () {
        final writer = BinaryWriter()
          ..writeUint8(1)
          ..writeUint8(2)
          ..writeUint8(3)
          ..writeUint8(4);

        final bytes = writer.takeBytes();
        final reader = BinaryReader(bytes);

        expect(reader.availableBytes, equals(4));
        reader.readUint8();
        expect(reader.availableBytes, equals(3));
        reader.readUint8();
        expect(reader.availableBytes, equals(2));
        reader.readUint16();
        expect(reader.availableBytes, equals(0));
      });
    });

    group('Large data cycles', () {
      test('write and read large byte array', () {
        const size = 100000;
        final writer = BinaryWriter();
        final data = Uint8List(size);
        for (var i = 0; i < size; i++) {
          data[i] = i % 256;
        }

        writer.writeBytes(data);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        final readData = reader.readBytes(size);

        expect(readData.length, equals(size));
        for (var i = 0; i < size; i++) {
          expect(readData[i], equals(i % 256));
        }
      });

      test('write and read many numeric values', () {
        const count = 1000;
        final writer = BinaryWriter();

        for (var i = 0; i < count; i++) {
          writer
            ..writeUint8(i % 256)
            ..writeUint16(i * 2)
            ..writeUint32(i * 1000);
        }

        final bytes = writer.takeBytes();
        final reader = BinaryReader(bytes);

        for (var i = 0; i < count; i++) {
          expect(reader.readUint8(), equals(i % 256));
          expect(reader.readUint16(), equals(i * 2));
          expect(reader.readUint32(), equals(i * 1000));
        }

        expect(reader.availableBytes, equals(0));
      });

      test('write and read very long string', () {
        final writer = BinaryWriter();
        final longString = 'A' * 50000;

        writer.writeString(longString);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        final result = reader.readString(bytes.length);

        expect(result, equals(longString));
        expect(result.length, equals(50000));
      });
    });

    group('Writer buffer management integration', () {
      test('write causes buffer expansion and can be read correctly', () {
        final writer = BinaryWriter(initialBufferSize: 4);

        for (var i = 0; i < 100; i++) {
          writer.writeUint8(i % 256);
        }

        final bytes = writer.takeBytes();
        final reader = BinaryReader(bytes);

        for (var i = 0; i < 100; i++) {
          expect(reader.readUint8(), equals(i % 256));
        }
      });

      test('use toBytes and continue writing', () {
        final writer = BinaryWriter()..writeUint32(100);

        final bytes1 = writer.toBytes();
        expect(bytes1.length, equals(4));

        writer.writeUint32(200);
        final bytes2 = writer.toBytes();
        expect(bytes2.length, equals(8));

        final reader = BinaryReader(bytes2);
        expect(reader.readUint32(), equals(100));
        expect(reader.readUint32(), equals(200));
      });

      test('takeBytes resets and new writes start fresh', () {
        final writer = BinaryWriter()..writeUint32(100);
        final bytes1 = writer.takeBytes();

        expect(bytes1.length, equals(4));

        writer.writeUint32(200);
        final bytes2 = writer.takeBytes();

        expect(bytes2.length, equals(4));

        final reader = BinaryReader(bytes2);
        expect(reader.readUint32(), equals(200));
      });

      test('reset clears buffer and can write new data', () {
        final writer = BinaryWriter()
          ..writeUint32(100)
          ..reset()
          ..writeUint32(200);
        final bytes = writer.takeBytes();

        final reader = BinaryReader(bytes);
        expect(reader.readUint32(), equals(200));
      });
    });

    group('Round-trip validation', () {
      test(
        'all types round-trip correctly with big-endian',
        () {
          final writer = BinaryWriter()
            ..writeUint8(255)
            ..writeInt8(-128)
            ..writeUint16(65535)
            ..writeInt16(-32768)
            ..writeUint32(4294967295)
            ..writeInt32(-2147483648)
            ..writeUint64(9223372036854775807)
            ..writeInt64(-9223372036854775808)
            ..writeFloat32(1.23456)
            ..writeFloat64(1.2345678901234)
            ..writeString('Test')
            ..writeBytes([1, 2, 3]);

          final bytes = writer.takeBytes();
          final reader = BinaryReader(bytes);

          expect(reader.readUint8(), equals(255));
          expect(reader.readInt8(), equals(-128));
          expect(reader.readUint16(), equals(65535));
          expect(reader.readInt16(), equals(-32768));
          expect(reader.readUint32(), equals(4294967295));
          expect(reader.readInt32(), equals(-2147483648));
          expect(reader.readUint64(), equals(9223372036854775807));
          expect(reader.readInt64(), equals(-9223372036854775808));
          expect(reader.readFloat32(), closeTo(1.23456, 0.00001));
          expect(reader.readFloat64(), closeTo(1.2345678901234, 0.0000001));
          expect(reader.readString(4), equals('Test'));
          expect(reader.readBytes(3), equals([1, 2, 3]));
          expect(reader.availableBytes, equals(0));
        },
      );

      test(
        'all types round-trip correctly with little-endian',
        () {
          final writer = BinaryWriter()
            ..writeUint16(65535, .little)
            ..writeInt16(-32768, .little)
            ..writeUint32(4294967295, .little)
            ..writeInt32(-2147483648, .little)
            ..writeUint64(9223372036854775807, .little)
            ..writeInt64(-9223372036854775808, .little)
            ..writeFloat32(1.23456, .little)
            ..writeFloat64(1.2345678901234, .little);

          final bytes = writer.takeBytes();
          final reader = BinaryReader(bytes);

          expect(
            reader.readUint16(.little),
            equals(65535),
          );
          expect(
            reader.readInt16(.little),
            equals(-32768),
          );
          expect(
            reader.readUint32(.little),
            equals(4294967295),
          );
          expect(
            reader.readInt32(.little),
            equals(-2147483648),
          );
          expect(
            reader.readUint64(.little),
            equals(9223372036854775807),
          );
          expect(
            reader.readInt64(.little),
            equals(-9223372036854775808),
          );
          expect(
            reader.readFloat32(.little),
            closeTo(1.23456, 0.00001),
          );
          expect(
            reader.readFloat64(.little),
            closeTo(1.2345678901234, 0.0000001),
          );
          expect(reader.availableBytes, equals(0));
        },
      );
    });

    group('Boundary condition integration', () {
      test('write and read exactly to buffer boundary', () {
        final writer = BinaryWriter()
          ..writeUint16(0x0102)
          ..writeUint16(0x0304)
          ..writeUint16(0x0506);

        final bytes = writer.takeBytes();
        final reader = BinaryReader(bytes);

        expect(reader.readUint16(), equals(0x0102));
        expect(reader.readUint16(), equals(0x0304));
        expect(reader.readUint16(), equals(0x0506));
        expect(reader.availableBytes, equals(0));
      });

      test('write zero-length data and read correctly', () {
        final writer = BinaryWriter()
          ..writeUint8(42)
          ..writeBytes([])
          ..writeUint8(43);

        final bytes = writer.takeBytes();
        final reader = BinaryReader(bytes);

        expect(reader.readUint8(), equals(42));
        expect(reader.readUint8(), equals(43));
      });

      test('write empty string between numeric values', () {
        final writer = BinaryWriter()
          ..writeUint32(100)
          ..writeString('')
          ..writeUint32(200);

        final bytes = writer.takeBytes();
        final reader = BinaryReader(bytes);

        expect(reader.readUint32(), equals(100));
        expect(reader.readUint32(), equals(200));
      });
    });

    group('Multiple reader instances on same data', () {
      test('multiple readers read same buffer independently', () {
        final writer = BinaryWriter()
          ..writeUint32(100)
          ..writeString('Hello')
          ..writeUint32(200);

        final bytes = writer.takeBytes();

        final reader1 = BinaryReader(bytes);
        final reader2 = BinaryReader(bytes);

        expect(reader1.readUint32(), equals(100));
        expect(reader2.readUint32(), equals(100));

        final str1 = reader1.readString(5);
        reader2.skip(5);

        expect(str1, equals('Hello'));
        expect(reader1.readUint32(), equals(200));
        expect(reader2.readUint32(), equals(200));
      });
    });

    group('Stress tests', () {
      test('alternating write and read operations', () {
        final writer = BinaryWriter();

        for (var i = 0; i < 100; i++) {
          writer
            ..writeUint16(i * 2)
            ..writeString('Item$i');
        }

        final bytes = writer.takeBytes();
        final newReader = BinaryReader(bytes);

        for (var i = 0; i < 100; i++) {
          expect(newReader.readUint16(), equals(i * 2));
          final itemStr = 'Item$i';
          expect(newReader.readString(itemStr.length), equals(itemStr));
        }
      });

      test('recursive-like nested structures', () {
        final writer = BinaryWriter();

        // Simulate nested structures
        for (var i = 0; i < 10; i++) {
          writer.writeUint8(i);
          for (var j = 0; j < 5; j++) {
            writer.writeUint16(i * 100 + j);
          }
        }

        final bytes = writer.takeBytes();
        final reader = BinaryReader(bytes);

        for (var i = 0; i < 10; i++) {
          expect(reader.readUint8(), equals(i));
          for (var j = 0; j < 5; j++) {
            expect(reader.readUint16(), equals(i * 100 + j));
          }
        }
      });
    });
  });
}
