import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:pro_binary/pro_binary.dart';

class BinaryReaderBenchmark extends BenchmarkBase {
  BinaryReaderBenchmark(this.iterations)
    : super('BinaryReader performance test');

  final int iterations;

  // Buffer with test data
  final buffer = Uint8List.fromList([
    42, // Uint8
    214, // Int8 (two's complement of -42 is 214)
    255, 255, // Uint16 (65535 in little-endian)
    0, 128, // Int16 (-32768 in little-endian)
    255, 255, 255, 255, // Uint32 (4294967295 in little-endian)
    0, 0, 0, 128, // Int32 (-2147483648 in little-endian)
    255, 255, 255, 255, 255, 255, 255,
    127, // Uint64 (9223372036854775807 in little-endian)
    0, 0, 0, 0, 0, 0, 0, 128, // Int64 (-9223372036854775808 in little-endian)
    195, 245, 72, 64, // Float32 (3.14 in IEEE 754 format, little-endian)
    24, 45, 68, 84, 251, 33, 9,
    64, // Float64 (3.141592653589793 in IEEE 754 format, little-endian)
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 100, 200, 255, // Bytes
    72, 101, 108, 108, 111, 44, 32, 119, 111, 114, 108, 100,
    33,
  ]);

  late final BinaryReader reader;

  @override
  void setup() {
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    for (var i = 0; i < iterations; i++) {
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
        ..readString(13); // length of the byte array
    }
  }
}

void main() {
  BinaryReaderBenchmark(1000).report();
}
