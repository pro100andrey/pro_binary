import 'dart:async';

import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

class StringMessage {
  StringMessage(this.id, this.text);
  final int id;
  final String text;
}

class MyTransformer extends BinaryStreamTransformer<StringMessage> {
  @override
  StringMessage? parse(StreamBinaryReader reader) {
    final id = reader.readUint32();
    final text = reader.readVarString();
    return StringMessage(id, text);
  }
}

void main() {
  group('BinaryStreamTransformer', () {
    test('parses stream of messages across chunks', () async {
      final writer = BinaryWriter()
        // Message 1
        ..writeUint32(1)
        ..writeVarString('Hello')
        // Message 2
        ..writeUint32(2)
        ..writeVarString('Stream');

      final allBytes = writer.takeBytes();

      final controller = StreamController<List<int>>();
      final stream = controller.stream.transform(MyTransformer());

      final resultsFuture = stream.toList();

      for (var i = 0; i < allBytes.length; i++) {
        controller.add([allBytes[i]]);
      }

      await controller.close();
      final results = await resultsFuture;

      expect(results, hasLength(2));
      expect(results[0].id, equals(1));
      expect(results[0].text, equals('Hello'));
      expect(results[1].id, equals(2));
      expect(results[1].text, equals('Stream'));
    });
  });
}
