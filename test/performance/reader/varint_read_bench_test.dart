import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

/// Benchmark for reading VarUint in fast path (single byte: 0-127)
///
/// This is the most common case in real-world protocols where small numbers
/// (lengths, counts, small IDs) dominate. The fast path should be highly
/// optimized as it's hit most frequently.
class VarUintFastPathBenchmark extends BenchmarkBase {
  VarUintFastPathBenchmark() : super('VarUint read: 0-127 (fast path)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter();
    // Write 1000 single-byte VarUints
    for (var i = 0; i < 1000; i++) {
      writer.writeVarUint(i % 128); // Values 0-127
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      final _ = reader.readVarUint();
    }

    reader.reset();
  }
}

/// Benchmark for reading 2-byte VarUint (128-16383)
///
/// Second most common case - covers most typical array lengths,
/// message sizes, and medium-range IDs.
class VarUint2ByteBenchmark extends BenchmarkBase {
  VarUint2ByteBenchmark() : super('VarUint read: 128-16383 (2 bytes)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter();
    // Write 1000 two-byte VarUints
    for (var i = 0; i < 1000; i++) {
      writer.writeVarUint(128 + (i % 100)); // Values 128-227
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      final _ = reader.readVarUint();
    }

    reader.reset();
  }
}

/// Benchmark for reading 3-byte VarUint (16384-2097151)
class VarUint3ByteBenchmark extends BenchmarkBase {
  VarUint3ByteBenchmark() : super('VarUint read: 16384-2097151 (3 bytes)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter();
    // Write 1000 three-byte VarUints
    for (var i = 0; i < 1000; i++) {
      writer.writeVarUint(16384 + (i % 1000) * 100);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      final _ = reader.readVarUint();
    }

    reader.reset();
  }
}

/// Benchmark for reading 4-byte VarUint (2097152-268435455)
class VarUint4ByteBenchmark extends BenchmarkBase {
  VarUint4ByteBenchmark() : super('VarUint read: 2097152-268435455 (4 bytes)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter();
    // Write 1000 four-byte VarUints
    for (var i = 0; i < 1000; i++) {
      writer.writeVarUint(2097152 + (i % 1000) * 10000);
    }

    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      final _ = reader.readVarUint();
    }

    reader.reset();
  }
}

/// Benchmark for reading 5-byte VarUint (268435456+)
///
/// Less common in practice but important for large file sizes,
/// timestamps, or 64-bit IDs.
class VarUint5ByteBenchmark extends BenchmarkBase {
  VarUint5ByteBenchmark() : super('VarUint read: 268435456+ (5 bytes)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter();
    // Write 1000 five-byte VarUints
    for (var i = 0; i < 1000; i++) {
      writer.writeVarUint(268435456 + i * 1000000);
    }

    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      final _ = reader.readVarUint();
    }

    reader.reset();
  }
}

/// Benchmark for reading VarInt with ZigZag encoding (small positive values)
///
/// ZigZag encoding: 0=>0, 1=>2, 2=>4, etc.
/// Tests decoding performance for positive signed integers.
class VarIntPositiveBenchmark extends BenchmarkBase {
  VarIntPositiveBenchmark() : super('VarInt read: positive (ZigZag)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter();
    // Write 1000 positive VarInts
    for (var i = 0; i < 1000; i++) {
      writer.writeVarInt(i % 1000); // Values 0-999
    }

    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      final _ = reader.readVarInt();
    }
    reader.reset();
  }
}

/// Benchmark for reading VarInt with ZigZag encoding (small negative values)
///
/// ZigZag encoding: -1=>1, -2=>3, -3=>5, etc.
/// Tests decoding performance for negative signed integers.
class VarIntNegativeBenchmark extends BenchmarkBase {
  VarIntNegativeBenchmark() : super('VarInt read: negative (ZigZag)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter();
    // Write 1000 negative VarInts
    for (var i = 0; i < 1000; i++) {
      writer.writeVarInt(-(i % 1000 + 1)); // Values -1 to -1000
    }

    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      final _ = reader.readVarInt();
    }

    reader.reset();
  }
}

/// Benchmark for reading mixed VarInt values (positive and negative)
///
/// Realistic scenario where data contains both positive and negative values.
class VarIntMixedBenchmark extends BenchmarkBase {
  VarIntMixedBenchmark() : super('VarInt read: mixed positive/negative');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter(initialBufferSize: 8192);
    // Write 1000 mixed VarInts
    for (var i = 0; i < 1000; i++) {
      final value = i.isEven ? (i ~/ 2) % 100 : -((i ~/ 2) % 100 + 1);
      writer.writeVarInt(value);
    }

    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readVarInt();
    }

    reader.reset();
  }
}

/// Benchmark for reading mixed sizes VarUint (realistic distribution)
///
/// Simulates real-world usage where most values are small (1-2 bytes)
/// but occasionally large values appear.
/// Distribution: 70% single-byte, 20% two-byte, 8% three-byte, 2% four-byte+
class VarUintMixedSizesBenchmark extends BenchmarkBase {
  VarUintMixedSizesBenchmark() : super('VarUint read: mixed sizes (realistic)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter();
    // Write 1000 VarUints with realistic distribution
    for (var i = 0; i < 1000; i++) {
      final mod = i % 100;
      if (mod < 70) {
        // 70% single byte
        writer.writeVarUint(i % 128);
      } else if (mod < 90) {
        // 20% two bytes
        writer.writeVarUint(128 + (i % 1000));
      } else if (mod < 98) {
        // 8% three bytes
        writer.writeVarUint(16384 + (i % 10000));
      } else {
        // 2% four+ bytes
        writer.writeVarUint(2097152 + i * 1000);
      }
    }

    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readVarUint();
    }

    reader.reset();
  }
}

void main() {
  test('VarUint size benchmarks:', () {
    VarUintFastPathBenchmark().report();
    VarUint2ByteBenchmark().report();
    VarUint3ByteBenchmark().report();
    VarUint4ByteBenchmark().report();
    VarUint5ByteBenchmark().report();
  }, tags: ['benchmark']);

  test('VarInt (ZigZag) benchmarks:', () {
    VarIntPositiveBenchmark().report();
    VarIntNegativeBenchmark().report();
    VarIntMixedBenchmark().report();
  }, tags: ['benchmark']);

  test('Realistic scenarios:', () {
    VarUintMixedSizesBenchmark().report();
  }, tags: ['benchmark']);
}
