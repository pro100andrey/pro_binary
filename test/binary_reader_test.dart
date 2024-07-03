import 'dart:typed_data';

import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('BinaryReader', () {
    late BinaryReader reader;
    late Uint8List buffer;

    setUp(() {
      buffer = Uint8List.fromList([
        0x01, // Uint8 (1)
        0xFF, // Int8 (-1)
        0x01, 0x00, // Uint16 big-endian (256)
        0x00, 0x01, // Uint16 little-endian (256)
        0xFF, 0xFF, // Int16 big-endian (-1)
        0xFF, 0x7F, // Int16 little-endian (-32768)
        0x00, 0x01, 0x00, 0x00, // Uint32 big-endian (65536)
        0x00, 0x00, 0x01, 0x00, // Uint32 little-endian (65536)
        0xFF, 0xFF, 0xFF, 0xFF, // Int32 big-endian (-1)
        0xFF, 0xFF, 0xFF, 0x7F, // Int32 little-endian (-2147483648)
        0x40, 0x49, 0x0F, 0xDB, // Float32 (3.1415927) big-endian
        0xDB, 0x0F, 0x49, 0x40, // Float32 (3.1415927) little-endian
        0x40, 0x09, 0x21, 0xFB, 0x54, 0x44, 0x2D,
        0x18, // Float64 (3.141592653589793) big-endian
        0x18, 0x2D, 0x44, 0x54, 0xFB, 0x21, 0x09,
        0x40, // Float64 (3.141592653589793) little-endian
        0x01, 0x02, 0x03, 0x04, 0x05, 0x06,
        0x07, // Bytes  [1, 2, 3, 4, 5, 6, 7]
        72, 101, 108, 108, 111, 44, 32, 119, 111, 114, 108, 100,
        33, // String 'Hello, world!'
      ]);
      reader = BinaryReader(buffer);
    });

    test('readUint8', () {
      expect(reader.readUint8(), 1);
    });

    test('readInt8', () {
      reader.readUint8(); // skip first byte
      expect(reader.readInt8(), -1);
    });

    test('readUint16 big-endian', () {
      reader
        ..readUint8() // skip first byte
        ..readInt8(); // skip second byte
      expect(reader.readUint16(), 256);
    });

    test('readUint16 little-endian', () {
      reader
        ..readUint8() // skip first byte
        ..readInt8() // skip second byte
        ..readUint16(); // skip next two bytes
      expect(reader.readUint16(Endian.little), 256);
    });

    test('readInt16 big-endian', () {
      reader
        ..readUint8() // skip first byte
        ..readInt8() // skip second byte
        ..readUint16() // skip next two bytes
        ..readUint16(Endian.little); // skip next two bytes
      expect(reader.readInt16(), -1);
    });

    test('readInt16 little-endian', () {
      reader
        ..readUint8() // skip first byte
        ..readInt8() // skip second byte
        ..readUint16() // skip next two bytes
        ..readUint16(Endian.little) // skip next two bytes
        ..readInt16(); // skip next two bytes
      expect(reader.readInt16(Endian.little), 32767);
    });

    test('readUint32 big-endian', () {
      reader
        ..readUint8() // skip first byte
        ..readInt8() // skip second byte
        ..readUint16() // skip next two bytes
        ..readUint16(Endian.little) // skip next two bytes
        ..readInt16() // skip next two bytes
        ..readInt16(Endian.little); // skip next two bytes
      expect(reader.readUint32(), 65536);
    });

    test('readUint32 little-endian', () {
      reader
        ..readUint8() // skip first byte
        ..readInt8() // skip second byte
        ..readUint16() // skip next two bytes
        ..readUint16(Endian.little) // skip next two bytes
        ..readInt16() // skip next two bytes
        ..readInt16(Endian.little) // skip next two bytes
        ..readUint32(); // skip next four bytes
      expect(reader.readUint32(Endian.little), 65536);
    });

    test('readInt32 big-endian', () {
      reader
        ..readUint8() // skip first byte
        ..readInt8() // skip second byte
        ..readUint16() // skip next two bytes
        ..readUint16(Endian.little) // skip next two bytes
        ..readInt16() // skip next two bytes
        ..readInt16(Endian.little) // skip next two bytes
        ..readUint32() // skip next four bytes
        ..readUint32(Endian.little); // skip next four bytes
      expect(reader.readInt32(), -1);
    });

    test('readInt32 little-endian', () {
      reader
        ..readUint8() // skip first byte
        ..readInt8() // skip second byte
        ..readUint16() // skip next two bytes
        ..readUint16(Endian.little) // skip next two bytes
        ..readInt16() // skip next two bytes
        ..readInt16(Endian.little) // skip next two bytes
        ..readUint32() // skip next four bytes
        ..readUint32(Endian.little) // skip next four bytes
        ..readInt32(); // skip next four bytes
      expect(reader.readInt32(Endian.little), 2147483647);
    });

    test('readFloat32 big-endian', () {
      reader
        ..readUint8() // skip first byte
        ..readInt8() // skip second byte
        ..readUint16() // skip next two bytes
        ..readUint16(Endian.little) // skip next two bytes
        ..readInt16() // skip next two bytes
        ..readInt16(Endian.little) // skip next two bytes
        ..readUint32() // skip next four bytes
        ..readUint32(Endian.little) // skip next four bytes
        ..readInt32() // skip next four bytes
        ..readInt32(Endian.little); // skip next four bytes
      expect(reader.readFloat32(), closeTo(3.1415927, 0.0000001));
    });

    test('readFloat32 little-endian', () {
      reader
        ..readUint8() // skip first byte
        ..readInt8() // skip second byte
        ..readUint16() // skip next two bytes
        ..readUint16(Endian.little) // skip next two bytes
        ..readInt16() // skip next two bytes
        ..readInt16(Endian.little) // skip next two bytes
        ..readUint32() // skip next four bytes
        ..readUint32(Endian.little) // skip next four bytes
        ..readInt32() // skip next four bytes
        ..readInt32(Endian.little) // skip next four bytes
        ..readFloat32(); // skip next four bytes
      expect(reader.readFloat32(Endian.little), closeTo(3.1415927, 0.0000001));
    });

    test('readFloat64 big-endian', () {
      reader
        ..readUint8() // skip first byte
        ..readInt8() // skip second byte
        ..readUint16() // skip next two bytes
        ..readUint16(Endian.little) // skip next two bytes
        ..readInt16() // skip next two bytes
        ..readInt16(Endian.little) // skip next two bytes
        ..readUint32() // skip next four bytes
        ..readUint32(Endian.little) // skip next four bytes
        ..readInt32() // skip next four bytes
        ..readInt32(Endian.little) // skip next four bytes
        ..readFloat32() // skip next four bytes
        ..readFloat32(Endian.little); // skip next four bytes
      expect(
        reader.readFloat64(),
        closeTo(3.141592653589793, 0.000000000000001),
      );
    });

    test('readFloat64 little-endian', () {
      reader
        ..readUint8() // skip first byte
        ..readInt8() // skip second byte
        ..readUint16() // skip next two bytes
        ..readUint16(Endian.little) // skip next two bytes
        ..readInt16() // skip next two bytes
        ..readInt16(Endian.little) // skip next two bytes
        ..readUint32() // skip next four bytes
        ..readUint32(Endian.little) // skip next four bytes
        ..readInt32() // skip next four bytes
        ..readInt32(Endian.little) // skip next four bytes
        ..readFloat32() // skip next four bytes
        ..readFloat32(Endian.little) // skip next four bytes
        ..readFloat64(); // skip next eight bytes
      expect(
        reader.readFloat64(Endian.little),
        closeTo(3.141592653589793, 0.000000000000001),
      );
    });

    test('readBytes', () {
      reader
        ..readUint8() // skip first byte
        ..readInt8() // skip second byte
        ..readUint16() // skip next two bytes
        ..readUint16(Endian.little) // skip next two bytes
        ..readInt16() // skip next two bytes
        ..readInt16(Endian.little) // skip next two bytes
        ..readUint32() // skip next four bytes
        ..readUint32(Endian.little) // skip next four bytes
        ..readInt32() // skip next four bytes
        ..readInt32(Endian.little) // skip next four bytes
        ..readFloat32() // skip next four bytes
        ..readFloat32(Endian.little) // skip next four bytes
        ..readFloat64() // skip next eight bytes
        ..readFloat64(Endian.little); // skip next eight bytes
      expect(reader.readBytes(7), [0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07]);
    });

    test('readString', () {
      reader
        ..readUint8() // skip first byte
        ..readInt8() // skip second byte
        ..readUint16() // skip next two bytes
        ..readUint16(Endian.little) // skip next two bytes
        ..readInt16() // skip next two bytes
        ..readInt16(Endian.little) // skip next two bytes
        ..readUint32() // skip next four bytes
        ..readUint32(Endian.little) // skip next four bytes
        ..readInt32() // skip next four bytes
        ..readInt32(Endian.little) // skip next four bytes
        ..readFloat32() // skip next four bytes
        ..readFloat32(Endian.little) // skip next four bytes
        ..readFloat64() // skip next eight bytes
        ..readFloat64(Endian.little) // skip next eight bytes
        ..readBytes(7); // skip next seven bytes;

      expect(reader.readString(13), 'Hello, world!');
    });

    test('availableBytes returns correct number of remaining bytes', () {
      expect(reader.availableBytes, equals(70));
      reader.readUint8();
      expect(reader.availableBytes, equals(69));
      reader.readBytes(4);
      expect(reader.availableBytes, equals(65));
    });

    test('usedBytes returns correct number of used bytes', () {
      expect(reader.usedBytes, equals(0));
      reader.readUint8();
      expect(reader.usedBytes, equals(1));
      reader.readBytes(4);
      expect(reader.usedBytes, equals(5));
    });

    test('peekBytes returns correct bytes without changing the internal state',
        () {
      final peekedBytes = reader.peekBytes(5);
      expect(peekedBytes, equals([0x01, 0xFF, 0x01, 0x00, 0x00]));

      // Ensure internal state has not changed
      expect(reader.availableBytes, equals(70));
      expect(reader.usedBytes, equals(0));

      reader.readBytes(5);
      expect(reader.availableBytes, equals(65));
      expect(reader.usedBytes, equals(5));

      final peekedBytesWithOffset = reader.peekBytes(3, 5);
      expect(peekedBytesWithOffset, equals([0x01, 0xFF, 0xFF]));

      // Ensure internal state has not changed
      expect(reader.availableBytes, equals(65));
      expect(reader.usedBytes, equals(5));
    });

    test('skip method correctly updates the offset', () {
      expect(reader.usedBytes, equals(0));
      reader.skip(6);
      expect(reader.usedBytes, equals(6));
      expect(reader.readUint8(), equals(0xFF)); // should read the 6th byte
      reader.skip(10);
      expect(reader.usedBytes, equals(17));
      expect(
        reader.readUint16(),
        equals(0xFF),
      ); // should read starting from the 9th byte
    });
  });
}
