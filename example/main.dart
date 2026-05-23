// Example demonstrating best practices for using `pro_binary` in a Dart
// ignore_for_file: avoid_print
import 'package:pro_binary/pro_binary.dart';

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

  /// Recommended pattern: Static method for serialization.
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

void main() {
  // 1. Using the high-level Pool API (Best for performance)
  print('Step 1: Serializing via Pool...');
  final bytes = BinaryWriterPool.withWriter((writer) {
    User(id: 101, name: 'Dart 🚀', isActive: true, score: 99.5).encode(writer);
    return writer.toBytes(); // View of the pooled buffer
  });

  print('Serialized length: ${bytes.length} bytes\n');

  // 2. Using the Concise API for reading
  print('Step 2: Deserializing...');
  final reader = BinaryReader(bytes);

  // Concise peek via operator []
  final firstByte = reader[0];
  print('Peek first byte: 0x${firstByte.toRadixString(16).padLeft(2, '0')}');

  final decodedUser = User.decode(reader);
  print('Decoded user: $decodedUser\n');

  // 3. Concise byte operations (Callable syntax)
  print('Step 3: Concise data writing...');
  final writer = BinaryWriter();
  writer([0xAA, 0xBB, 0xCC]); // Shorthand for writeBytes

  final r2 = BinaryReader(writer.takeBytes());
  print('Read back 2 bytes concisely: ${r2(2)}'); // Shorthand for readBytes(2)

  print('\nAll examples completed successfully!');
}
