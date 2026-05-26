import 'dart:typed_data';

import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('BinaryReader Navigation', () {
    test('skip method correctly updates the offset', () {
      final buffer = Uint8List.fromList([0x00, 0x01, 0x02, 0x03, 0x04]);
      final reader = BinaryReader(buffer)..skip(2);
      expect(reader.offset, equals(2));
      expect(reader.readUint8(), equals(0x02));
    });

    test('seek method sets position correctly', () {
      final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
      final reader = BinaryReader(buffer)..seek(2);
      expect(reader.offset, equals(2));
      expect(reader.readUint8(), equals(3));

      reader.seek(0);
      expect(reader.offset, equals(0));
      expect(reader.readUint8(), equals(1));
    });

    test('rewind method moves back correctly', () {
      final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
      final reader = BinaryReader(buffer)
        ..readBytes(3) // offset 3
        ..rewind(2);
      expect(reader.offset, equals(1));
      expect(reader.readUint8(), equals(2));
    });

    test('hasBytes returns true when enough bytes available', () {
      final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
      final reader = BinaryReader(buffer);
      expect(reader.hasBytes(1), isTrue);
      expect(reader.hasBytes(5), isTrue);
      expect(reader.hasBytes(6), isFalse);
    });

    group('baseOffset handling', () {
      test('readBytes works correctly with non-zero baseOffset', () {
        final largeBuffer = Uint8List.fromList(List.generate(100, (i) => i));
        final subBuffer = Uint8List.sublistView(largeBuffer, 50, 60);
        final reader = BinaryReader(subBuffer);

        final bytes = reader.readBytes(5);
        expect(bytes, equals([50, 51, 52, 53, 54]));
        expect(reader.availableBytes, equals(5));
      });
    });

    test('throws on seeking beyond buffer', () {
      final buffer = Uint8List.fromList([1, 2, 3]);
      final reader = BinaryReader(buffer);
      expect(() => reader.seek(4), throwsA(isA<RangeError>()));
    });

    test('throws when rewinding beyond start', () {
      final buffer = Uint8List.fromList([1, 2, 3]);
      final reader = BinaryReader(buffer)..readUint8(); // offset 1
      expect(() => reader.rewind(2), throwsA(isA<RangeError>()));
    });
  });
}
