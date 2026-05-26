import 'dart:typed_data';

import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('BinaryReader Buffer Operations', () {
    test('peekBytes returns bytes without changing offset', () {
      final buffer = Uint8List.fromList([0x10, 0x20, 0x30, 0x40]);
      final reader = BinaryReader(buffer);

      final peeked = reader.peekBytes(2);
      expect(peeked, equals([0x10, 0x20]));
      expect(reader.offset, equals(0));

      expect(reader.readUint8(), equals(0x10));
    });

    test('readBytes returns view of original buffer', () {
      final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
      final reader = BinaryReader(buffer);
      final bytes = reader.readBytes(3);
      expect(bytes, isA<Uint8List>());
      expect(bytes, equals([1, 2, 3]));
    });

    test('Buffer sharing - multiple readers on same buffer', () {
      final buffer = Uint8List.fromList([1, 2, 3, 4, 5]);
      final reader1 = BinaryReader(buffer);
      final reader2 = BinaryReader(buffer);

      expect(reader1.readUint8(), equals(1));
      expect(reader2.readUint8(), equals(1));
      expect(reader1.readUint8(), equals(2));
    });

    group('rebind', () {
      test('rebind replaces buffer and resets offset to 0', () {
        final buffer1 = Uint8List.fromList([0x01, 0x02, 0x03, 0x04]);
        final reader = BinaryReader(buffer1)..readUint8();
        expect(reader.offset, equals(1));

        final buffer2 = Uint8List.fromList([0x10, 0x20, 0x30]);
        reader.rebind(buffer2);

        expect(reader.offset, equals(0));
        expect(reader.length, equals(3));
        expect(reader.readUint8(), equals(0x10));
      });

      test('rebind with zero-length buffer', () {
        final buffer1 = Uint8List.fromList([0x01, 0x02]);
        final reader = BinaryReader(buffer1)
          ..readUint8()
          ..rebind(Uint8List(0));
        expect(reader.offset, equals(0));
        expect(reader.length, equals(0));
        expect(reader.readUint8, throwsA(isA<RangeError>()));
      });
    });

    test('Mixed endianness operations', () {
      final buffer = Uint8List.fromList([0x01, 0x02, 0x02, 0x01]);
      final reader = BinaryReader(buffer);

      expect(reader.readUint16(), equals(0x0102)); // Big
      expect(
        reader.readUint16(.little),
        equals(0x0102),
      ); // Little (reversed 0x0201 is 0x0102)
    });
  });
}
