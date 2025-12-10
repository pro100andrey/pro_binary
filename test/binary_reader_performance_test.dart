import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:pro_binary/pro_binary.dart';

/// Benchmark for reading mixed data types
class MixedReadBenchmark extends BenchmarkBase {
  MixedReadBenchmark() : super('Mixed read (all types)');

  final buffer = Uint8List.fromList([
    42, 214, 255, 255, 0, 128, 255, 255, 255, 255, 0, 0, 0, 128, //
    255, 255, 255, 255, 255, 255, 255, 127, 0, 0, 0, 0, 0, 0, 0, 128, //
    195, 245, 72, 64, 24, 45, 68, 84, 251, 33, 9, 64, //
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 100, 200, 255, //
    72, 101, 108, 108, 111, 44, 32, 119, 111, 114, 108, 100, 33, //
  ]);

  late BinaryReader reader;

  @override
  void setup() => reader = BinaryReader(buffer);

  @override
  void run() {
    reader
      ..reset()
      ..readUint8()
      ..readInt8()
      ..readUint16(Endian.little)
      ..readInt16(Endian.little)
      ..readUint32(Endian.little)
      ..readInt32(Endian.little)
      ..readUint64(Endian.little)
      ..readInt64(Endian.little)
      ..readFloat32(Endian.little)
      ..readFloat64(Endian.little)
      ..readBytes(13)
      ..readString(13);
  }
}

/// Benchmark for reading many small integers
class IntegerReadBenchmark extends BenchmarkBase {
  IntegerReadBenchmark() : super('Sequential uint8 reads');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    buffer = Uint8List(1000);
    for (var i = 0; i < buffer.length; i++) {
      buffer[i] = i % 256;
    }
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    reader.reset();
    for (var i = 0; i < 1000; i++) {
      reader.readUint8();
    }
  }
}

/// Benchmark for reading large byte arrays
class ByteArrayReadBenchmark extends BenchmarkBase {
  ByteArrayReadBenchmark() : super('Large byte array reads');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    buffer = Uint8List(10000);
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    reader.reset();
    // Read in chunks of 100 bytes
    for (var i = 0; i < 100; i++) {
      reader.readBytes(100);
    }
  }
}

/// Benchmark for reading strings
class StringReadBenchmark extends BenchmarkBase {
  StringReadBenchmark() : super('String reads (UTF-8)');

  late BinaryReader reader;
  late Uint8List buffer;
  late int stringLength;

  @override
  void setup() {
    // Create a writer to properly encode the strings
    final writer = BinaryWriter();
    const text = 'Hello, World!';
    for (var i = 0; i < 100; i++) {
      writer.writeString(text);
    }
    buffer = writer.toBytes();
    stringLength = text.length;
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    reader.reset();
    for (var i = 0; i < 100; i++) {
      reader.readString(stringLength);
    }
  }
}

void main() {
  final benchmarks = [
    MixedReadBenchmark(),
    IntegerReadBenchmark(),
    ByteArrayReadBenchmark(),
    StringReadBenchmark(),
  ];

  for (final benchmark in benchmarks) {
    benchmark.report();
  }
}
