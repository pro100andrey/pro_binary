import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

/// Benchmark for reading small byte arrays (< 16 bytes)
///
/// Small reads are common for fixed-size headers, checksums, and IDs.
class SmallBytesReadBenchmark extends BenchmarkBase {
  SmallBytesReadBenchmark() : super('Bytes read: small (8 bytes)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter();
    final data = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);

    // Write 1000 small byte arrays
    for (var i = 0; i < 1000; i++) {
      writer.writeBytes(data);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readBytes(8);
    }
    reader.reset();
  }
}

/// Benchmark for reading medium byte arrays (64 bytes)
class MediumBytesReadBenchmark extends BenchmarkBase {
  MediumBytesReadBenchmark() : super('Bytes read: medium (64 bytes)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter();
    final data = Uint8List.fromList(List.generate(64, (i) => i % 256));

    // Write 1000 medium byte arrays
    for (var i = 0; i < 1000; i++) {
      writer.writeBytes(data);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readBytes(64);
    }
    reader.reset();
  }
}

/// Benchmark for reading large byte arrays (1 KB)
class LargeBytesReadBenchmark extends BenchmarkBase {
  LargeBytesReadBenchmark() : super('Bytes read: large (1 KB)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter(initialBufferSize: 1024 * 1024);
    final data = Uint8List.fromList(List.generate(1024, (i) => i % 256));

    // Write 100 large byte arrays
    for (var i = 0; i < 1000; i++) {
      writer.writeBytes(data);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readBytes(1024);
    }
    reader.reset();
  }
}

/// Benchmark for reading very large byte arrays (64 KB)
class VeryLargeBytesReadBenchmark extends BenchmarkBase {
  VeryLargeBytesReadBenchmark() : super('Bytes read: very large (64 KB)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter();
    final data = Uint8List.fromList(List.generate(64 * 1024, (i) => i % 256));

    // Write 10 very large byte arrays
    for (var i = 0; i < 10; i++) {
      writer.writeBytes(data);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 10; i++) {
      reader.readBytes(64 * 1024);
    }
    reader.reset();
  }
}

/// Benchmark for reading VarBytes (length-prefixed byte arrays)
class VarBytesSmallReadBenchmark extends BenchmarkBase {
  VarBytesSmallReadBenchmark() : super('VarBytes read: small');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter();
    final data = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);

    // Write 1000 VarBytes
    for (var i = 0; i < 1000; i++) {
      writer.writeVarBytes(data);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readVarBytes();
    }
    reader.reset();
  }
}

/// Benchmark for reading VarBytes with medium-sized data
class VarBytesMediumReadBenchmark extends BenchmarkBase {
  VarBytesMediumReadBenchmark() : super('VarBytes read: medium');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter();
    final data = Uint8List.fromList(List.generate(256, (i) => i % 256));

    // Write 500 VarBytes
    for (var i = 0; i < 500; i++) {
      writer.writeVarBytes(data);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 500; i++) {
      reader.readVarBytes();
    }
    reader.reset();
  }
}

/// Benchmark for reading VarBytes with large data
class VarBytesLargeReadBenchmark extends BenchmarkBase {
  VarBytesLargeReadBenchmark() : super('VarBytes read: large');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter();
    final data = Uint8List.fromList(List.generate(4096, (i) => i % 256));

    // Write 100 VarBytes
    for (var i = 0; i < 100; i++) {
      writer.writeVarBytes(data);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 100; i++) {
      reader.readVarBytes();
    }
    reader.reset();
  }
}

/// Benchmark for reading empty byte arrays
class EmptyBytesReadBenchmark extends BenchmarkBase {
  EmptyBytesReadBenchmark() : super('Bytes read: empty');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter();

    // Write 1000 empty byte arrays
    for (var i = 0; i < 1000; i++) {
      writer.writeBytes([]);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readBytes(0);
    }
    reader.reset();
  }
}

/// Benchmark for peeking at bytes without advancing position
class PeekBytesReadBenchmark extends BenchmarkBase {
  PeekBytesReadBenchmark() : super('Bytes peek: 16 bytes');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter();
    final data = Uint8List.fromList(List.generate(16, (i) => i));

    writer.writeBytes(data);
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.peekBytes(16);
    }
    // No reset needed - we're not advancing position
  }
}

/// Benchmark for reading remaining bytes
class ReadRemainingBytesReadBenchmark extends BenchmarkBase {
  ReadRemainingBytesReadBenchmark() : super('readRemainingBytes');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter();
    final data = Uint8List.fromList(List.generate(1024, (i) => i % 256));

    // Write 100 chunks
    for (var i = 0; i < 100; i++) {
      writer.writeBytes(data);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 100; i++) {
      reader.readBytes(1024);
    }
    reader.reset();
  }
}

/// Benchmark for mixed-size byte reads (realistic scenario)
///
/// Simulates reading a protocol with headers, payloads, and checksums.
class MixedBytesReadBenchmark extends BenchmarkBase {
  MixedBytesReadBenchmark() : super('Bytes read: mixed sizes (realistic)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter();

    // Simulate a protocol message:
    // - Header (16 bytes)
    // - Payload (variable: 64, 128, 256 bytes)
    // - Checksum (4 bytes)
    for (var i = 0; i < 1000; i++) {
      final header = Uint8List.fromList(List.generate(16, (j) => j));
      final payload = Uint8List.fromList(
        List.generate(64 + (i % 3) * 64, (j) => (j + i) % 256),
      );
      final checksum = Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF]);

      writer
        ..writeBytes(header)
        ..writeBytes(payload)
        ..writeBytes(checksum);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader
        ..readBytes(16) // Header
        ..readBytes(64 + (i % 3) * 64) // Payload
        ..readBytes(4); // Checksum
    }
    reader.reset();
  }
}

/// Benchmark for alternating small and large reads
class AlternatingBytesReadBenchmark extends BenchmarkBase {
  AlternatingBytesReadBenchmark() : super('Bytes read: alternating sizes');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter();
    final small = Uint8List.fromList([1, 2, 3, 4]);
    final large = Uint8List.fromList(List.generate(512, (i) => i % 256));

    // Alternate between small and large
    for (var i = 0; i < 1000; i++) {
      writer
        ..writeBytes(small)
        ..writeBytes(large);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader
        ..readBytes(4)
        ..readBytes(512);
    }
    reader.reset();
  }
}

/// Benchmark for sequential small reads
///
/// Tests performance when reading many small chunks sequentially.
class SequentialSmallReadsReadBenchmark extends BenchmarkBase {
  SequentialSmallReadsReadBenchmark()
    : super('Bytes read: sequential small reads');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter();

    // Write 4000 bytes as 1-byte chunks
    for (var i = 0; i < 1000; i++) {
      writer.writeUint8(i % 256);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readBytes(1);
    }
    reader.reset();
  }
}

/// Benchmark for reading with skip operations
class SkipAndReadBenchmark extends BenchmarkBase {
  SkipAndReadBenchmark() : super('Bytes read: skip + read pattern');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter();

    // Write pattern: 8 bytes data, 8 bytes padding
    for (var i = 0; i < 1000; i++) {
      final data = Uint8List.fromList(List.generate(8, (j) => (i + j) % 256));
      final padding = Uint8List.fromList(List.generate(8, (_) => 0));
      writer
        ..writeBytes(data)
        ..writeBytes(padding);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader
        ..readBytes(8) // Read data
        ..skip(8); // Skip padding
    }
    reader.reset();
  }
}

void main() {
  test('Fixed-size reads benchmarks:', () {
    EmptyBytesReadBenchmark().report();
    SmallBytesReadBenchmark().report();
    MediumBytesReadBenchmark().report();
    LargeBytesReadBenchmark().report();
    VeryLargeBytesReadBenchmark().report();
  }, tags: ['benchmark']);

  test('VarBytes (length-prefixed) benchmarks:', () {
    VarBytesSmallReadBenchmark().report();
    VarBytesMediumReadBenchmark().report();
    VarBytesLargeReadBenchmark().report();
  }, tags: ['benchmark']);

  test('Special operations benchmarks:', () {
    PeekBytesReadBenchmark().report();
    ReadRemainingBytesReadBenchmark().report();
  }, tags: ['benchmark']);

  test('Realistic scenarios benchmarks:', () {
    MixedBytesReadBenchmark().report();
    AlternatingBytesReadBenchmark().report();
    SequentialSmallReadsReadBenchmark().report();
    SkipAndReadBenchmark().report();
  }, tags: ['benchmark']);
}
