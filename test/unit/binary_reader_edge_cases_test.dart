import 'dart:typed_data';

import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('BinaryReader Edge Cases and Validation', () {
    test('read beyond buffer throws RangeError', () {
      final buffer = Uint8List.fromList([0x01, 0x02]);
      final reader = BinaryReader(buffer);
      expect(reader.readUint32, throwsA(isA<RangeError>()));
    });

    test('negative length input throws RangeError', () {
      final buffer = Uint8List.fromList([0x01, 0x02]);
      final reader = BinaryReader(buffer);
      expect(() => reader.readBytes(-1), throwsA(isA<RangeError>()));
      expect(() => reader.skip(-1), throwsA(isA<RangeError>()));
    });

    group('Partial read scenarios', () {
      test('interleaved VarInt and fixed-size reads', () {
        final writer = BinaryWriter()
          ..writeVarUint(127)
          ..writeUint8(42)
          ..writeVarInt(-1)
          ..writeUint16(1000);

        final reader = BinaryReader(writer.takeBytes());
        expect(reader.readVarUint(), equals(127));
        expect(reader.readUint8(), equals(42));
        expect(reader.readVarInt(), equals(-1));
        expect(reader.readUint16(), equals(1000));
      });
    });

    group('Concise API', () {
      test('operator [] returns byte at absolute index', () {
        final buffer = Uint8List.fromList([10, 20, 30, 40]);
        final reader = BinaryReader(buffer);
        expect(reader[0], equals(10));
        expect(reader[1], equals(20));
        expect(reader.offset, equals(0));
      });

      test('call reads bytes and advances offset', () {
        final buffer = Uint8List.fromList([10, 20, 30, 40]);
        final reader = BinaryReader(buffer);
        expect(reader.call(2), equals([10, 20]));
        expect(reader.offset, equals(2));
      });
    });

    group('fromList', () {
      test('fromList creates reader from List<int>', () {
        final bytes = <int>[0x01, 0x02];
        final reader = BinaryReader.fromList(bytes);
        expect(reader.readUint8(), equals(1));
        expect(reader.readUint8(), equals(2));
      });

      test('fromList copies data', () {
        final bytes = <int>[0x01, 0x02];
        final reader = BinaryReader.fromList(bytes);
        bytes[0] = 0xFF;
        expect(reader.readUint8(), equals(1));
      });
    });
  });
}
