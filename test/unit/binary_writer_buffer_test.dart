import 'dart:typed_data';

import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('BinaryWriter Buffer', () {
    late BinaryWriter writer;

    setUp(() {
      writer = BinaryWriter();
    });

    test('initial capacity is aligned to 64 bytes', () {
      expect(writer.capacity, equals(128));

      final writer2 = BinaryWriter(initialBufferSize: 10);
      expect(writer2.capacity, equals(64));
    });

    test('expands buffer when writing beyond capacity', () {
      final largeBytes = Uint8List(200);
      writer.writeBytes(largeBytes);

      expect(writer.capacity, greaterThanOrEqualTo(200));
      expect(writer.bytesWritten, equals(200));
    });

    test('uses exponential growth for expansion', () {
      final initialCapacity = writer.capacity;

      // Force expansion by 1 byte
      final bytes = Uint8List(initialCapacity + 1);
      writer.writeBytes(bytes);

      // Growth factor is 1.5x, aligned to 64
      final expected = (initialCapacity + (initialCapacity >> 1) + 63) & ~63;
      expect(writer.capacity, equals(expected));
    });

    test('multiple expansions maintain data integrity', () {
      for (var i = 0; i < 1000; i++) {
        writer.writeUint32(i);
      }

      final bytes = writer.takeBytes();
      final reader = BinaryReader(bytes);

      for (var i = 0; i < 1000; i++) {
        expect(reader.readUint32(), equals(i));
      }
    });

    test('reset() clears offset but maintains capacity', () {
      final initialCapacity = writer.capacity;
      writer.writeBytes(Uint8List(200));

      final expandedCapacity = writer.capacity;
      expect(expandedCapacity, greaterThan(initialCapacity));

      writer.reset();
      expect(writer.bytesWritten, equals(0));
      // reset() actually re-initializes with initial size
      expect(writer.capacity, equals(initialCapacity));
    });

    group('Pool interaction', () {
      test('capacity resets to initial size after takeBytes (copy: false)', () {
        writer.writeBytes(Uint8List(500));
        expect(writer.capacity, greaterThan(128));

        // takeBytes() resets to initial size (128) by default
        writer.takeBytes();
        expect(writer.capacity, equals(128));
      });

      test('capacity is retained after takeBytes(copy: true)', () {
        writer.writeBytes(Uint8List(500));
        final expandedCapacity = writer.capacity;

        // takeBytes(copy: true) keeps the buffer
        writer.takeBytes(copy: true);
        expect(writer.capacity, equals(expandedCapacity));
        expect(writer.bytesWritten, equals(0));
      });

      test('sequential writes after takeBytes(copy: true)', () {
        writer
          ..writeUint8(10)
          ..takeBytes(copy: true)
          ..writeUint8(20)
          ..writeUint8(30);

        expect(writer.toBytes(), equals([20, 30]));
      });

      test('reset() during copy-mode maintains buffer', () {
        writer
          ..writeUint8(1)
          ..takeBytes(copy: true)
          ..writeUint8(2)
          ..reset()
          ..writeUint8(100);

        expect(writer.toBytes(), equals([100]));
      });
    });

    group('Memory efficiency', () {
      test('takeBytes(copy: false) returns a zero-copy view of the buffer', () {
        writer.writeUint32(0x11223344);

        // 1. Get a view of the internal buffer before taking bytes.
        final internalView = writer.toBytes();

        // 2. Take bytes (copy: false is default). This detaches the buffer.
        final takenBytes = writer.takeBytes();

        // 3. Verify they look the same initially.
        expect(takenBytes, equals(internalView));

        // 4. Prove it's a view: modifying 'takenBytes' must affect
        // 'internalView' because they share the same underlying memory.
        takenBytes[0] = 0xFF;
        expect(internalView[0], equals(0xFF));
      });

      test('takeBytes(copy: true) returns a deep copy of the buffer', () {
        writer.writeUint32(0x11223344);

        final internalView = writer.toBytes();
        final takenBytes = writer.takeBytes(copy: true);

        expect(takenBytes, equals(internalView));

        // Modifying the copy should NOT affect the original internal buffer
        // memory
        takenBytes[0] = 0xFF;
        expect(internalView[0], isNot(equals(0xFF)));
      });

      test('toBytes() creates view not copy', () {
        writer.writeUint64(123456789);
        final bytes = writer.toBytes();

        expect(bytes, isA<Uint8List>());
        expect(bytes.length, equals(8));

        // Modifying internal buffer affects toBytes() view
        writer
          ..seek(0)
          ..writeUint8(0xFF);
        expect(bytes[0], equals(0xFF));
      });
    });
  });
}
