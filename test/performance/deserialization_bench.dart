import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:pro_binary/pro_binary.dart';

/// Benchmark for reading a simple message.
class SimpleMessageReadBenchmark extends BenchmarkBase {
  SimpleMessageReadBenchmark() : super('Read: Simple Message');

  late BinaryReader reader;
  late Uint8List buffer;
  var _checksum = 0;

  @override
  void setup() {
    final writer = BinaryWriter()
      ..writeUint32(123456789)
      ..writeFloat32(3.14159)
      ..writeBool(true)
      ..writeInt16(-100)
      ..writeUint8(255);
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    reader.reset();
    _checksum += reader.readUint32();
    _checksum += reader.readFloat32().toInt();
    _checksum += reader.readBool() ? 1 : 0;
    _checksum += reader.readInt16();
    _checksum += reader.readUint8();
  }

  @override
  void teardown() {
    if (_checksum == 0) {
      //
      // ignore: avoid_print
      print('Prevent DCE');
    }
  }
}

/// Benchmark for reading a complex profile.
class ComplexProfileReadBenchmark extends BenchmarkBase {
  ComplexProfileReadBenchmark() : super('Read: Complex Profile');

  late BinaryReader reader;
  late Uint8List buffer;
  var _checksum = 0;

  @override
  void setup() {
    final writer = BinaryWriter()
      ..writeVarUint(1001)
      ..writeVarString('John Alexander Doe')
      ..writeVarString('john.doe.very.long.email.address@example.com')
      ..writeBool(false);

    final scores = List.generate(20, (i) => i * 100);
    writer.writeVarUint(scores.length);
    for (final score in scores) {
      writer.writeVarInt(score);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    reader.reset();
    _checksum += reader.readVarUint();
    _checksum += reader.readVarString().length;
    _checksum += reader.readVarString().length;
    _checksum += reader.readBool() ? 1 : 0;

    final count = reader.readVarUint();
    for (var i = 0; i < count; i++) {
      _checksum += reader.readVarInt();
    }
  }

  @override
  void teardown() {
    if (_checksum == 0) {
      //
      // ignore: avoid_print
      print('Prevent DCE');
    }
  }
}

/// Benchmark for reading large arrays of data.
class LargeArrayReadBenchmark extends BenchmarkBase {
  LargeArrayReadBenchmark() : super('Read: Large Array (10K ints)');

  late BinaryReader reader;
  late Uint8List buffer;
  var _checksum = 0;

  @override
  void setup() {
    final writer = BinaryWriter();
    final data = List.generate(10000, (i) => i);
    writer.writeVarUint(data.length);
    for (final val in data) {
      writer.writeUint32(val);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    reader.reset();
    final count = reader.readVarUint();
    for (var i = 0; i < count; i++) {
      _checksum += reader.readUint32();
    }
  }

  @override
  void teardown() {
    if (_checksum == 0) {
      //
      // ignore: avoid_print
      print('Prevent DCE');
    }
  }
}

void main() {
  SimpleMessageReadBenchmark().report();
  ComplexProfileReadBenchmark().report();
  LargeArrayReadBenchmark().report();
}
