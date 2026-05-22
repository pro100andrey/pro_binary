import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:pro_binary/pro_binary.dart';

/// Benchmark for the full acquire-use-release cycle of the BinaryWriterPool.
class PoolFullCycleBenchmark extends BenchmarkBase {
  PoolFullCycleBenchmark() : super('Pool: Full Cycle (Acquire-Write-Release)');

  @override
  void setup() {
    BinaryWriterPool.clear();
    // Warm up the pool
    for (var i = 0; i < 10; i++) {
      final w = BinaryWriterPool.acquire()..writeUint32(i);
      BinaryWriterPool.release(w);
    }
  }

  @override
  void run() {
    final writer = BinaryWriterPool.acquire()
      ..writeUint32(42)
      ..writeVarString('Pooled writer usage');

    // We use toBytes() instead of takeBytes() to keep the buffer for reuse
    final _ = writer.toBytes();

    BinaryWriterPool.release(writer);
  }
}

/// Benchmark comparing pooled vs non-pooled (raw allocation) performance.
class RawAllocationBenchmark extends BenchmarkBase {
  RawAllocationBenchmark() : super('Pool: Raw Allocation (No Pool)');

  @override
  void run() {
    final writer = BinaryWriter(initialBufferSize: 1024)
      ..writeUint32(42)
      ..writeVarString('Pooled writer usage');
    final _ = writer.toBytes();
  }
}

void main() {
  PoolFullCycleBenchmark().report();
  RawAllocationBenchmark().report();
}
