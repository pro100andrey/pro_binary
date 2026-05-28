import 'dart:io';
import 'dart:typed_data';

import 'package:pro_binary/pro_binary.dart';

void main() {
  // 1. Basic Serialization
  final user = User(
    id: 101,
    name: 'Dart 🚀',
    isActive: true,
    level: 5,
    balance: -150, // Demonstrate signed VarInt (ZigZag)
    score: 99.5,
    avatar: Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF]),
  );

  final writer = BinaryWriter();
  user.encode(writer);

  // takeBytes() returns Uint8List and resets writer for reuse
  final bytes = writer.takeBytes();
  _log('Serialization');
  _log('  Encoded: ${bytes.length} bytes');
  // 2. Basic Deserialization
  final reader = BinaryReader(bytes);
  final decodedUser = User.decode(reader);

  _log('\nDeserialization -');
  _log('  Decoded: $decodedUser');
  _log('  Avatar: ${decodedUser.avatar}');

  // 3. Pool API (Recommended for high-frequency operations)
  // Reuses internal buffers to minimize Garbage Collection pressure.
  _log('\nPool API');
  final pooledBytes = BinaryWriterPool.withWriter((w) {
    user.encode(w);
    return w.toBytes(); // toBytes() returns a zero-copy view
  });
  _log('  Pooled serialization done: ${pooledBytes.length} bytes');

  // 4. Navigation & Peeking
  _log('\nNavigation & Peeking');
  final navReader = BinaryReader(pooledBytes);
  // Support for index operator [] (peeking at specific position)
  _log('  Peek byte at index 0: 0x${navReader[0].toRadixString(16)}');
  navReader.skip(1); // Manually move cursor
  _log('  Remaining bytes: ${navReader.availableBytes}');
}

/// A domain model demonstrating diverse data types and serialization patterns.
class User {
  User({
    required this.id,
    required this.name,
    required this.isActive,
    required this.level,
    required this.balance,
    required this.score,
    required this.avatar,
  });

  /// Pattern: Factory for deserialization.
  factory User.decode(BinaryReader r) => User(
    id: r.readVarUint(), // Compact variable-length unsigned int
    name: r.readVarString(), // Length-prefixed UTF-8 string
    isActive: r.readBool(), // 1 byte boolean
    level: r.readUint8(), // Fixed-size 1 byte unsigned int
    balance: r.readVarInt(), // Signed variable-length int (ZigZag)
    score: r.readFloat64(), // 8 byte floating point
    avatar: r.readVarBytes(), // Length-prefixed byte array
  );

  final int id;
  final String name;
  final bool isActive;
  final int level;
  final int balance;
  final double score;
  final Uint8List avatar;

  /// Pattern: Instance method for serialization.
  void encode(BinaryWriter w) {
    w
      ..writeVarUint(id)
      ..writeVarString(name)
      ..writeBool(isActive)
      ..writeUint8(level)
      ..writeVarInt(balance)
      ..writeFloat64(score)
      ..writeVarBytes(avatar);
  }

  @override
  String toString() =>
      'User('
      'id: $id, '
      'name: "$name", '
      'active: $isActive, '
      'lvl: $level, '
      'bal: $balance, '
      'score: $score'
      ')';
}

void _log([Object? object = '']) => stdout.writeln(object);
