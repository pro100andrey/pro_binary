import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

/// Benchmark for skip operations (small offsets)
///
/// Skip is commonly used to jump over padding, unused fields, or known
/// sections.
class SkipSmallOffsetBenchmark extends BenchmarkBase {
  SkipSmallOffsetBenchmark() : super('Skip: small offset (8 bytes)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter();

    for (var i = 0; i < 1000; i++) {
      writer.writeUint64(i);
    }

    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.skip(8);
    }
    reader.reset();
  }
}

/// Benchmark for skip operations (medium offsets)
class SkipMediumOffsetBenchmark extends BenchmarkBase {
  SkipMediumOffsetBenchmark() : super('Skip: medium offset (256 bytes)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter();
    final data = Uint8List.fromList(List.generate(256, (i) => i % 256));

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
      reader.skip(256);
    }
    reader.reset();
  }
}

/// Benchmark for skip operations (large offsets)
class SkipLargeOffsetBenchmark extends BenchmarkBase {
  SkipLargeOffsetBenchmark() : super('Skip: large offset (4 KB)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter();
    final data = Uint8List.fromList(List.generate(4096, (i) => i % 256));
    // Write 1000 chunks of 4KB
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
      reader.skip(4096);
    }
    reader.reset();
  }
}

/// Benchmark for seek operations (forward)
///
/// Seek is used for random access patterns, like jumping to specific offsets.
class SeekForwardBenchmark extends BenchmarkBase {
  SeekForwardBenchmark() : super('Seek: forward (sequential positions)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter();
    // Write 100KB of data
    final data = Uint8List.fromList(List.generate(100000, (i) => i % 256));
    writer.writeBytes(data);

    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    // Seek to 1000 different positions
    for (var i = 0; i < 1000; i++) {
      reader.seek((i * 100) % 90000);
    }
    reader.reset();
  }
}

/// Benchmark for seek operations (backward)
class SeekBackwardBenchmark extends BenchmarkBase {
  SeekBackwardBenchmark() : super('Seek: backward (reverse positions)');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter();
    final data = Uint8List.fromList(List.generate(100000, (i) => i % 256));
    writer.writeBytes(data);

    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);

    reader.seek(90000); // Start near end
  }

  @override
  void exercise() => run();

  @override
  void run() {
    // Seek backward to 1000 different positions
    for (var i = 1000; i > 0; i--) {
      reader.seek((i * 90) % 90000);
    }
    reader.reset();
  }
}

/// Benchmark for seek operations (random access)
class SeekRandomAccessBenchmark extends BenchmarkBase {
  SeekRandomAccessBenchmark() : super('Seek: random access pattern');

  late BinaryReader reader;
  late Uint8List buffer;
  late List<int> positions;

  @override
  void setup() {
    final writer = BinaryWriter();
    final data = Uint8List.fromList(List.generate(100000, (i) => i % 256));

    writer.writeBytes(data);
    buffer = writer.takeBytes();

    reader = BinaryReader(buffer);
    // Pre-calculate random-like positions (deterministic for consistency)
    positions = List.generate(1000, (i) => (i * 7919) % 90000);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    // Disable lint for using for-in to emphasize the benchmark nature
    // ignore: prefer_foreach
    for (final pos in positions) {
      reader.seek(pos);
    }
    reader.reset();
  }
}

/// Benchmark for rewind operations
///
/// Rewind resets position to the beginning - common in parsing retry scenarios.
class RewindBenchmark extends BenchmarkBase {
  RewindBenchmark() : super('Rewind: reset to start');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter();
    for (var i = 0; i < 1000; i++) {
      writer.writeUint64(i);
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
        ..skip(8)
        ..reset();
    }
  }
}

/// Benchmark for reset operations
///
/// Reset is similar to rewind - tests the efficiency of position reset.
class ResetBenchmark extends BenchmarkBase {
  ResetBenchmark() : super('Reset: position reset');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter();
    for (var i = 0; i < 1000; i++) {
      writer.writeUint64(i);
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
        ..skip(8)
        ..reset();
    }
  }
}

/// Benchmark for getPosition operations
///
/// Getting current position (offset) is often needed in parsing to track
/// offsets.
class GetPositionBenchmark extends BenchmarkBase {
  GetPositionBenchmark() : super('offset: query current position');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter();
    for (var i = 0; i < 1000; i++) {
      writer.writeUint64(i);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.skip(8);
    }
    reader.reset();
  }
}

/// Benchmark for remainingBytes getter
class RemainingBytesBenchmark extends BenchmarkBase {
  RemainingBytesBenchmark() : super('availableBytes: query remaining length');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter();
    for (var i = 0; i < 1000; i++) {
      writer.writeUint64(i);
    }

    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.skip(8);
    }
    reader.reset();
  }
}

/// Benchmark for combined navigation operations (realistic parsing)
///
/// Simulates a parser that needs to:
/// 1. Check position
/// 2. Peek at header
/// 3. Decide to skip or read
/// 4. Move to next section
class RealisticParsingNavigationBenchmark extends BenchmarkBase {
  RealisticParsingNavigationBenchmark()
    : super('Navigation: realistic parsing pattern');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter();
    // Write protocol-like data: header (4 bytes) + payload (variable)
    for (var i = 0; i < 1000; i++) {
      final payloadSize = 16 + (i % 8) * 8;
      writer
        ..writeUint32(payloadSize) // Header with payload size
        ..writeBytes(List.generate(payloadSize, (j) => (i + j) % 256));
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      // 1. Get current position
      reader.offset;
      // 2. Peek at header to determine payload size
      final peekData = reader.peekBytes(4);
      final payloadSize = ByteData.view(peekData.buffer).getUint32(0);
      // 3. Skip header
      reader.skip(4);
      // 4. Decide: skip payload based on some condition
      if (i % 3 == 0) {
        reader.skip(payloadSize);
      } else {
        // Read and process payload
        reader.readBytes(payloadSize);
      }
    }
    reader.reset();
  }
}

/// Benchmark for seek + read pattern
///
/// Common in binary file formats with indexes or tables of contents.
class SeekAndReadBenchmark extends BenchmarkBase {
  SeekAndReadBenchmark() : super('Navigation: seek + read pattern');

  late BinaryReader reader;
  late Uint8List buffer;
  late List<int> offsets;

  @override
  void setup() {
    final writer = BinaryWriter();
    // Write 100 records of 64 bytes each
    offsets = <int>[];
    for (var i = 0; i < 100; i++) {
      offsets.add(i * 64); // Track offsets manually
      final data = Uint8List.fromList(List.generate(64, (j) => (i + j) % 256));
      writer.writeBytes(data);
    }

    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    // Read records in non-sequential order
    for (var i = 0; i < 100; i++) {
      final idx = (i * 7) % 100;
      reader
        ..seek(offsets[idx])
        ..readBytes(64);
    }
    reader.reset();
  }
}

/// Benchmark for skip + peek pattern
///
/// Used when scanning through data looking for specific patterns.
class SkipAndPeekBenchmark extends BenchmarkBase {
  SkipAndPeekBenchmark() : super('Navigation: skip + peek pattern');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter();
    // Write pattern: 4 bytes to skip, 4 bytes to peek
    for (var i = 0; i < 1000; i++) {
      writer
        ..writeUint32(0xDEADBEEF) // Skip this
        ..writeUint32(i); // Peek at this
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
        ..skip(4)
        ..peekBytes(4)
        ..skip(4);
    }
    reader.reset();
  }
}

/// Benchmark for backward navigation (seek back and re-read)
///
/// Used when parser needs to backtrack.
class BacktrackNavigationBenchmark extends BenchmarkBase {
  BacktrackNavigationBenchmark() : super('Navigation: backtrack pattern');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter();
    for (var i = 0; i < 2000; i++) {
      writer.writeUint32(i);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 500; i++) {
      // Read forward
      reader
        ..readUint32()
        ..readUint32();
      final pos = reader.offset;
      reader
        ..readUint32()
        // Backtrack to saved position
        ..seek(pos)
        // Re-read
        ..readUint32();
    }
    reader.reset();
  }
}

void main() {
  test('Skip operation benchmarks:', () {
    SkipSmallOffsetBenchmark().report();
    SkipMediumOffsetBenchmark().report();
    SkipLargeOffsetBenchmark().report();
  }, tags: ['benchmark']);

  test('Seek operation benchmarks:', () {
    SeekForwardBenchmark().report();
    SeekBackwardBenchmark().report();
    SeekRandomAccessBenchmark().report();
  }, tags: ['benchmark']);

  test('Position control benchmarks:', () {
    RewindBenchmark().report();
    ResetBenchmark().report();
    GetPositionBenchmark().report();
  }, tags: ['benchmark']);

  test('Position query benchmarks:', () {
    GetPositionBenchmark().report();
    RemainingBytesBenchmark().report();
  }, tags: ['benchmark']);

  test('Complex navigation patterns:', () {
    RealisticParsingNavigationBenchmark().report();
    SeekAndReadBenchmark().report();
    SkipAndPeekBenchmark().report();
    BacktrackNavigationBenchmark().report();
  }, tags: ['benchmark']);
}
