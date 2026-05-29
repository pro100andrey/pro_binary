import 'dart:async';
import 'dart:typed_data';

import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('StreamBinaryReader Chunk Operations', () {
    late StreamBinaryReader reader;

    setUp(() {
      reader = StreamBinaryReader();
    });

    test('readInt8 handles chunk boundary', () {
      reader.addChunk([0xFF]); // -1
      expect(reader.readInt8(), equals(-1));
    });

    test('readBool reads boolean values', () {
      reader.addChunk([0, 1, 42]);
      expect(reader.readBool(), isFalse);
      expect(reader.readBool(), isTrue);
      expect(reader.readBool(), isTrue);
    });

    test('readInt16 handles chunk boundary', () {
      reader
        ..addChunk([0xFF])
        ..addChunk([0xFF]);
      expect(reader.readInt16(), equals(-1));
    });

    test('readUint16 supports little-endian', () {
      reader
        ..addChunk([0x01])
        ..addChunk([0x00]);
      expect(reader.readUint16(Endian.little), equals(1));
    });

    test('readInt32 handles chunk boundary', () {
      reader
        ..addChunk([0xFF, 0xFF])
        ..addChunk([0xFF, 0xFF]);
      expect(reader.readInt32(), equals(-1));
    });

    test('readUint32 supports little-endian', () {
      reader
        ..addChunk([0x01, 0x00])
        ..addChunk([0x00, 0x00]);
      expect(reader.readUint32(Endian.little), equals(1));
    });

    test('readInt64 handles chunk boundary', () {
      reader
        ..addChunk([0xFF, 0xFF, 0xFF, 0xFF])
        ..addChunk([0xFF, 0xFF, 0xFF, 0xFF]);
      expect(reader.readInt64(), equals(-1));
    });

    test('readUint64 supports little-endian', () {
      reader
        ..addChunk([0x01, 0x00, 0x00, 0x00])
        ..addChunk([0x00, 0x00, 0x00, 0x00]);
      expect(reader.readUint64(Endian.little), equals(1));
    });

    test('readFloat32 handles chunk boundary', () {
      final writer = BinaryWriter()..writeFloat32(3.14);
      final bytes = writer.takeBytes();
      reader
        ..addChunk(bytes.sublist(0, 2))
        ..addChunk(bytes.sublist(2));
      expect(reader.readFloat32(), closeTo(3.14, 0.001));
    });

    test('readFloat64 handles chunk boundary', () {
      final writer = BinaryWriter()..writeFloat64(3.14159);
      final bytes = writer.takeBytes();
      reader
        ..addChunk(bytes.sublist(0, 4))
        ..addChunk(bytes.sublist(4));
      expect(reader.readFloat64(), closeTo(3.14159, 0.00001));
    });

    test('readVarInt handles chunk boundary', () {
      final writer = BinaryWriter()..writeVarInt(-300);
      final bytes = writer.takeBytes();
      for (final b in bytes) {
        reader.addChunk([b]);
      }
      expect(reader.readVarInt(), equals(-300));
    });

    test('readRemainingBytes reads from multiple chunks', () {
      reader
        ..addChunk([1, 2])
        ..addChunk([3, 4])
        ..addChunk([5]);
      final bytes = reader.readRemainingBytes();
      expect(bytes, equals([1, 2, 3, 4, 5]));
      expect(reader.availableBytes, equals(0));
    });

    test('readVarBytes handles chunk boundary', () {
      final writer = BinaryWriter()..writeVarBytes([10, 20, 30]);
      final bytes = writer.takeBytes();
      reader
        ..addChunk(bytes.sublist(0, 2))
        ..addChunk(bytes.sublist(2));
      expect(reader.readVarBytes(), equals([10, 20, 30]));
    });

    test('readString supports allowMalformed across chunk boundary', () {
      // Cyrillic 'П' is [0xD0, 0x9F]
      reader
        ..addChunk([0xD0])
        ..addChunk([0x9F]);
      expect(reader.readString(2, allowMalformed: true), equals('П'));
    });

    test('readBytes throws RangeError for negative length', () {
      expect(() => reader.readBytes(-1), throwsRangeError);
      expect(() => reader.readString(-1), throwsRangeError);
      expect(() => reader.skip(-1), throwsRangeError);
      expect(() => reader.hasBytes(-1), throwsRangeError);
    });

    test('commit prunes consumed chunks', () {
      reader
        ..addChunk([1])
        ..addChunk([2])
        ..addChunk([3])
        ..readUint8() // 1
        ..bookmark()
        ..readUint8() // 2
        ..commit(); // Should prune chunk 1 and 2

      expect(reader.readUint8(), equals(3));
    });

    test('bookmark handles growth beyond initial capacity', () {
      // Force bookmark array growth (initial size is 16)
      for (var i = 0; i < 20; i++) {
        reader.bookmark();
      }
      expect(reader.readUint8, throwsA(isA<NotEnoughDataException>()));
    });

    test('rollback handles no current reader and maintains state', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      reader.addChunk(bytes);

      final initialAvailable = reader.availableBytes;
      expect(initialAvailable, equals(3));

      reader.bookmark();
      // Rollback without consuming any data
      expect(() => reader.rollback(), returnsNormally);

      // State should be identical
      expect(reader.availableBytes, equals(initialAvailable));

      // Should still be able to read correctly
      expect(reader.readUint8(), equals(1));
      expect(reader.availableBytes, equals(2));
    });

    test('readVarUint throws FormatException for oversized varint', () {
      reader.addChunk(List.filled(11, 0x80));
      expect(() => reader.readVarUint(), throwsFormatException);
    });

    test('addChunk ignores empty list', () {
      reader.addChunk([]);
      expect(reader.availableBytes, equals(0));
    });

    test('addChunk accepts List<int>', () {
      final list = <int>[1, 2, 3];
      reader.addChunk(list);
      expect(reader.availableBytes, equals(3));
      expect(reader.readUint8(), equals(1));
    });

    test('readBytes handles zero length', () {
      reader.addChunk([1, 2, 3]);
      final bytes = reader.readBytes(0);
      expect(bytes, isEmpty);
      expect(reader.availableBytes, equals(3));
    });

    test('readRemainingBytes returns empty when no data', () {
      final bytes = reader.readRemainingBytes();
      expect(bytes, isEmpty);
    });

    test('skip handles zero offset', () {
      reader
        ..addChunk([1, 2, 3])
        ..skip(0);
      expect(reader.readUint8(), equals(1));
    });

    test('hasBytes returns true for zero length', () {
      expect(reader.hasBytes(0), isTrue);
      reader.addChunk([1, 2, 3]);
      expect(reader.hasBytes(0), isTrue);
    });

    test('readString handles zero length', () {
      reader.addChunk([1, 2, 3]);
      expect(reader.readString(0), equals(''));
      expect(reader.availableBytes, equals(3));
    });

    test('readVarString handles empty string', () {
      reader.addChunk([0]);
      expect(reader.readVarString(), equals(''));
    });

    test('readUint16 supports little-endian', () {
      reader
        ..addChunk([0x34])
        ..addChunk([0x12]);
      expect(reader.readUint16(Endian.little), equals(0x1234));
    });

    test('readInt16 supports little-endian', () {
      final writer = BinaryWriter()..writeInt16(-852, Endian.little);
      final bytes = writer.takeBytes();
      reader
        ..addChunk(bytes.sublist(0, 1))
        ..addChunk(bytes.sublist(1));
      expect(reader.readInt16(Endian.little), equals(-852));
    });

    test('readUint32 supports little-endian', () {
      final writer = BinaryWriter()..writeUint32(0x44332211, Endian.little);
      final bytes = writer.takeBytes();
      reader
        ..addChunk(bytes.sublist(0, 2))
        ..addChunk(bytes.sublist(2));
      expect(reader.readUint32(Endian.little), equals(0x44332211));
    });

    test('readInt32 supports little-endian', () {
      final writer = BinaryWriter()..writeInt32(-266, Endian.little);
      final bytes = writer.takeBytes();
      reader
        ..addChunk(bytes.sublist(0, 2))
        ..addChunk(bytes.sublist(2));
      expect(reader.readInt32(Endian.little), equals(-266));
    });

    test('readUint64 supports little-endian', () {
      reader
        ..addChunk([0x01])
        ..addChunk([0x00])
        ..addChunk([0x00])
        ..addChunk([0x00])
        ..addChunk([0x00])
        ..addChunk([0x00])
        ..addChunk([0x00])
        ..addChunk([0x00]);
      expect(reader.readUint64(Endian.little), equals(1));
    });

    test('readInt64 supports little-endian', () {
      reader
        ..addChunk([0xFF])
        ..addChunk([0xFF])
        ..addChunk([0xFF])
        ..addChunk([0xFF])
        ..addChunk([0xFF])
        ..addChunk([0xFF])
        ..addChunk([0xFF])
        ..addChunk([0xFF]);
      expect(reader.readInt64(Endian.little), equals(-1));
    });

    test('readFloat32 supports little-endian', () {
      final writer = BinaryWriter()..writeFloat32(2.5, Endian.little);
      final bytes = writer.takeBytes();
      reader
        ..addChunk(bytes.sublist(0, 2))
        ..addChunk(bytes.sublist(2));
      expect(reader.readFloat32(Endian.little), closeTo(2.5, 0.001));
    });

    test('readFloat64 supports little-endian', () {
      final writer = BinaryWriter()..writeFloat64(3.14159, Endian.little);
      final bytes = writer.takeBytes();
      reader
        ..addChunk(bytes.sublist(0, 4))
        ..addChunk(bytes.sublist(4));
      expect(reader.readFloat64(Endian.little), closeTo(3.14159, 0.00001));
    });

    test('readBytes handles more than two chunks', () {
      reader
        ..addChunk([1, 2])
        ..addChunk([3, 4])
        ..addChunk([5, 6]);
      final bytes = reader.readBytes(5);
      expect(bytes, equals([1, 2, 3, 4, 5]));
    });

    test('NotEnoughDataException toString includes required and available', () {
      reader.addChunk([1, 2]);
      expect(
        () => reader.readUint32(),
        throwsA(
          isA<NotEnoughDataException>().having(
            (e) => e.toString(),
            'toString',
            allOf(
              contains('required 4'),
              contains('2 available'),
            ),
          ),
        ),
      );
    });
  });

  group('BinaryStreamTransformer Stream Behavior', () {
    test('rethrows non-NotEnoughDataException errors', () async {
      final controller = StreamController<List<int>>();
      final transformer = _ErrorTransformer();
      final stream = controller.stream.transform(transformer);

      controller.add([1, 2, 3]);

      expect(stream.first, throwsException);
      await controller.close();
    });

    test('waits for more data when parse returns null', () async {
      final controller = StreamController<List<int>>();
      final transformer = _NullTransformer();
      final stream = controller.stream.transform(transformer);

      final results = <int>[];
      final sub = stream.listen(results.add);

      controller.add([1]); // Transformer will return null
      await Future<void>.delayed(Duration.zero);
      expect(results, isEmpty);

      controller.add([2]); // Transformer will return data
      await Future<void>.delayed(Duration.zero);
      expect(results, equals([42]));

      await controller.close();
      await sub.asFuture<void>();
      await sub.cancel();
    });

    test(
      'breaks loop when parse returns without consuming data',
      () async {
        final controller = StreamController<List<int>>();
        final transformer = _ZeroByteTransformer();
        final stream = controller.stream.transform(transformer);

        final results = <int>[];
        final sub = stream.listen(results.add);

        controller.add([1, 2, 3]);
        await Future<void>.delayed(Duration.zero);
        expect(results, equals([42]));

        await controller.close();
        await sub.asFuture<void>();
        await sub.cancel();
      },
    );

    test('ignores empty chunk', () async {
      final controller = StreamController<List<int>>();
      final transformer = _TwoByteTransformer();
      final stream = controller.stream.transform(transformer);

      final results = <int>[];
      final sub = stream.listen(results.add);

      controller.add([]);
      await Future<void>.delayed(Duration.zero);

      controller.add([1]);
      await Future<void>.delayed(Duration.zero);

      controller.add([2]);
      await Future<void>.delayed(Duration.zero);
      expect(results, equals([42]));

      await controller.close();
      await sub.asFuture<void>();
      await sub.cancel();
    });

    test('accepts List<int> chunk', () async {
      final controller = StreamController<List<int>>();
      final transformer = _TwoByteTransformer();
      final stream = controller.stream.transform(transformer);

      final data = <int>[1, 2];
      final results = <int>[];
      final sub = stream.listen(results.add);

      controller.add(data);
      await Future<void>.delayed(Duration.zero);
      expect(results, equals([42]));

      await controller.close();
      await sub.asFuture<void>();
      await sub.cancel();
    });
  });
}

class _ErrorTransformer extends BinaryStreamTransformer<int> {
  @override
  int? parse(StreamBinaryReader reader) {
    throw Exception('Parse error');
  }
}

class _NullTransformer extends BinaryStreamTransformer<int> {
  var _calls = 0;
  @override
  int? parse(StreamBinaryReader reader) {
    _calls++;
    if (_calls == 1) {
      return null;
    }
    reader
      ..readUint8()
      ..readUint8();
    return 42;
  }
}

class _ZeroByteTransformer extends BinaryStreamTransformer<int> {
  @override
  int? parse(StreamBinaryReader reader) => 42;
}

class _TwoByteTransformer extends BinaryStreamTransformer<int> {
  @override
  int? parse(StreamBinaryReader reader) {
    if (reader.availableBytes < 2) {
      return null;
    }
    reader
      ..readUint8()
      ..readUint8();
    return 42;
  }
}
