import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:pro_binary/pro_binary.dart';

/// Benchmark for writing mixed data types
class MixedWriteBenchmark extends BenchmarkBase {
  MixedWriteBenchmark() : super('Mixed write (all types)');

  late BinaryWriter writer;

  @override
  void setup() => writer = BinaryWriter();

  @override
  void run() {
    writer
      ..writeUint8(42)
      ..writeInt8(-42)
      ..writeUint16(65535, Endian.little)
      ..writeInt16(-32768, Endian.little)
      ..writeUint32(4294967295, Endian.little)
      ..writeInt32(-2147483648, Endian.little)
      ..writeUint64(9223372036854775807, Endian.little)
      ..writeInt64(-9223372036854775808, Endian.little)
      ..writeFloat32(3.14, Endian.little)
      ..writeFloat64(3.141592653589793, Endian.little)
      ..writeBytes([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 100, 200, 255])
      ..writeString('Hello, World!')
      ..clear();
  }
}

/// Benchmark for writing many small integers
class IntegerWriteBenchmark extends BenchmarkBase {
  IntegerWriteBenchmark() : super('Sequential uint8 writes');

  late BinaryWriter writer;

  @override
  void setup() => writer = BinaryWriter();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      writer.writeUint8(i % 256);
    }
    writer.clear();
  }
}

/// Benchmark for writing large byte arrays
class ByteArrayWriteBenchmark extends BenchmarkBase {
  ByteArrayWriteBenchmark() : super('Large byte array writes');

  late BinaryWriter writer;
  late Uint8List largeArray;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 256);
    largeArray = Uint8List(1000);
    for (var i = 0; i < largeArray.length; i++) {
      largeArray[i] = i % 256;
    }
  }

  @override
  void run() {
    // Write 10 chunks of 1000 bytes
    for (var i = 0; i < 10; i++) {
      writer.writeBytes(largeArray);
    }
    writer.clear();
  }
}

/// Benchmark for writing strings
class StringWriteBenchmark extends BenchmarkBase {
  StringWriteBenchmark() : super('String writes (UTF-8)');

  late BinaryWriter writer;
  static const testString = 'Hello, World! 你好世界 🚀';

  @override
  void setup() => writer = BinaryWriter();

  @override
  void run() {
    for (var i = 0; i < 100; i++) {
      writer.writeString(testString);
    }
    writer.clear();
  }
}

/// Benchmark for buffer reallocation
class BufferGrowthBenchmark extends BenchmarkBase {
  BufferGrowthBenchmark() : super('Buffer growth (reallocation)');

  late BinaryWriter writer;

  @override
  void setup() => writer = BinaryWriter(initialBufferSize: 8);

  @override
  void run() {
    // Force multiple reallocations
    for (var i = 0; i < 1000; i++) {
      writer.writeUint32(i);
    }
    writer.clear();
  }
}

/// Benchmark for toBytes vs takeBytes
class BufferOperationsBenchmark extends BenchmarkBase {
  BufferOperationsBenchmark() : super('toBytes() operations');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter();
    for (var i = 0; i < 100; i++) {
      writer.writeUint8(i);
    }
  }

  @override
  void run() {
    // Call toBytes multiple times (doesn't reset)
    for (var i = 0; i < 100; i++) {
      writer.toBytes();
    }
  }
}

void main() {
  final benchmarks = [
    MixedWriteBenchmark(),
    IntegerWriteBenchmark(),
    ByteArrayWriteBenchmark(),
    StringWriteBenchmark(),
    BufferGrowthBenchmark(),
    BufferOperationsBenchmark(),
  ];

  for (final benchmark in benchmarks) {
    benchmark.report();
  }
}
