import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

/// Benchmark for writing VarUint in fast path (0-127)
class VarUintFastPathWriteBenchmark extends BenchmarkBase {
  VarUintFastPathWriteBenchmark() : super('VarUint write: 0-127 (fast path)');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 16384);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      writer.writeVarUint(i % 128);
    }
    writer.reset();
  }
}

/// Benchmark for writing VarUint 2-byte values
class VarUint2ByteWriteBenchmark extends BenchmarkBase {
  VarUint2ByteWriteBenchmark() : super('VarUint write: 128-16383 (2 bytes)');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 16384);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      writer.writeVarUint(128 + (i % 1000));
    }
    writer.reset();
  }
}

/// Benchmark for writing VarUint 3-byte values
class VarUint3ByteWriteBenchmark extends BenchmarkBase {
  VarUint3ByteWriteBenchmark()
    : super('VarUint write: 16384-2097151 (3 bytes)');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 32768);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      writer.writeVarUint(16384 + (i % 10000));
    }
    writer.reset();
  }
}

/// Benchmark for writing VarUint 4-byte values
class VarUint4ByteWriteBenchmark extends BenchmarkBase {
  VarUint4ByteWriteBenchmark()
    : super('VarUint write: 2097152-268435455 (4 bytes)');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 32768);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      writer.writeVarUint(2097152 + (i % 100000));
    }
    writer.reset();
  }
}

/// Benchmark for writing VarUint 5-byte values
class VarUint5ByteWriteBenchmark extends BenchmarkBase {
  VarUint5ByteWriteBenchmark() : super('VarUint write: 268435456+ (5 bytes)');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 32768);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      writer.writeVarUint(268435456 + i);
    }
    writer.reset();
  }
}

/// Benchmark for writing positive VarInt (ZigZag encoded)
class VarIntPositiveWriteBenchmark extends BenchmarkBase {
  VarIntPositiveWriteBenchmark() : super('VarInt write: positive (ZigZag)');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 16384);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      writer.writeVarInt(i);
    }
    writer.reset();
  }
}

/// Benchmark for writing negative VarInt (ZigZag encoded)
class VarIntNegativeWriteBenchmark extends BenchmarkBase {
  VarIntNegativeWriteBenchmark() : super('VarInt write: negative (ZigZag)');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 16384);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      writer.writeVarInt(-(i + 1));
    }
    writer.reset();
  }
}

/// Benchmark for writing mixed positive/negative VarInt
class VarIntMixedWriteBenchmark extends BenchmarkBase {
  VarIntMixedWriteBenchmark() : super('VarInt write: mixed positive/negative');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 16384);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      writer.writeVarInt(i.isEven ? i : -i);
    }
    writer.reset();
  }
}

/// Benchmark for realistic VarUint distribution
class VarUintMixedSizesWriteBenchmark extends BenchmarkBase {
  VarUintMixedSizesWriteBenchmark()
    : super('VarUint write: mixed sizes (realistic)');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 32768);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      final mod = i % 100;
      if (mod < 70) {
        writer.writeVarUint(i % 128);
      } else if (mod < 90) {
        writer.writeVarUint(128 + (i % 1000));
      } else if (mod < 98) {
        writer.writeVarUint(16384 + (i % 10000));
      } else {
        writer.writeVarUint(2097152 + i);
      }
    }
    writer.reset();
  }
}

void main() {
  test('VarUint size benchmarks:', () {
    VarUintFastPathWriteBenchmark().report();
    VarUint2ByteWriteBenchmark().report();
    VarUint3ByteWriteBenchmark().report();
    VarUint4ByteWriteBenchmark().report();
    VarUint5ByteWriteBenchmark().report();
  }, tags: ['benchmark']);

  test('VarInt (ZigZag) benchmarks:', () {
    VarIntPositiveWriteBenchmark().report();
    VarIntNegativeWriteBenchmark().report();
    VarIntMixedWriteBenchmark().report();
  }, tags: ['benchmark']);

  test('Realistic scenarios:', () {
    VarUintMixedSizesWriteBenchmark().report();
  }, tags: ['benchmark']);
}
