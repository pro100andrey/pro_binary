import 'dart:typed_data';

import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('BinaryReader Basic Operations', () {
    test('reads Uint8 correctly', () {
      final buffer = Uint8List.fromList([0x01]);
      final reader = BinaryReader(buffer);
      expect(reader.readUint8(), equals(1));
      expect(reader.availableBytes, equals(0));
    });

    test('reads Int8 correctly', () {
      final buffer = Uint8List.fromList([0xFF]);
      final reader = BinaryReader(buffer);
      expect(reader.readInt8(), equals(-1));
      expect(reader.availableBytes, equals(0));
    });

    test('reads Uint16 in big-endian', () {
      final buffer = Uint8List.fromList([0x01, 0x00]);
      final reader = BinaryReader(buffer);
      expect(reader.readUint16(), equals(256));
    });

    test('reads Uint16 in little-endian', () {
      final buffer = Uint8List.fromList([0x00, 0x01]);
      final reader = BinaryReader(buffer);
      expect(reader.readUint16(.little), equals(256));
    });

    test('reads Uint32 correctly', () {
      final buffer = Uint8List.fromList([0x00, 0x01, 0x00, 0x00]);
      final reader = BinaryReader(buffer);
      expect(reader.readUint32(), equals(65536));
    });

    test('reads Uint64 correctly', () {
      final buffer = Uint8List.fromList([0, 0, 0, 1, 0, 0, 0, 0]);
      final reader = BinaryReader(buffer);
      expect(reader.readUint64(), equals(4294967296));
    });

    test('reads Float32 correctly', () {
      final buffer = Uint8List.fromList([0x40, 0x49, 0x0F, 0xDB]);
      final reader = BinaryReader(buffer);
      expect(reader.readFloat32(), closeTo(3.1415927, 0.0000001));
    });

    test('reads Float64 correctly', () {
      final buffer = Uint8List.fromList([
        0x40,
        0x09,
        0x21,
        0xFB,
        0x54,
        0x44,
        0x2D,
        0x18,
      ]);
      final reader = BinaryReader(buffer);
      expect(
        reader.readFloat64(),
        closeTo(3.141592653589793, 0.000000000000001),
      );
    });

    test('readBool correctly', () {
      final buffer = Uint8List.fromList([0x01, 0x00]);
      final reader = BinaryReader(buffer);
      expect(reader.readBool(), isTrue);
      expect(reader.readBool(), isFalse);
    });

    test('availableBytes returns correct number', () {
      final buffer = Uint8List.fromList([1, 2, 3]);
      final reader = BinaryReader(buffer);
      expect(reader.availableBytes, equals(3));
      reader.readUint8();
      expect(reader.availableBytes, equals(2));
    });

    test('offset returns current position', () {
      final buffer = Uint8List.fromList([1, 2, 3]);
      final reader = BinaryReader(buffer);
      expect(reader.offset, equals(0));
      reader.readUint8();
      expect(reader.offset, equals(1));
    });
  });
}
