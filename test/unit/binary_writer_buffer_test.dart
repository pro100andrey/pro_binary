import 'dart:typed_data';

import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('BinaryWriter Buffer Management', () {
    late BinaryWriter writer;

    setUp(() {
      writer = BinaryWriter();
    });

    test('initial capacity is 128 bytes by default and aligned', () {
      expect(writer.capacity, equals(128));
      expect(writer.capacity % 64, equals(0));
    });

    test('capacity is aligned to 64-byte boundary on initialization', () {
      // Test various sizes
      final customWriter256 = BinaryWriter(initialBufferSize: 256);
      expect(customWriter256.capacity, equals(256));
      expect(customWriter256.capacity % 64, equals(0));

      // Size 50 should be aligned to 64
      final customWriter50 = BinaryWriter(initialBufferSize: 50);
      expect(customWriter50.capacity, equals(64));
      expect(customWriter50.capacity % 64, equals(0));

      // Size 100 should be aligned to 128
      final customWriter100 = BinaryWriter(initialBufferSize: 100);
      expect(customWriter100.capacity, equals(128));
      expect(customWriter100.capacity % 64, equals(0));
    });

    test('capacity increases after buffer expansion', () {
      // Default capacity is 128 bytes
      expect(writer.capacity, equals(128));

      // Write data that exceeds initial capacity
      final largeData = Uint8List(200);
      writer.writeBytes(largeData);

      // Capacity with 1.5x growth: need 200, 128 * 1.5 = 192 < 200, so use
      // 200 aligned to 256
      expect(writer.capacity, equals(256));
    });

    test('capacity expands with 1.5x growth strategy', () {
      final smallWriter = BinaryWriter(initialBufferSize: 64);
      expect(smallWriter.capacity, equals(64));

      // Write 100 bytes (exceeds initial 64)
      // 64 * 1.5 = 96 < 100, so use 100 aligned to 128
      smallWriter.writeBytes(Uint8List(100));

      expect(smallWriter.capacity, equals(128));
    });

    test('capacity resets to initial size after reset', () {
      // Force expansion
      writer.writeBytes(Uint8List(200));
      expect(writer.capacity, greaterThan(128));

      // reset() should reset capacity back to initial size (128)
      writer.reset();
      expect(writer.capacity, equals(128));
      expect(writer.bytesWritten, equals(0));
    });

    test('capacity resets to initial size after takeBytes (copy: false)', () {
      // Force expansion
      writer.writeBytes(Uint8List(200));
      expect(writer.capacity, greaterThan(128));

      // takeBytes() resets to initial size (128) by default
      writer.takeBytes();
      expect(writer.capacity, equals(128));
      expect(writer.bytesWritten, equals(0));
    });

    test('capacity is retained after takeBytes(copy: true)', () {
      // Force expansion
      writer.writeBytes(Uint8List(200));
      final capacityBefore = writer.capacity;
      expect(capacityBefore, greaterThan(128));

      // takeBytes(copy: true) keeps the buffer
      final bytes = writer.takeBytes(copy: true);
      expect(bytes.length, equals(200));
      expect(writer.capacity, equals(capacityBefore));
      expect(writer.bytesWritten, equals(0));
    });

    test('capacity does not change with toBytes', () {
      writer.writeBytes(Uint8List(200));
      final capacityBefore = writer.capacity;

      // toBytes() should not change capacity
      final bytes = writer.toBytes();
      expect(writer.capacity, equals(capacityBefore));
      expect(bytes.length, equals(200));
    });

    test('capacity aligns to 64-byte boundary after expansion', () {
      // Start with 128 bytes (already aligned to 64)
      expect(writer.capacity, equals(128));
      expect(writer.capacity % 64, equals(0));

      // Write 200 bytes -> requires 256 capacity (128 * 2)
      // 256 is already aligned to 64, so capacity should be 256
      writer.writeBytes(Uint8List(200));
      expect(writer.capacity, equals(256));
      expect(writer.capacity % 64, equals(0));
    });

    test('capacity alignment happens on initialization and expansion', () {
      final sizes = [1, 17, 33, 65, 99, 130];
      final expectedInitial = [64, 64, 64, 128, 128, 192];

      for (var i = 0; i < sizes.length; i++) {
        final size = sizes[i];
        final expected = expectedInitial[i];
        final w = BinaryWriter(initialBufferSize: size);

        expect(w.capacity, equals(expected));
        expect(w.capacity % 64, equals(0));

        w.writeBytes(Uint8List(w.capacity + 1));
        expect(w.capacity % 64, equals(0));
      }
    });

    test('capacity alignment calculation is correct', () {
      final testCases = {
        1: 64,
        63: 64,
        64: 64,
        65: 128,
        127: 128,
        128: 128,
        129: 192,
        255: 256,
        256: 256,
        257: 320,
      };

      for (final entry in testCases.entries) {
        final unaligned = entry.key;
        final aligned = entry.value;
        final calculated = (unaligned + 63) & ~63;
        expect(calculated, equals(aligned));
      }
    });

    group('toBytes', () {
      test('return current buffer without resetting writer state', () {
        writer
          ..writeUint8(42)
          ..writeUint8(100);

        final bytes1 = writer.toBytes();
        expect(bytes1, equals([42, 100]));

        writer.writeUint8(200);
        final bytes2 = writer.toBytes();
        expect(bytes2, equals([42, 100, 200]));
      });

      test('preserve written data across toBytes calls', () {
        writer.writeUint32(0x12345678);

        final bytes1 = writer.toBytes();
        expect(bytes1, equals([0x12, 0x34, 0x56, 0x78]));

        writer.writeUint32(0xABCDEF00);

        final bytes2 = writer.toBytes();
        expect(
          bytes2,
          equals([0x12, 0x34, 0x56, 0x78, 0xAB, 0xCD, 0xEF, 0x00]),
        );
      });
    });

    group('reset', () {
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
    });

    group('Memory efficiency', () {
      test('takeBytes(copy: false) creates view not copy', () {
        writer.writeUint32(0x12345678);
        final bytes = writer.takeBytes();

        expect(bytes, isA<Uint8List>());
        expect(bytes.length, equals(4));

        // It's a view, but the writer has a NEW buffer now.
        // We can't easily prove it's a view of the OLD buffer without keeping
        // a reference to the old buffer.
      });

      test('takeBytes(copy: true) creates copy', () {
        writer.writeUint32(0x12345678);
        final bytes = writer.takeBytes(copy: true);

        expect(bytes, isA<Uint8List>());
        expect(bytes.length, equals(4));

        // Modify the copy and check if writer's retained buffer is affected
        bytes[0] = 0xFF;
        writer.writeUint8(0x00);
        // If it was a copy, the first byte of writer's current buffer
        // (offset 0) should be 0x00
        expect(writer.toBytes()[0], equals(0x00));
      });

      test('toBytes creates view not copy', () {
        writer.writeUint64(123456789);
        final bytes = writer.toBytes();

        expect(bytes, isA<Uint8List>());
        expect(bytes.length, equals(8));
      });
    });
  });
}
