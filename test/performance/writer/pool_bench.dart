import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

/// Benchmark for acquiring writers from pool (empty pool)
///
/// Tests the performance of getting a new writer from the pool.
class PoolAcquireNewBenchmark extends BenchmarkBase {
  PoolAcquireNewBenchmark() : super('Pool: acquire new writer');

  @override
  void setup() {
    BinaryWriterPool.clear();
  }

  @override
  void run() {
    for (var i = 0; i < 100; i++) {
      final writer = BinaryWriterPool.acquire();
      BinaryWriterPool.release(writer);
    }
  }
}

/// Benchmark for acquiring reused writers from pool
///
/// Tests the performance when writers are reused from the pool.
class PoolAcquireReusedBenchmark extends BenchmarkBase {
  PoolAcquireReusedBenchmark() : super('Pool: acquire reused writer');

  late List<BinaryWriter> writers;

  @override
  void setup() {
    BinaryWriterPool.clear();
    writers = <BinaryWriter>[];
    // Pre-fill pool with released writers
    for (var i = 0; i < 10; i++) {
      final writer = BinaryWriterPool.acquire()
        ..writeBytes(List.generate(100, (j) => j % 256));
      writers.add(writer);
    }
    writers.forEach(BinaryWriterPool.release);
  }

  @override
  void run() {
    for (var i = 0; i < 100; i++) {
      final writer = BinaryWriterPool.acquire();
      BinaryWriterPool.release(writer);
    }
  }
}

/// Benchmark for releasing writers to pool
///
/// Tests the performance of returning writers to the pool.
class PoolReleaseBenchmark extends BenchmarkBase {
  PoolReleaseBenchmark() : super('Pool: release writer');

  late List<BinaryWriter> writers;

  @override
  void setup() {
    BinaryWriterPool.clear();
    writers = <BinaryWriter>[];
    for (var i = 0; i < 100; i++) {
      writers.add(BinaryWriterPool.acquire());
    }
  }

  @override
  void run() {
    for (final writer in writers) {
      writer.writeBytes(List.generate(50, (j) => j % 256));
      BinaryWriterPool.release(writer);
    }
  }
}

/// Benchmark for acquire + write + release cycle
///
/// Full cycle: get writer, use it, return it to pool.
class PoolFullCycleBenchmark extends BenchmarkBase {
  PoolFullCycleBenchmark()
    : super('Pool: full cycle (acquire + write + release)');

  @override
  void setup() {
    BinaryWriterPool.clear();
  }

  @override
  void run() {
    for (var i = 0; i < 100; i++) {
      final writer = BinaryWriterPool.acquire()
        ..writeUint32(i)
        ..writeString('test message $i')
        ..writeBytes(List.generate(32, (j) => (i + j) % 256));
      BinaryWriterPool.release(writer);
    }
  }
}

/// Benchmark for heavy writer usage with pool
///
/// Simulates typical protocol message serialization using pool.
class PoolHeavyUsageBenchmark extends BenchmarkBase {
  PoolHeavyUsageBenchmark() : super('Pool: heavy usage (realistic)');

  @override
  void setup() {
    BinaryWriterPool.clear();
  }

  @override
  void run() {
    for (var i = 0; i < 50; i++) {
      final writer = BinaryWriterPool.acquire()
        // Simulate message header
        ..writeUint32(i) // Message ID
        ..writeVarUint(i % 1000) // Message length
        // Write payload
        ..writeString('Header: $i');
      for (var j = 0; j < 5; j++) {
        writer.writeFloat64(i * 3.14 + j);
      }
      writer.writeBytes(List.generate(256, (k) => (i + k) % 256));
      // Return to pool
      BinaryWriterPool.release(writer);
    }
  }
}

/// Benchmark for sequential acquire operations
///
/// Tests pool performance under sequential load without much release.
class PoolSequentialAcquireBenchmark extends BenchmarkBase {
  PoolSequentialAcquireBenchmark() : super('Pool: sequential acquire');

  @override
  void setup() {
    BinaryWriterPool.clear();
  }

  @override
  void run() {
    final writers = <BinaryWriter>[];
    // Acquire up to pool max size
    for (var i = 0; i < 32; i++) {
      writers.add(BinaryWriterPool.acquire());
    }
    // Release all
    writers.forEach(BinaryWriterPool.release);
  }
}

/// Benchmark for pool statistics queries
///
/// Tests the performance of checking pool statistics.
class PoolStatisticsBenchmark extends BenchmarkBase {
  PoolStatisticsBenchmark() : super('Pool: query statistics');

  late List<BinaryWriter> writers;

  @override
  void setup() {
    BinaryWriterPool.clear();
    writers = <BinaryWriter>[];
    for (var i = 0; i < 10; i++) {
      final w = BinaryWriterPool.acquire()
        ..writeBytes(List.generate(100, (j) => j % 256));
      writers.add(w);
    }
  }

  @override
  void run() {
    // Query statistics multiple times
    for (var i = 0; i < 1000; i++) {
      // This should ideally be cheap - just reading counters
      final stat = BinaryWriterPool.stats;
      // Use the stat to prevent optimization away
      if (stat.pooled > 0) {
        // Just to use the value
      }
    }
  }
}

/// Benchmark for mixed operations on pool
///
/// Realistic pattern: acquire, use, release in varying patterns.
class PoolMixedOperationsBenchmark extends BenchmarkBase {
  PoolMixedOperationsBenchmark() : super('Pool: mixed operations');

  @override
  void setup() {
    BinaryWriterPool.clear();
  }

  @override
  void run() {
    final batch1 = <BinaryWriter>[];
    // Acquire batch
    for (var i = 0; i < 10; i++) {
      batch1.add(BinaryWriterPool.acquire());
    }
    // Use first batch
    for (final w in batch1) {
      w.writeVarUint(42);
    }
    // Acquire second batch while first still active
    final batch2 = <BinaryWriter>[];
    for (var i = 0; i < 10; i++) {
      batch2.add(BinaryWriterPool.acquire());
    }
    // Release first batch
    batch1.forEach(BinaryWriterPool.release);
    // Continue using second batch
    for (final w in batch2) {
      w.writeFloat32(3.14);
    }
    // Release second batch
    batch2.forEach(BinaryWriterPool.release);
  }
}

/// Benchmark for pool with buffer reuse
///
/// Tests how well buffers are reused when writers are recycled.
class PoolBufferReuseBenchmark extends BenchmarkBase {
  PoolBufferReuseBenchmark() : super('Pool: buffer reuse efficiency');

  @override
  void setup() {
    BinaryWriterPool.clear();
  }

  @override
  void run() {
    // Use pool with varying write sizes
    for (var cycle = 0; cycle < 20; cycle++) {
      final writer = BinaryWriterPool.acquire();
      // Write varying amount of data
      final size = 64 * (cycle % 10 + 1); // 64, 128, 192, ..., 640
      writer.writeBytes(List.generate(size, (i) => i % 256));
      BinaryWriterPool.release(writer);
    }
  }
}

/// Benchmark for reset statistics
///
/// Tests the cost of resetting pool statistics.
class PoolResetStatisticsBenchmark extends BenchmarkBase {
  PoolResetStatisticsBenchmark() : super('Pool: reset statistics');

  @override
  void setup() {
    BinaryWriterPool.clear();
    // Generate some statistics by using pool
    for (var i = 0; i < 100; i++) {
      final w = BinaryWriterPool.acquire()..writeUint32(i);
      BinaryWriterPool.release(w);
    }
  }

  @override
  void run() {
    for (var i = 0; i < 100; i++) {
      BinaryWriterPool.clear();
      // Do some work
      final w = BinaryWriterPool.acquire()..writeUint32(i);
      BinaryWriterPool.release(w);
    }
  }
}

void main() {
  test('Pool acquire operations:', () {
    PoolAcquireNewBenchmark().report();
    PoolAcquireReusedBenchmark().report();
  }, tags: ['benchmark']);

  test('Pool release operations:', () {
    PoolReleaseBenchmark().report();
    PoolFullCycleBenchmark().report();
  }, tags: ['benchmark']);

  test('Pool usage patterns:', () {
    PoolHeavyUsageBenchmark().report();
    PoolSequentialAcquireBenchmark().report();
    PoolMixedOperationsBenchmark().report();
  }, tags: ['benchmark']);

  test('Pool efficiency:', () {
    PoolBufferReuseBenchmark().report();
    PoolStatisticsBenchmark().report();
    PoolResetStatisticsBenchmark().report();
  }, tags: ['benchmark']);
}
