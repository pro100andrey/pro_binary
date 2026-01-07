import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

/// Benchmark for writing Uint8
class Uint8WriteBenchmark extends BenchmarkBase {
  Uint8WriteBenchmark() : super('Uint8 write');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 8192);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      writer.writeUint8(i % 256);
    }
    writer.reset();
  }
}

/// Benchmark for writing Int8
class Int8WriteBenchmark extends BenchmarkBase {
  Int8WriteBenchmark() : super('Int8 write');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 8192);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      writer.writeInt8((i % 256) - 128);
    }
    writer.reset();
  }
}

/// Benchmark for writing Uint16 big-endian
class Uint16BigEndianWriteBenchmark extends BenchmarkBase {
  Uint16BigEndianWriteBenchmark() : super('Uint16 write (big-endian)');

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
      writer.writeUint16(i % 65536);
    }
    writer.reset();
  }
}

/// Benchmark for writing Uint16 little-endian
class Uint16LittleEndianWriteBenchmark extends BenchmarkBase {
  Uint16LittleEndianWriteBenchmark() : super('Uint16 write (little-endian)');

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
      writer.writeUint16(i % 65536, .little);
    }
    writer.reset();
  }
}

/// Benchmark for writing Int16 big-endian
class Int16BigEndianWriteBenchmark extends BenchmarkBase {
  Int16BigEndianWriteBenchmark() : super('Int16 write (big-endian)');

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
      writer.writeInt16((i % 65536) - 32768);
    }
    writer.reset();
  }
}

/// Benchmark for writing Int16 little-endian
class Int16LittleEndianWriteBenchmark extends BenchmarkBase {
  Int16LittleEndianWriteBenchmark() : super('Int16 write (little-endian)');

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
      writer.writeInt16((i % 65536) - 32768, .little);
    }
    writer.reset();
  }
}

/// Benchmark for writing Uint32 big-endian
class Uint32BigEndianWriteBenchmark extends BenchmarkBase {
  Uint32BigEndianWriteBenchmark() : super('Uint32 write (big-endian)');

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
      writer.writeUint32(i * 1000);
    }
    writer.reset();
  }
}

/// Benchmark for writing Uint32 little-endian
class Uint32LittleEndianWriteBenchmark extends BenchmarkBase {
  Uint32LittleEndianWriteBenchmark() : super('Uint32 write (little-endian)');

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
      writer.writeUint32(i * 1000, .little);
    }
    writer.reset();
  }
}

/// Benchmark for writing Int32 big-endian
class Int32BigEndianWriteBenchmark extends BenchmarkBase {
  Int32BigEndianWriteBenchmark() : super('Int32 write (big-endian)');

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
      writer.writeInt32(i * 1000 - 500000);
    }
    writer.reset();
  }
}

/// Benchmark for writing Int32 little-endian
class Int32LittleEndianWriteBenchmark extends BenchmarkBase {
  Int32LittleEndianWriteBenchmark() : super('Int32 write (little-endian)');

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
      writer.writeInt32(i * 1000 - 500000, .little);
    }
    writer.reset();
  }
}

/// Benchmark for writing Uint64 big-endian
class Uint64BigEndianWriteBenchmark extends BenchmarkBase {
  Uint64BigEndianWriteBenchmark() : super('Uint64 write (big-endian)');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 65536);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      writer.writeUint64(i * 1000000);
    }
    writer.reset();
  }
}

/// Benchmark for writing Uint64 little-endian
class Uint64LittleEndianWriteBenchmark extends BenchmarkBase {
  Uint64LittleEndianWriteBenchmark() : super('Uint64 write (little-endian)');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 65536);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      writer.writeUint64(i * 1000000, .little);
    }
    writer.reset();
  }
}

/// Benchmark for writing Int64 big-endian
class Int64BigEndianWriteBenchmark extends BenchmarkBase {
  Int64BigEndianWriteBenchmark() : super('Int64 write (big-endian)');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 65536);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      writer.writeInt64(i * 1000000 - 500000000);
    }
    writer.reset();
  }
}

/// Benchmark for writing Int64 little-endian
class Int64LittleEndianWriteBenchmark extends BenchmarkBase {
  Int64LittleEndianWriteBenchmark() : super('Int64 write (little-endian)');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 65536);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      writer.writeInt64(i * 1000000 - 500000000, .little);
    }
    writer.reset();
  }
}

/// Benchmark for mixed fixed-int writes (realistic scenario)
class MixedFixedIntWriteBenchmark extends BenchmarkBase {
  MixedFixedIntWriteBenchmark() : super('Mixed fixed-int write (realistic)');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 65536);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 100; i++) {
      writer
        ..writeUint8(i % 256)
        ..writeUint16(i % 65536, .little)
        ..writeUint32(i * 1000, .little)
        ..writeInt32(i * 100 - 5000, .little)
        ..writeUint64(i * 1000000, .little)
        ..writeInt8((i % 256) - 128)
        ..writeInt16((i % 32768) - 16384, .little)
        ..writeInt64(i * 1000000, .little);
    }
    writer.reset();
  }
}

void main() {
  test('8-bit integer benchmarks:', () {
    Uint8WriteBenchmark().report();
    Int8WriteBenchmark().report();
  }, tags: ['benchmark']);

  test('16-bit integer benchmarks:', () {
    Uint16BigEndianWriteBenchmark().report();
    Uint16LittleEndianWriteBenchmark().report();
    Int16BigEndianWriteBenchmark().report();
    Int16LittleEndianWriteBenchmark().report();
  }, tags: ['benchmark']);

  test('32-bit integer benchmarks:', () {
    Uint32BigEndianWriteBenchmark().report();
    Uint32LittleEndianWriteBenchmark().report();
    Int32BigEndianWriteBenchmark().report();
    Int32LittleEndianWriteBenchmark().report();
  }, tags: ['benchmark']);

  test('64-bit integer benchmarks:', () {
    Uint64BigEndianWriteBenchmark().report();
    Uint64LittleEndianWriteBenchmark().report();
    Int64BigEndianWriteBenchmark().report();
    Int64LittleEndianWriteBenchmark().report();
  }, tags: ['benchmark']);

  test('Mixed integer benchmarks:', () {
    MixedFixedIntWriteBenchmark().report();
  }, tags: ['benchmark']);
}
