import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

/// Benchmark for writing Float32 big-endian
class Float32BigEndianWriteBenchmark extends BenchmarkBase {
  Float32BigEndianWriteBenchmark() : super('Float32 write (big-endian)');

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
      writer.writeFloat32((i * 3.14159) - 500.0);
    }
    writer.reset();
  }
}

/// Benchmark for writing Float32 little-endian
class Float32LittleEndianWriteBenchmark extends BenchmarkBase {
  Float32LittleEndianWriteBenchmark() : super('Float32 write (little-endian)');

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
      writer.writeFloat32((i * 3.14159) - 500.0, .little);
    }
    writer.reset();
  }
}

/// Benchmark for writing Float32 small values
class Float32SmallValuesWriteBenchmark extends BenchmarkBase {
  Float32SmallValuesWriteBenchmark() : super('Float32 write (small values)');

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
      writer.writeFloat32((i % 100) * 0.01, .little);
    }
    writer.reset();
  }
}

/// Benchmark for writing Float32 large values
class Float32LargeValuesWriteBenchmark extends BenchmarkBase {
  Float32LargeValuesWriteBenchmark() : super('Float32 write (large values)');

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
      writer.writeFloat32((i * 1000000.0) - 500000000.0, .little);
    }
    writer.reset();
  }
}

/// Benchmark for writing Float32 special values
class Float32SpecialValuesWriteBenchmark extends BenchmarkBase {
  Float32SpecialValuesWriteBenchmark()
    : super('Float32 write (special values)');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 8192);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 250; i++) {
      writer
        ..writeFloat32(0, .little)
        ..writeFloat32(.nan, .little)
        ..writeFloat32(.infinity, .little)
        ..writeFloat32(.negativeInfinity, .little);
    }
    writer.reset();
  }
}

/// Benchmark for writing Float64 big-endian
class Float64BigEndianWriteBenchmark extends BenchmarkBase {
  Float64BigEndianWriteBenchmark() : super('Float64 write (big-endian)');

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
      writer.writeFloat64((i * 2.718281828) - 1000.0);
    }
    writer.reset();
  }
}

/// Benchmark for writing Float64 little-endian
class Float64LittleEndianWriteBenchmark extends BenchmarkBase {
  Float64LittleEndianWriteBenchmark() : super('Float64 write (little-endian)');

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
      writer.writeFloat64((i * 2.718281828) - 1000.0, .little);
    }
    writer.reset();
  }
}

/// Benchmark for writing Float64 small values
class Float64SmallValuesWriteBenchmark extends BenchmarkBase {
  Float64SmallValuesWriteBenchmark() : super('Float64 write (small values)');

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
      writer.writeFloat64((i % 100) * 0.001, .little);
    }
    writer.reset();
  }
}

/// Benchmark for writing Float64 large values
class Float64LargeValuesWriteBenchmark extends BenchmarkBase {
  Float64LargeValuesWriteBenchmark() : super('Float64 write (large values)');

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
      writer.writeFloat64(
        (i * 1000000000.0) - 500000000000.0,
        .little,
      );
    }
    writer.reset();
  }
}

/// Benchmark for writing Float64 special values
class Float64SpecialValuesWriteBenchmark extends BenchmarkBase {
  Float64SpecialValuesWriteBenchmark()
    : super('Float64 write (special values)');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 16384);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 250; i++) {
      writer
        ..writeFloat64(0, .little)
        ..writeFloat64(.nan, .little)
        ..writeFloat64(.infinity, .little)
        ..writeFloat64(.negativeInfinity, .little);
    }
    writer.reset();
  }
}

/// Benchmark for mixed float writes (realistic scenario)
class MixedFloatWriteBenchmark extends BenchmarkBase {
  MixedFloatWriteBenchmark() : super('Mixed float write (realistic)');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 32768);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 100; i++) {
      writer
        // Position (3D coordinates)
        ..writeFloat32(i * 10.0, .little)
        ..writeFloat32(i * 20.0, .little)
        ..writeFloat32(i * 30.0, .little)
        // Rotation (quaternion)
        ..writeFloat32(0, .little)
        ..writeFloat32(0, .little)
        ..writeFloat32(0, .little)
        ..writeFloat32(1, .little)
        // Timestamp
        ..writeFloat64(i * 0.016, .little)
        // Color (RGBA)
        ..writeFloat32(1, .little)
        ..writeFloat32(0.5, .little)
        ..writeFloat32(0, .little)
        ..writeFloat32(1, .little);
    }
    writer.reset();
  }
}

/// Benchmark for alternating Float32/Float64
class AlternatingFloatWriteBenchmark extends BenchmarkBase {
  AlternatingFloatWriteBenchmark() : super('Alternating Float32/Float64 write');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 16384);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 500; i++) {
      writer
        ..writeFloat32(i * 3.14, .little)
        ..writeFloat64(i * 2.718, .little);
    }
    writer.reset();
  }
}

void main() {
  test('Float32 benchmarks:', () {
    Float32BigEndianWriteBenchmark().report();
    Float32LittleEndianWriteBenchmark().report();
    Float32SmallValuesWriteBenchmark().report();
    Float32LargeValuesWriteBenchmark().report();
    Float32SpecialValuesWriteBenchmark().report();
  }, tags: ['benchmark']);

  test('Float64 benchmarks:', () {
    Float64BigEndianWriteBenchmark().report();
    Float64LittleEndianWriteBenchmark().report();
    Float64SmallValuesWriteBenchmark().report();
    Float64LargeValuesWriteBenchmark().report();
    Float64SpecialValuesWriteBenchmark().report();
  }, tags: ['benchmark']);

  test('Mixed float benchmarks:', () {
    MixedFloatWriteBenchmark().report();
    AlternatingFloatWriteBenchmark().report();
  }, tags: ['benchmark']);
}
