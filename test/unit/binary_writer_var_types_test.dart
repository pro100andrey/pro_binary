import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('BinaryWriter Variable-Length Types', () {
    late BinaryWriter writer;

    setUp(() {
      writer = BinaryWriter();
    });

    group('VarInt and VarUint', () {
      test('writes VarUint single byte (0)', () {
        writer.writeVarUint(0);
        expect(writer.takeBytes(), [0]);
      });

      test('writes VarUint single byte (127)', () {
        writer.writeVarUint(127);
        expect(writer.takeBytes(), [127]);
      });

      test('writes VarUint two bytes (128)', () {
        writer.writeVarUint(128);
        expect(writer.takeBytes(), [0x80, 0x01]);
      });

      test('writes VarUint three bytes (16384)', () {
        writer.writeVarUint(16384);
        expect(writer.takeBytes(), [0x80, 0x80, 0x01]);
      });

      test('writes VarUint large value', () {
        writer.writeVarUint(1 << 30);
        expect(writer.takeBytes(), [0x80, 0x80, 0x80, 0x80, 0x04]);
      });

      test('writes VarInt (ZigZag) encoding for positive value 1', () {
        writer.writeVarInt(1);
        expect(writer.takeBytes(), [2]);
      });

      test('writes VarInt (ZigZag) encoding for negative value -1', () {
        writer.writeVarInt(-1);
        expect(writer.takeBytes(), [1]);
      });

      test('writes VarInt ZigZag encoding for large values', () {
        writer.writeVarInt(2147483647);
        expect(writer.takeBytes(), [0xFE, 0xFF, 0xFF, 0xFF, 0x0F]);

        writer
          ..reset()
          ..writeVarInt(-2147483648);
        expect(writer.takeBytes(), [0xFF, 0xFF, 0xFF, 0xFF, 0x0F]);
      });

      test('writeVarUint boundary transitions', () {
        writer
          ..writeVarUint(0x7F) // Last 1-byte value
          ..writeVarUint(0x80) // First 2-byte value
          ..writeVarUint(0x3FFF) // Last 2-byte value
          ..writeVarUint(0x4000); // First 3-byte value

        final reader = BinaryReader(writer.takeBytes());
        expect(reader.readVarUint(), equals(0x7F));
        expect(reader.readVarUint(), equals(0x80));
        expect(reader.readVarUint(), equals(0x3FFF));
        expect(reader.readVarUint(), equals(0x4000));
      });

      test(
        'writeVarUint with negative value must not use fast path',
        () {
          writer.writeVarUint(-1);
          final bytes = writer.takeBytes();
          expect(bytes.length, 10);
          expect(bytes[0], 0xFF);
          expect(bytes[9], 0x01);
        },
      );
    });

    group('VarBytes', () {
      test('writeVarBytes with empty array', () {
        writer.writeVarBytes([]);
        expect(writer.takeBytes(), equals([0]));
      });

      test('writeVarBytes with small array', () {
        writer.writeVarBytes([1, 2, 3, 4]);
        final bytes = writer.takeBytes();
        expect(bytes[0], equals(4));
        expect(bytes.sublist(1), equals([1, 2, 3, 4]));
      });

      test('writeVarBytes with 128 bytes (two-byte VarUint length)', () {
        final data = List.generate(128, (i) => i & 0xFF);
        writer.writeVarBytes(data);
        final bytes = writer.takeBytes();
        expect(bytes[0], equals(0x80));
        expect(bytes[1], equals(0x01));
        expect(bytes.length, equals(130));
      });

      test('writeVarBytes triggers buffer expansion', () {
        final w = BinaryWriter(initialBufferSize: 16);
        final largeData = List.generate(1000, (i) => i & 0xFF);
        w.writeVarBytes(largeData);
        final bytes = w.takeBytes();
        expect(bytes.length, greaterThan(1000));
        final reader = BinaryReader(bytes);
        expect(reader.readVarBytes(), equals(largeData));
      });
    });

    group('VarString', () {
      test('writeVarString with ASCII string', () {
        writer.writeVarString('Hello');
        final bytes = writer.takeBytes();
        expect(bytes[0], equals(5));
        expect(bytes.sublist(1), equals([72, 101, 108, 108, 111]));
      });

      test('writeVarString with UTF-8 multi-byte characters', () {
        writer.writeVarString('世界');
        final bytes = writer.takeBytes();
        expect(bytes[0], equals(6));
        expect(bytes.length, equals(7));
      });

      test('writeVarString with empty string', () {
        writer.writeVarString('');
        expect(writer.takeBytes(), equals([0]));
      });

      test('writeVarString with malformed handling', () {
        // Lone high surrogate
        final malformed = String.fromCharCode(0xD800);
        expect(() => writer.writeVarString(malformed), returnsNormally);
      });
    });
  });
}
