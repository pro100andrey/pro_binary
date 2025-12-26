// Disable lint rule for demonstration purposes
// ignore_for_file: avoid_print

import 'dart:typed_data';

import 'package:pro_binary/pro_binary.dart';

void main() {
  writeExample();
  readExample();
  errorHandlingExample();
  bufferManagementExample();
}

void writeExample() {
  print('=== Writing Binary Data ===');

  final writer = BinaryWriter()
    ..writeUint8(42)
    ..writeInt32(-1000, .little)
    ..writeFloat64(3.14159)
    ..writeString('Hello, World!');

  final bytes = writer.takeBytes();
  print('Written ${bytes.length} bytes: $bytes\n');
}

void readExample() {
  print('=== Reading Binary Data ===');

  final buffer = Uint8List.fromList([
    42, 24, 252, 255, 255, // uint8 + int32
    31, 133, 235, 81, 184, 30, 9, 64, // float64
    72, 101, 108, 108, 111, // "Hello"
  ]);

  final reader = BinaryReader(buffer);

  print('uint8:   ${reader.readUint8()}');
  print('int32:   ${reader.readInt32(.little)}');
  print('float64: ${reader.readFloat64()}');
  print('string:  ${reader.readString(5)}');
  print('Position: ${reader.offset}/${buffer.length}\n');
}

void errorHandlingExample() {
  print('=== Error Handling ===');

  final buffer = Uint8List(2); // Only 2 bytes
  final reader = BinaryReader(buffer);

  try {
    reader.readUint32(); // Needs 4 bytes
  } on Object catch (e) {
    print('Caught: $e\n');
  }
}

void bufferManagementExample() {
  print('=== Buffer Management ===');

  final writer = BinaryWriter()
    ..writeUint8(1)
    ..writeUint8(2);

  // Inspect without consuming
  print('Current buffer: ${writer.toBytes()}');

  writer.writeUint8(3);
  print('After adding: ${writer.toBytes()}');

  // Take and reset
  final result = writer.takeBytes();
  print('Final result: $result');
  print('After takeBytes: ${writer.toBytes()}');
}
