import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

/// Benchmark for reading Float32 in big-endian format
///
/// Float32 (IEEE 754 single precision) is commonly used for graphics,
/// game data, and scientific computing where memory efficiency matters.
class Float32BigEndianReadBenchmark extends BenchmarkBase {
  Float32BigEndianReadBenchmark() : super('Float32 read (big-endian)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter(initialBufferSize: 8192);
    // Write 1000 Float32 values with varied magnitudes
    for (var i = 0; i < 1000; i++) {
      final value = (i * 3.14159) - 500.0;
      writer.writeFloat32(value);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readFloat32();
    }
    reader.reset();
  }
}

/// Benchmark for reading Float32 in little-endian format
class Float32LittleEndianReadBenchmark extends BenchmarkBase {
  Float32LittleEndianReadBenchmark() : super('Float32 read (little-endian)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter(initialBufferSize: 8192);
    // Write 1000 Float32 values in little-endian
    for (var i = 0; i < 1000; i++) {
      final value = (i * 3.14159) - 500.0;
      writer.writeFloat32(value, .little);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readFloat32(.little);
    }
    reader.reset();
  }
}

/// Benchmark for reading Float64 in big-endian format
///
/// Float64 (IEEE 754 double precision) is the default floating-point type
/// in Dart and most high-level languages. Used for general-purpose math.
class Float64BigEndianReadBenchmark extends BenchmarkBase {
  Float64BigEndianReadBenchmark() : super('Float64 read (big-endian)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter(initialBufferSize: 8192);
    // Write 1000 Float64 values with varied magnitudes
    for (var i = 0; i < 1000; i++) {
      final value = (i * 2.718281828) - 1000.0;
      writer.writeFloat64(value);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readFloat64();
    }
    reader.reset();
  }
}

/// Benchmark for reading Float64 in little-endian format
class Float64LittleEndianReadBenchmark extends BenchmarkBase {
  Float64LittleEndianReadBenchmark() : super('Float64 read (little-endian)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter(initialBufferSize: 8192);
    // Write 1000 Float64 values in little-endian
    for (var i = 0; i < 1000; i++) {
      final value = (i * 2.718281828) - 1000.0;
      writer.writeFloat64(value, .little);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readFloat64(.little);
    }
    reader.reset();
  }
}

/// Benchmark for reading Float32 special values (NaN, Infinity)
///
/// Special IEEE 754 values may have different performance characteristics
/// due to how hardware handles them.
class Float32SpecialValuesReadBenchmark extends BenchmarkBase {
  Float32SpecialValuesReadBenchmark() : super('Float32 read (special values)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter(initialBufferSize: 8192);
    // Write special values: NaN, Infinity, -Infinity, -0.0, normal values
    for (var i = 0; i < 200; i++) {
      writer
        ..writeFloat32(double.nan, .little)
        ..writeFloat32(double.infinity, .little)
        ..writeFloat32(double.negativeInfinity, .little)
        ..writeFloat32(-0, .little)
        ..writeFloat32(1, .little);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readFloat32(.little);
    }
    reader.reset();
  }
}

/// Benchmark for reading Float64 special values (NaN, Infinity)
class Float64SpecialValuesReadBenchmark extends BenchmarkBase {
  Float64SpecialValuesReadBenchmark() : super('Float64 read (special values)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter(initialBufferSize: 8192);
    // Write special values: NaN, Infinity, -Infinity, -0.0, normal values
    for (var i = 0; i < 200; i++) {
      writer
        ..writeFloat64(double.nan, .little)
        ..writeFloat64(double.infinity, .little)
        ..writeFloat64(double.negativeInfinity, .little)
        ..writeFloat64(-0, .little)
        ..writeFloat64(1, .little);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readFloat64(.little);
    }
    reader.reset();
  }
}

/// Benchmark for reading Float32 with small values (subnormal range)
///
/// Subnormal numbers (very close to zero) may have different performance.
class Float32SmallValuesReadBenchmark extends BenchmarkBase {
  Float32SmallValuesReadBenchmark() : super('Float32 read (small values)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter(initialBufferSize: 8192);
    // Write very small values near the subnormal range
    for (var i = 0; i < 1000; i++) {
      final value = (i + 1) * 1e-38; // Near Float32 min positive normal
      writer.writeFloat32(value, .little);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readFloat32(.little);
    }
    reader.reset();
  }
}

/// Benchmark for reading Float64 with small values (subnormal range)
class Float64SmallValuesReadBenchmark extends BenchmarkBase {
  Float64SmallValuesReadBenchmark() : super('Float64 read (small values)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter(initialBufferSize: 8192);
    // Write very small values near the subnormal range
    for (var i = 0; i < 1000; i++) {
      final value = (i + 1) * 1e-308; // Near Float64 min positive normal
      writer.writeFloat64(value, .little);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readFloat64(.little);
    }
    reader.reset();
  }
}

/// Benchmark for reading Float32 with large values
class Float32LargeValuesReadBenchmark extends BenchmarkBase {
  Float32LargeValuesReadBenchmark() : super('Float32 read (large values)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter(initialBufferSize: 8192);
    // Write large values near Float32 max
    for (var i = 0; i < 1000; i++) {
      final value = (i + 1) * 1e35; // Near Float32 max (~3.4e38)
      writer.writeFloat32(value, .little);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readFloat32(.little);
    }
    reader.reset();
  }
}

/// Benchmark for reading Float64 with large values
class Float64LargeValuesReadBenchmark extends BenchmarkBase {
  Float64LargeValuesReadBenchmark() : super('Float64 read (large values)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter(initialBufferSize: 8192);
    // Write large values near Float64 max
    for (var i = 0; i < 1000; i++) {
      final value = (i + 1) * 1e305; // Near Float64 max (~1.8e308)
      writer.writeFloat64(value, .little);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readFloat64(.little);
    }
    reader.reset();
  }
}

/// Benchmark for reading mixed Float32 and Float64 (realistic scenario)
///
/// Simulates real-world usage where both precision levels are used.
/// For example: positions (Float32) + precise calculations (Float64).
class MixedFloatReadBenchmark extends BenchmarkBase {
  MixedFloatReadBenchmark() : super('Mixed float read (realistic)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter(initialBufferSize: 8192);
    // Write mixed Float32/Float64 as in a typical game or graphics protocol
    for (var i = 0; i < 100; i++) {
      writer
        // 3D position (Float32 x3)
        ..writeFloat32(i * 1.5, .little)
        ..writeFloat32(i * 2.0, .little)
        ..writeFloat32(i * 0.5, .little)
        // Rotation quaternion (Float32 x4)
        ..writeFloat32(0.707, .little)
        ..writeFloat32(0, .little)
        ..writeFloat32(0.707, .little)
        ..writeFloat32(0, .little)
        // Precise timestamp (Float64)
        ..writeFloat64(i * 1000000.0, .little)
        // Color (Float32 x4 - RGBA)
        ..writeFloat32(0.5, .little)
        ..writeFloat32(0.8, .little)
        ..writeFloat32(0.2, .little)
        ..writeFloat32(1, .little);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    for (var i = 0; i < 100; i++) {
      // Read position
      reader
        ..readFloat32(.little)
        ..readFloat32(.little)
        ..readFloat32(.little)
        // Read rotation
        ..readFloat32(.little)
        ..readFloat32(.little)
        ..readFloat32(.little)
        ..readFloat32(.little)
        // Read timestamp
        ..readFloat64(.little)
        // Read color
        ..readFloat32(.little)
        ..readFloat32(.little)
        ..readFloat32(.little)
        ..readFloat32(.little);
    }
    reader.reset();
  }
}

/// Benchmark for reading alternating Float32/Float64
///
/// Tests performance when switching between 32-bit and 64-bit reads.
class AlternatingFloatReadBenchmark extends BenchmarkBase {
  AlternatingFloatReadBenchmark() : super('Alternating Float32/Float64 read');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter(initialBufferSize: 8192);
    // Alternate between Float32 and Float64
    for (var i = 0; i < 500; i++) {
      writer
        ..writeFloat32(i * 3.14, .little)
        ..writeFloat64(i * 2.718, .little);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    for (var i = 0; i < 500; i++) {
      reader
        ..readFloat32(.little)
        ..readFloat64(.little);
    }
    reader.reset();
  }
}

void main() {
  test('Float32 benchmarks:', () {
    Float32BigEndianReadBenchmark().report();
    Float32LittleEndianReadBenchmark().report();
    Float32SmallValuesReadBenchmark().report();
    Float32LargeValuesReadBenchmark().report();
    Float32SpecialValuesReadBenchmark().report();
  }, tags: ['benchmark']);

  test('Float64 benchmarks:', () {
    Float64BigEndianReadBenchmark().report();
    Float64LittleEndianReadBenchmark().report();
    Float64SmallValuesReadBenchmark().report();
    Float64LargeValuesReadBenchmark().report();
    Float64SpecialValuesReadBenchmark().report();
  }, tags: ['benchmark']);

  test('Mixed float benchmarks:', () {
    MixedFloatReadBenchmark().report();
    AlternatingFloatReadBenchmark().report();
  }, tags: ['benchmark']);
}
