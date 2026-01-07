import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

/// Benchmark for buffer growth from small initial size
class BufferGrowthSmallInitialBenchmark extends BenchmarkBase {
  BufferGrowthSmallInitialBenchmark()
    : super('Buffer growth: small initial (16 bytes -> 1KB)');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 16);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    // Write 1KB of data, forcing multiple expansions
    for (var i = 0; i < 256; i++) {
      writer.writeUint32(i);
    }
    writer.reset();
  }
}

/// Benchmark for buffer growth from medium initial size
class BufferGrowthMediumInitialBenchmark extends BenchmarkBase {
  BufferGrowthMediumInitialBenchmark()
    : super('Buffer growth: medium initial (256 bytes -> 64KB)');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 256);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    // Write 64KB of data
    final data = Uint8List.fromList(List.generate(256, (i) => i % 256));
    for (var i = 0; i < 256; i++) {
      writer.writeBytes(data);
    }
    writer.reset();
  }
}

/// Benchmark for buffer growth with incremental writes
class BufferGrowthIncrementalBenchmark extends BenchmarkBase {
  BufferGrowthIncrementalBenchmark()
    : super('Buffer growth: incremental writes');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 64);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    // Write progressively larger chunks
    for (var size = 1; size <= 256; size *= 2) {
      final data = Uint8List.fromList(List.generate(size, (i) => i % 256));
      for (var i = 0; i < 10; i++) {
        writer.writeBytes(data);
      }
    }
    writer.reset();
  }
}

/// Benchmark for buffer growth with large single write
class BufferGrowthLargeSingleWriteBenchmark extends BenchmarkBase {
  BufferGrowthLargeSingleWriteBenchmark()
    : super('Buffer growth: large single write');

  late BinaryWriter writer;
  late Uint8List largeData;

  @override
  void setup() {
    writer = BinaryWriter();
    largeData = Uint8List.fromList(List.generate(32768, (i) => i % 256));
  }

  @override
  void exercise() => run();

  @override
  void run() {
    // Single large write that forces expansion
    writer
      ..writeBytes(largeData)
      ..reset();
  }
}

/// Benchmark for buffer growth with string writes
class BufferGrowthStringWritesBenchmark extends BenchmarkBase {
  BufferGrowthStringWritesBenchmark() : super('Buffer growth: string writes');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 32);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    const testString = 'Hello World! This is a test string.';
    for (var i = 0; i < 500; i++) {
      writer.writeString(testString);
    }
    writer.reset();
  }
}

/// Benchmark for buffer growth with VarInt writes
class BufferGrowthVarIntWritesBenchmark extends BenchmarkBase {
  BufferGrowthVarIntWritesBenchmark() : super('Buffer growth: VarInt writes');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 1024);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 250; i++) {
      writer.writeVarUint(i & 0x7F); // Keep values to 0-127 (single byte)
    }
    writer.reset();
  }
}

/// Benchmark for buffer growth with mixed writes
class BufferGrowthMixedWritesBenchmark extends BenchmarkBase {
  BufferGrowthMixedWritesBenchmark() : super('Buffer growth: mixed data types');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 64);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 200; i++) {
      writer
        ..writeUint8(i % 256)
        ..writeUint32(i * 1000, .little)
        ..writeFloat64(i * 3.14, .little)
        ..writeString('Message $i')
        ..writeVarUint(i);
    }
    writer.reset();
  }
}

/// Benchmark for no buffer growth (sufficient initial size)
class NoBufferGrowthBenchmark extends BenchmarkBase {
  NoBufferGrowthBenchmark()
    : super('No buffer growth: sufficient initial size');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 65536);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    // Write 32KB without triggering growth
    final data = Uint8List.fromList(List.generate(256, (i) => i % 256));
    for (var i = 0; i < 128; i++) {
      writer.writeBytes(data);
    }
    writer.reset();
  }
}

/// Benchmark for buffer growth with VarBytes
class BufferGrowthVarBytesBenchmark extends BenchmarkBase {
  BufferGrowthVarBytesBenchmark() : super('Buffer growth: VarBytes writes');

  late BinaryWriter writer;
  late Uint8List data;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 16 * 1024);
    data = Uint8List.fromList(List.generate(32, (i) => i % 256));
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 100; i++) {
      writer.writeVarBytes(data);
    }
    writer.reset();
  }
}

/// Benchmark for buffer growth pattern: write, reset, write larger
class BufferGrowthResetPatternBenchmark extends BenchmarkBase {
  BufferGrowthResetPatternBenchmark()
    : super('Buffer growth: write-reset-write pattern');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter();
  }

  @override
  void exercise() => run();

  @override
  void run() {
    // First write: small
    for (var i = 0; i < 16; i++) {
      writer.writeUint32(i);
    }
    writer.reset();

    // Second write: medium (may reuse buffer)
    for (var i = 0; i < 64; i++) {
      writer.writeUint32(i);
    }
    writer.reset();

    // Third write: large (may grow buffer)
    for (var i = 0; i < 256; i++) {
      writer.writeUint32(i);
    }
    writer.reset();
  }
}

/// Benchmark for buffer growth with alternating sizes
class BufferGrowthAlternatingSizesBenchmark extends BenchmarkBase {
  BufferGrowthAlternatingSizesBenchmark()
    : super('Buffer growth: alternating write sizes');

  late BinaryWriter writer;
  late Uint8List smallData;
  late Uint8List largeData;

  @override
  void setup() {
    writer = BinaryWriter();
    smallData = Uint8List.fromList(List.generate(8, (i) => i));
    largeData = Uint8List.fromList(List.generate(512, (i) => i % 256));
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 50; i++) {
      writer
        ..writeBytes(smallData)
        ..writeBytes(largeData)
        ..writeBytes(smallData);
    }
    writer.reset();
  }
}

/// Benchmark for buffer growth reaching max reusable capacity
class BufferGrowthMaxCapacityBenchmark extends BenchmarkBase {
  BufferGrowthMaxCapacityBenchmark()
    : super('Buffer growth: reaching max capacity (64KB)');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 1024);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    // Write exactly 64KB to test max reusable capacity
    final data = Uint8List.fromList(List.generate(1024, (i) => i % 256));
    for (var i = 0; i < 64; i++) {
      writer.writeBytes(data);
    }
    writer.reset();
  }
}

void main() {
  test('Initial size variations:', () {
    BufferGrowthSmallInitialBenchmark().report();
    BufferGrowthMediumInitialBenchmark().report();
    NoBufferGrowthBenchmark().report();
  }, tags: ['benchmark']);

  test('Growth patterns:', () {
    BufferGrowthIncrementalBenchmark().report();
    BufferGrowthLargeSingleWriteBenchmark().report();
    BufferGrowthAlternatingSizesBenchmark().report();
  }, tags: ['benchmark']);

  test('Data type specific growth:', () {
    BufferGrowthStringWritesBenchmark().report();
    BufferGrowthVarIntWritesBenchmark().report();
    BufferGrowthVarBytesBenchmark().report();
    BufferGrowthMixedWritesBenchmark().report();
  }, tags: ['benchmark']);

  test('Reset and capacity patterns:', () {
    BufferGrowthResetPatternBenchmark().report();
    BufferGrowthMaxCapacityBenchmark().report();
  }, tags: ['benchmark']);
}
