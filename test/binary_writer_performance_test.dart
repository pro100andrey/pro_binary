import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:pro_binary/src/binary_writer.dart';

class BinaryWriterBenchmark extends BenchmarkBase {
  BinaryWriterBenchmark() : super('BinaryWriter performance test');

  @override
  void run() {
    final writer = BinaryWriter()
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
      ..writeString('Hello, World!');

    final _ = writer.takeBytes();
  }

  @override
  void exercise() => run();

  @override
  void setup() {
    // Set up any initial state here
  }

  @override
  void teardown() {
    // Clean up any resources here
  }
}

void main() {
  BinaryWriterBenchmark().report();
}
