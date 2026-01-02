import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

/// Benchmark for reading Uint8 (1 byte unsigned)
///
/// Most basic read operation - single byte access without endianness concerns.
/// Should be the fastest fixed-int read operation.
class Uint8ReadBenchmark extends BenchmarkBase {
  Uint8ReadBenchmark() : super('Uint8 read');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter(initialBufferSize: 8192);
    // Write 1000 Uint8 values
    for (var i = 0; i < 1000; i++) {
      writer.writeUint8(i % 256);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readUint8();
    }
    reader.reset();
  }
}

/// Benchmark for reading Int8 (1 byte signed)
class Int8ReadBenchmark extends BenchmarkBase {
  Int8ReadBenchmark() : super('Int8 read');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter(initialBufferSize: 8192);
    // Write 1000 Int8 values
    for (var i = 0; i < 1000; i++) {
      writer.writeInt8((i % 256) - 128); // Range: -128 to 127
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readInt8();
    }
    reader.reset();
  }
}

/// Benchmark for reading Uint16 in big-endian format
class Uint16BigEndianReadBenchmark extends BenchmarkBase {
  Uint16BigEndianReadBenchmark() : super('Uint16 read (big-endian)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter(initialBufferSize: 8192);
    // Write 1000 Uint16 values
    for (var i = 0; i < 1000; i++) {
      writer.writeUint16((i * 257) % 65536); // Varied values
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readUint16();
    }
    reader.reset();
  }
}

/// Benchmark for reading Uint16 in little-endian format
class Uint16LittleEndianReadBenchmark extends BenchmarkBase {
  Uint16LittleEndianReadBenchmark() : super('Uint16 read (little-endian)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter(initialBufferSize: 8192);
    // Write 1000 Uint16 values in little-endian
    for (var i = 0; i < 1000; i++) {
      writer.writeUint16((i * 257) % 65536, .little);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readUint16(.little);
    }
    reader.reset();
  }
}

/// Benchmark for reading Int16 in big-endian format
class Int16BigEndianReadBenchmark extends BenchmarkBase {
  Int16BigEndianReadBenchmark() : super('Int16 read (big-endian)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter(initialBufferSize: 8192);
    // Write 1000 Int16 values
    for (var i = 0; i < 1000; i++) {
      writer.writeInt16((i * 257) % 65536 - 32768); // Range: -32768 to 32767
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readInt16();
    }
    reader.reset();
  }
}

/// Benchmark for reading Int16 in little-endian format
class Int16LittleEndianReadBenchmark extends BenchmarkBase {
  Int16LittleEndianReadBenchmark() : super('Int16 read (little-endian)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter(initialBufferSize: 8192);
    // Write 1000 Int16 values in little-endian
    for (var i = 0; i < 1000; i++) {
      writer.writeInt16((i * 257) % 65536 - 32768, .little);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readInt16(.little);
    }
    reader.reset();
  }
}

/// Benchmark for reading Uint32 in big-endian format
class Uint32BigEndianReadBenchmark extends BenchmarkBase {
  Uint32BigEndianReadBenchmark() : super('Uint32 read (big-endian)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter(initialBufferSize: 8192);
    // Write 1000 Uint32 values
    for (var i = 0; i < 1000; i++) {
      writer.writeUint32((i * 1000000 + i * 123) % 4294967296);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readUint32();
    }
    reader.reset();
  }
}

/// Benchmark for reading Uint32 in little-endian format
class Uint32LittleEndianReadBenchmark extends BenchmarkBase {
  Uint32LittleEndianReadBenchmark() : super('Uint32 read (little-endian)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter(initialBufferSize: 8192);
    // Write 1000 Uint32 values in little-endian
    for (var i = 0; i < 1000; i++) {
      writer.writeUint32((i * 1000000 + i * 123) % 4294967296, .little);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readUint32(.little);
    }
    reader.reset();
  }
}

/// Benchmark for reading Int32 in big-endian format
class Int32BigEndianReadBenchmark extends BenchmarkBase {
  Int32BigEndianReadBenchmark() : super('Int32 read (big-endian)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter(initialBufferSize: 8192);
    // Write 1000 Int32 values
    for (var i = 0; i < 1000; i++) {
      writer.writeInt32((i * 1000000 + i * 123) % 4294967296 - 2147483648);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readInt32();
    }
    reader.reset();
  }
}

/// Benchmark for reading Int32 in little-endian format
class Int32LittleEndianReadBenchmark extends BenchmarkBase {
  Int32LittleEndianReadBenchmark() : super('Int32 read (little-endian)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter(initialBufferSize: 8192);
    // Write 1000 Int32 values in little-endian
    for (var i = 0; i < 1000; i++) {
      writer.writeInt32(
        (i * 1000000 + i * 123) % 4294967296 - 2147483648,
        .little,
      );
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readInt32(.little);
    }
    reader.reset();
  }
}

/// Benchmark for reading Uint64 in big-endian format
class Uint64BigEndianReadBenchmark extends BenchmarkBase {
  Uint64BigEndianReadBenchmark() : super('Uint64 read (big-endian)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter(initialBufferSize: 8192);
    // Write 1000 Uint64 values
    for (var i = 0; i < 1000; i++) {
      writer.writeUint64(i * 1000000000 + i * 12345);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readUint64();
    }
    reader.reset();
  }
}

/// Benchmark for reading Uint64 in little-endian format
class Uint64LittleEndianReadBenchmark extends BenchmarkBase {
  Uint64LittleEndianReadBenchmark() : super('Uint64 read (little-endian)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter(initialBufferSize: 8192);
    // Write 1000 Uint64 values in little-endian
    for (var i = 0; i < 1000; i++) {
      writer.writeUint64(i * 1000000000 + i * 12345, .little);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readUint64(.little);
    }
    reader.reset();
  }
}

/// Benchmark for reading Int64 in big-endian format
class Int64BigEndianReadBenchmark extends BenchmarkBase {
  Int64BigEndianReadBenchmark() : super('Int64 read (big-endian)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter(initialBufferSize: 8192);
    // Write 1000 Int64 values
    for (var i = 0; i < 1000; i++) {
      final value = i.isEven
          ? (i * 1000000000 + i * 12345)
          : -(i * 1000000000 + i * 12345);
      writer.writeInt64(value);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readInt64();
    }
    reader.reset();
  }
}

/// Benchmark for reading Int64 in little-endian format
class Int64LittleEndianReadBenchmark extends BenchmarkBase {
  Int64LittleEndianReadBenchmark() : super('Int64 read (little-endian)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter(initialBufferSize: 8192);
    // Write 1000 Int64 values in little-endian
    for (var i = 0; i < 1000; i++) {
      final value = i.isEven
          ? (i * 1000000000 + i * 12345)
          : -(i * 1000000000 + i * 12345);
      writer.writeInt64(value, .little);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readInt64(.little);
    }
    reader.reset();
  }
}

/// Benchmark for reading mixed fixed-width integers (realistic scenario)
///
/// Simulates real-world protocol where various integer sizes are mixed.
/// Uses little-endian as it's more common in modern protocols.
class MixedFixedIntReadBenchmark extends BenchmarkBase {
  MixedFixedIntReadBenchmark() : super('Mixed fixed-int read (realistic)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter(initialBufferSize: 8192);
    // Write mixed integer types as they might appear in a real protocol
    for (var i = 0; i < 1000; i++) {
      writer
        ..writeUint8(127) // Message type
        ..writeUint16(10, .little) // Length
        ..writeUint32(1000, .little) // ID
        ..writeInt32(-100, .little) // Signed value
        ..writeUint64(1000000000, .little) // Timestamp
        ..writeInt8(64) // Small signed value
        ..writeInt16(-1000, .little) // Medium signed value
        ..writeInt64(-10000000, .little); // Large signed value
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader
        ..readUint8()
        ..readUint16(.little)
        ..readUint32(.little)
        ..readInt32(.little)
        ..readUint64(.little)
        ..readInt8()
        ..readInt16(.little)
        ..readInt64(.little);
    }
    reader.reset();
  }
}

void main() {
  test('8-bit integer benchmarks:', () {
    Uint8ReadBenchmark().report();
    Int8ReadBenchmark().report();
  }, tags: ['benchmark']);

  test('16-bit integer benchmarks:', () {
    Uint16BigEndianReadBenchmark().report();
    Uint16LittleEndianReadBenchmark().report();
    Int16BigEndianReadBenchmark().report();
    Int16LittleEndianReadBenchmark().report();
  }, tags: ['benchmark']);

  test('32-bit integer benchmarks:', () {
    Uint32BigEndianReadBenchmark().report();
    Uint32LittleEndianReadBenchmark().report();
    Int32BigEndianReadBenchmark().report();
    Int32LittleEndianReadBenchmark().report();
  }, tags: ['benchmark']);

  test('64-bit integer benchmarks:', () {
    Uint64BigEndianReadBenchmark().report();
    Uint64LittleEndianReadBenchmark().report();
    Int64BigEndianReadBenchmark().report();
    Int64LittleEndianReadBenchmark().report();
  }, tags: ['benchmark']);

  test('Mixed integer benchmarks:', () {
    MixedFixedIntReadBenchmark().report();
  }, tags: ['benchmark']);
}
