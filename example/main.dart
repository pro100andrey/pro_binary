// Example demonstrating best practices for using `pro_binary` in Dart.
// ignore_for_file: unreachable_from_main
import 'dart:io';
import 'dart:typed_data';

import 'package:pro_binary/pro_binary.dart';

void main() {
  // 1. Pool API — recommended for high-frequency writes
  log('1. Pool API');

  final bytes = BinaryWriterPool.withWriter((writer) {
    User(id: 101, name: 'Dart 🚀', isActive: true, score: 99.5).encode(writer);
    return writer.toBytes();
  });

  log('Serialized: ${bytes.length} bytes');

  // 2. Deserialization with navigation
  log('\n2. Navigation');
  final reader = BinaryReader(bytes);

  // Peek without consuming
  log('First byte: 0x${reader[0].toRadixString(16).padLeft(2, '0')}');
  log('Peek 4 bytes: ${reader.peekBytes(4)}');

  // Read and navigate
  final user = User.decode(reader);
  log('Decoded: $user');

  // Rebind reader to new data (reuse without allocation)
  final moreData = Uint8List.fromList([1, 0, 0, 0, 42]);
  reader.rebind(moreData);
  log('Rebound, read: ${reader.readUint8()}');

  // 3. Writer reuse with reset
  log('\n3. Writer Reuse');
  final writer = BinaryWriter()
    ..writeVarUint(1)
    ..writeVarString('first');
  final first = writer.takeBytes(); // Resets writer
  log('First batch: ${first.length} bytes');

  writer
    ..writeVarUint(2)
    ..writeVarString('second');
  final second = writer.takeBytes();
  log('Second batch: ${second.length} bytes');

  // 4. Signed VarInt (ZigZag) — efficient for deltas
  log('\n4. Signed VarInt (ZigZag)');
  final deltaWriter = BinaryWriter();
  for (final delta in [0, -1, 1, -42, 42, -1000, 1000]) {
    deltaWriter.writeVarInt(delta);
  }
  final deltaBytes = deltaWriter.takeBytes();
  log('Encoded 7 deltas in ${deltaBytes.length} bytes');

  final deltaReader = BinaryReader(deltaBytes);
  log('Decoded: ${List.generate(7, (_) => deltaReader.readVarInt())}');

  // 5. getUtf8Length utility
  log('\n5. UTF-8 Length');
  const ascii = 'Hello';
  const unicode = 'Hello 世界 🌍';
  log('"$ascii" -> ${getUtf8Length(ascii)} bytes');
  log('"$unicode" -> ${getUtf8Length(unicode)} bytes');

  // 6. Pool statistics
  log('\n6. Pool Stats');
  final stats = BinaryWriterPool.stats;
  log(
    'Pooled: ${stats.pooled}, Hits: ${stats.acquireHit}, '
    'Misses: ${stats.acquireMiss}',
  );
  log('Hit rate: ${(stats.hitRate * 100).toStringAsFixed(1)}%');

  // 7. Stream parsing (requires actual Stream<List<int>>)
  log('\n7. Stream Parsing');
  // In real usage:
  //   stream.transform(MessageParser()).listen((msg) => print(msg));
  log('Use: stream.transform(MessageParser()).listen(...)');

  // 8. Concise callable syntax
  log('\n8. Callable Syntax');
  final cWriter = BinaryWriter();
  cWriter([0xAA, 0xBB, 0xCC, 0xDD]); // writeBytes shorthand
  final cBytes = cWriter.takeBytes();

  final cReader = BinaryReader(cBytes);
  log('Callable read 2 bytes: ${cReader(2)}'); // readBytes shorthand

  // 9. fromList convenience
  log('\n9. List<int> Support');
  final listReader = BinaryReader.fromList([0x01, 0x02, 0x03, 0x04]);
  log('From List<int>: ${listReader.readBytes(4)}');

  // 10. takeBytes vs toBytes
  log('\n10. takeBytes vs toBytes');
  final w1 = BinaryWriter()..writeUint32(42);
  final view = w1.toBytes(); // View, writer keeps state
  w1.writeUint32(100);
  log('toBytes() snapshot: ${view.length} bytes');
  log('After more writes: ${w1.takeBytes().length} bytes (writer reset)');

  final w2 = BinaryWriter()..writeUint32(42);
  final owned = w2.takeBytes(); // Resets writer
  log('takeBytes() owns buffer: ${owned.length} bytes');

  log('\nAll examples completed successfully!');
}

void log([Object? object = '']) => stdout.writeln(object);

/// A simple domain model to demonstrate serialization best practices.
class User {
  User({
    required this.id,
    required this.name,
    required this.isActive,
    required this.score,
  });

  /// Recommended pattern: Factory for deserialization.
  factory User.decode(BinaryReader r) => User(
    id: r.readVarUint(),
    name: r.readVarString(),
    isActive: r.readBool(),
    score: r.readFloat64(),
  );

  final int id;
  final String name;
  final bool isActive;
  final double score;

  /// Recommended pattern: Instance method for serialization.
  void encode(BinaryWriter w) {
    w
      ..writeVarUint(id)
      ..writeVarString(name)
      ..writeBool(isActive)
      ..writeFloat64(score);
  }

  @override
  String toString() =>
      'User(id: $id, name: "$name", active: $isActive, score: $score)';
}

/// Message for streaming example.
class Message {
  Message({required this.type, required this.payload});

  factory Message.decode(StreamBinaryReader r) => Message(
    type: r.readUint8(),
    payload: r.readVarString(),
  );

  final int type;
  final String payload;

  void encode(BinaryWriter w) {
    w
      ..writeUint8(type)
      ..writeVarString(payload);
  }

  @override
  String toString() => 'Message(type: $type, payload: "$payload")';
}

/// Stream parser for [Message].
class MessageParser extends BinaryStreamTransformer<Message> {
  @override
  Message? parse(StreamBinaryReader reader) {
    if (!reader.hasBytes(1)) {
      return null;
    }
    return Message.decode(reader);
  }
}
