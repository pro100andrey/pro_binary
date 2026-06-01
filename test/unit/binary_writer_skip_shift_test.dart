import 'dart:convert';

import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('BinaryWriter skip', () {
    late BinaryWriter writer;

    setUp(() {
      writer = BinaryWriter();
    });

    test('skip 0 bytes is a no-op', () {
      writer.writeUint32(42);
      final before = writer.bytesWritten;
      writer.skip(0);
      expect(writer.bytesWritten, equals(before));
    });

    test('skip advances write position', () {
      writer.writeUint32(42);
      expect(writer.bytesWritten, equals(4));
      writer.skip(8);
      expect(writer.bytesWritten, equals(12));
    });

    test('skip expands buffer when needed', () {
      final initialCapacity = writer.capacity;
      writer.skip(initialCapacity + 100);
      expect(writer.bytesWritten, equals(initialCapacity + 100));
      expect(writer.capacity, greaterThan(initialCapacity));
    });

    test('skip negative throws RangeError', () {
      expect(() => writer.skip(-1), throwsA(isA<RangeError>()));
    });

    test('skip then write verifies data integrity', () {
      writer
        ..writeUint32(0xDEADBEEF)
        ..skip(4)
        ..writeUint32(0xCAFEBABE);
      // skip advances offset, so second write goes to position 8
      expect(writer[8], equals(0xCA));
      expect(writer[9], equals(0xFE));
      expect(writer[10], equals(0xBA));
      expect(writer[11], equals(0xBE));
    });

    test('skip then backpatch overwrites skipped bytes', () {
      writer
        ..writeUint32(0) // placeholder
        ..skip(4) // reserve 4 bytes
        ..writeUint32(0x12345678);
      // backpatch: overwrite the skipped region
      writer[0] = 0x99;
      writer[1] = 0x88;
      writer[2] = 0x77;
      writer[3] = 0x66;
      expect(writer[0], equals(0x99));
      expect(writer[1], equals(0x88));
      expect(writer[2], equals(0x77));
      expect(writer[3], equals(0x66));
    });
  });

  group('BinaryWriter reserve', () {
    late BinaryWriter writer;

    setUp(() {
      writer = BinaryWriter();
    });

    test('reserve returns starting offset', () {
      writer.writeUint32(0xDEADBEEF);
      final pos = writer.reserve(8);
      expect(pos, equals(4));
    });

    test('reserve advances bytesWritten', () {
      writer.writeUint32(0xDEADBEEF);
      final before = writer.bytesWritten;
      final pos = writer.reserve(8);
      expect(writer.bytesWritten, equals(before + 8));
      expect(pos, equals(before));
    });

    test('reserved bytes can be backpatched', () {
      final headerPos = writer.reserve(4);
      writer
        ..writeUint32(0x12345678)
        ..seek(headerPos)
        ..writeUint32(0xABCDEF00);
      expect(writer[headerPos], equals(0xAB));
      expect(writer[headerPos + 1], equals(0xCD));
      expect(writer[headerPos + 2], equals(0xEF));
      expect(writer[headerPos + 3], equals(0x00));
    });

    test('reserve multiple blocks', () {
      final pos1 = writer.reserve(4);
      final pos2 = writer.reserve(8);
      writer.writeUint8(0xFF);
      expect(pos1, equals(0));
      expect(pos2, equals(4));
      expect(writer.bytesWritten, equals(12 + 1));
    });

    test('reserve 0 bytes returns current offset', () {
      writer.writeUint32(42);
      final pos = writer.reserve(0);
      expect(pos, equals(4));
      expect(writer.bytesWritten, equals(4));
    });

    test('reserve then shiftBytes compacts buffer', () {
      final headerPos = writer.reserve(8);
      writer
        ..writeUint32(0x11111111)
        ..writeUint32(0x22222222)
        // Shift payload left to overwrite unused reserved space
        ..shiftBytes(headerPos + 2, writer.bytesWritten, 0);
      // Now backpatch the compacted header
      writer[headerPos] = 0x00;
      writer[headerPos + 1] = 0x0C;
      expect(writer.bytesWritten, equals(14));
      expect(writer[0], equals(0x00));
      expect(writer[1], equals(0x0C));
      // Payload shifted to position 6
      expect(writer[6], equals(0x11));
      expect(writer[10], equals(0x22));
    });
  });

  group('BinaryWriter shiftBytes', () {
    late BinaryWriter writer;

    setUp(() {
      writer = BinaryWriter();
    });

    test('shift block left within buffer', () {
      writer
        ..writeUint32(0x11111111)
        ..writeUint32(0x22222222)
        ..writeUint32(0x33333333)
        // shift bytes [4..8) to position 0
        ..shiftBytes(4, 8, 0);
      expect(writer.bytesWritten, equals(12));
      expect(writer[0], equals(0x22));
      expect(writer[1], equals(0x22));
      expect(writer[2], equals(0x22));
      expect(writer[3], equals(0x22));
    });

    test('shift to position 0', () {
      writer
        ..writeUint8(0)
        ..writeUint8(0)
        ..writeUint8(0xAA)
        ..writeUint8(0xBB)
        ..shiftBytes(2, 4, 0);
      // end == offset, so offset becomes target + length = 2
      expect(writer.bytesWritten, equals(2));
      expect(writer[0], equals(0xAA));
      expect(writer[1], equals(0xBB));
    });

    test('shift with target == start is a no-op', () {
      writer
        ..writeUint8(0xAA)
        ..writeUint8(0xBB)
        ..shiftBytes(0, 2, 0);
      expect(writer[0], equals(0xAA));
      expect(writer[1], equals(0xBB));
    });

    test('shift with start == end (empty range) is a no-op', () {
      writer
        ..writeUint8(0xAA)
        ..writeUint8(0xBB)
        ..shiftBytes(2, 2, 0);
      expect(writer[0], equals(0xAA));
      expect(writer[1], equals(0xBB));
    });

    test('shift updates offset when shifting the end boundary', () {
      writer
        ..writeUint32(0x11111111)
        ..writeUint32(0x22222222)
        ..writeUint32(0x33333333);
      expect(writer.bytesWritten, equals(12));
      // shift [8..12) to [4..8), end == offset so offset should update
      writer.shiftBytes(8, 12, 4);
      expect(writer.bytesWritten, equals(8));
    });

    test('shift does not update offset when not shifting the end', () {
      writer
        ..writeUint32(0x11111111)
        ..writeUint32(0x22222222)
        ..writeUint32(0x33333333);
      expect(writer.bytesWritten, equals(12));
      // shift [4..8) to [0..4), end != offset so offset stays
      writer.shiftBytes(4, 8, 0);
      expect(writer.bytesWritten, equals(12));
    });

    test('shift negative start throws AssertionError', () {
      writer.writeUint8(0xAA);
      expect(() => writer.shiftBytes(-1, 1, 0), throwsA(isA<AssertionError>()));
    });

    test('shift end < start throws AssertionError', () {
      writer.writeUint8(0xAA);
      expect(() => writer.shiftBytes(1, 0, 0), throwsA(isA<AssertionError>()));
    });

    test('shift end > offset throws AssertionError', () {
      writer.writeUint8(0xAA);
      expect(() => writer.shiftBytes(0, 5, 0), throwsA(isA<AssertionError>()));
    });

    test('shift target < 0 throws AssertionError', () {
      writer.writeUint8(0xAA);
      expect(() => writer.shiftBytes(0, 1, -1), throwsA(isA<AssertionError>()));
    });

    test('shift target > start throws AssertionError', () {
      writer
        ..writeUint8(0xAA)
        ..writeUint8(0xBB);
      expect(() => writer.shiftBytes(0, 1, 1), throwsA(isA<AssertionError>()));
    });

    test('shift preserves data integrity for non-shifted bytes', () {
      writer
        ..writeUint8(0x01)
        ..writeUint8(0x02)
        ..writeUint8(0x03)
        ..writeUint8(0x04)
        ..writeUint8(0x05)
        // shift [2..4) to [0..2)
        ..shiftBytes(2, 4, 0);
      expect(writer.bytesWritten, equals(5));
      expect(writer[0], equals(0x03));
      expect(writer[1], equals(0x04));
      expect(writer[2], equals(0x03));
      expect(writer[3], equals(0x04));
      expect(writer[4], equals(0x05));
    });
  });

  group('BinaryWriter Reserve & Backpatch pattern', () {
    late BinaryWriter writer;

    setUp(() {
      writer = BinaryWriter();
    });

    test('full reserve and backpatch with shift', () {
      // Reserve 8 bytes for header (over-allocated)
      writer
        ..skip(8)
        // Write payload
        ..writeUint32(0x11111111)
        ..writeUint32(0x22222222);
      expect(writer.bytesWritten, equals(16));

      // Actual header is 4 bytes, shift payload left by 4
      writer.shiftBytes(8, 16, 4);
      expect(writer.bytesWritten, equals(12));

      // Now backpatch the 4-byte header using seek to go back
      writer
        ..seek(0)
        ..writeUint32(12);
      // 12 = 0x0000000C in big-endian
      expect(writer[0], equals(0x00));
      expect(writer[1], equals(0x00));
      expect(writer[2], equals(0x00));
      expect(writer[3], equals(0x0C));
    });

    test('reserve and backpatch via direct write', () {
      writer
        ..skip(4)
        ..writeVarString('hello');
      // Backpatch the length at position 0
      final len = utf8.encode('hello').length;
      writer[0] = len & 0xFF;
      writer[1] = (len >> 8) & 0xFF;
      writer[2] = (len >> 16) & 0xFF;
      writer[3] = (len >> 24) & 0xFF;
      expect(writer[0], equals(len & 0xFF));
    });
  });
}
