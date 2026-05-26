import 'dart:async';
import 'dart:typed_data';

import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

void main() {
  group('StreamBinaryReader Coverage', () {
    late StreamBinaryReader reader;

    setUp(() {
      reader = StreamBinaryReader();
    });

    test('readInt8 across chunks', () {
      reader.addChunk([0xFF]); // -1
      expect(reader.readInt8(), equals(-1));
    });

    test('readBool variations', () {
      reader.addChunk([0, 1, 42]);
      expect(reader.readBool(), isFalse);
      expect(reader.readBool(), isTrue);
      expect(reader.readBool(), isTrue);
    });

    test('readInt16 across chunks', () {
      reader
        ..addChunk([0xFF])
        ..addChunk([0xFF]);
      expect(reader.readInt16(), equals(-1));
    });

    test('readUint16 little-endian across chunks', () {
      reader
        ..addChunk([0x01])
        ..addChunk([0x00]);
      expect(reader.readUint16(Endian.little), equals(1));
    });

    test('readInt32 across chunks', () {
      reader
        ..addChunk([0xFF, 0xFF])
        ..addChunk([0xFF, 0xFF]);
      expect(reader.readInt32(), equals(-1));
    });

    test('readUint32 little-endian across chunks', () {
      reader
        ..addChunk([0x01, 0x00])
        ..addChunk([0x00, 0x00]);
      expect(reader.readUint32(Endian.little), equals(1));
    });

    test('readInt64 across chunks', () {
      reader
        ..addChunk([0xFF, 0xFF, 0xFF, 0xFF])
        ..addChunk([0xFF, 0xFF, 0xFF, 0xFF]);
      expect(reader.readInt64(), equals(-1));
    });

    test('readUint64 little-endian across chunks', () {
      reader
        ..addChunk([0x01, 0x00, 0x00, 0x00])
        ..addChunk([0x00, 0x00, 0x00, 0x00]);
      expect(reader.readUint64(Endian.little), equals(1));
    });

    test('readFloat32 across chunks', () {
      final writer = BinaryWriter()..writeFloat32(3.14);
      final bytes = writer.takeBytes();
      reader
        ..addChunk(bytes.sublist(0, 2))
        ..addChunk(bytes.sublist(2));
      expect(reader.readFloat32(), closeTo(3.14, 0.001));
    });

    test('readFloat64 across chunks', () {
      final writer = BinaryWriter()..writeFloat64(3.14159);
      final bytes = writer.takeBytes();
      reader
        ..addChunk(bytes.sublist(0, 4))
        ..addChunk(bytes.sublist(4));
      expect(reader.readFloat64(), closeTo(3.14159, 0.00001));
    });

    test('readVarInt across chunks', () {
      final writer = BinaryWriter()..writeVarInt(-300);
      final bytes = writer.takeBytes();
      for (final b in bytes) {
        reader.addChunk([b]);
      }
      expect(reader.readVarInt(), equals(-300));
    });

    test('readRemainingBytes across multiple chunks', () {
      reader
        ..addChunk([1, 2])
        ..addChunk([3, 4])
        ..addChunk([5]);
      final bytes = reader.readRemainingBytes();
      expect(bytes, equals([1, 2, 3, 4, 5]));
      expect(reader.availableBytes, equals(0));
    });

    test('readVarBytes across chunks', () {
      final writer = BinaryWriter()..writeVarBytes([10, 20, 30]);
      final bytes = writer.takeBytes();
      reader
        ..addChunk(bytes.sublist(0, 2))
        ..addChunk(bytes.sublist(2));
      expect(reader.readVarBytes(), equals([10, 20, 30]));
    });

    test('readString with allowMalformed across chunks', () {
      // Cyrillic 'П' is [0xD0, 0x9F]
      reader
        ..addChunk([0xD0])
        ..addChunk([0x9F]);
      expect(reader.readString(2, allowMalformed: true), equals('П'));
    });

    test('Validation: negative length throws RangeError', () {
      expect(() => reader.readBytes(-1), throwsRangeError);
      expect(() => reader.readString(-1), throwsRangeError);
      expect(() => reader.skip(-1), throwsRangeError);
      expect(() => reader.hasBytes(-1), throwsRangeError);
    });

    test('Pruning logic with multiple chunks', () {
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

    test('Bookmark growth logic', () {
      // Force bookmark array growth (initial size is 16)
      for (var i = 0; i < 20; i++) {
        reader.bookmark();
      }
      expect(reader.readUint8, throwsA(isA<NotEnoughDataException>()));
    });

    test('rollback with no currentReader', () {
      reader.bookmark();
      expect(() => reader.rollback(), returnsNormally);
    });

    test('readVarUint too long throws FormatException', () {
      reader.addChunk(List.filled(11, 0x80));
      expect(() => reader.readVarUint(), throwsFormatException);
    });
  });

  group('BinaryStreamTransformer Coverage', () {
    test('catch error in parseLoop', () async {
      final controller = StreamController<List<int>>();
      final transformer = _ErrorTransformer();
      final stream = controller.stream.transform(transformer);

      controller.add([1, 2, 3]);

      expect(stream.first, throwsException);
      await controller.close();
    });

    test('parse returning null waits for more data', () async {
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
