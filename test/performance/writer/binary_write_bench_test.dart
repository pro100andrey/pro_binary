import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

/// Benchmark for writing small byte arrays (< 16 bytes)
class SmallBytesWriteBenchmark extends BenchmarkBase {
  SmallBytesWriteBenchmark() : super('Bytes write: small (8 bytes)');

  late BinaryWriter writer;
  late Uint8List data;

  @override
  void setup() {
    writer = BinaryWriter();
    data = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      writer.writeBytes(data);
    }
    writer.reset();
  }
}

/// Benchmark for writing medium byte arrays (64 bytes)
class MediumBytesWriteBenchmark extends BenchmarkBase {
  MediumBytesWriteBenchmark() : super('Bytes write: medium (64 bytes)');

  late BinaryWriter writer;
  late Uint8List data;

  @override
  void setup() {
    writer = BinaryWriter();
    data = Uint8List.fromList(List.generate(64, (i) => i % 256));
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      writer.writeBytes(data);
    }
    writer.reset();
  }
}

/// Benchmark for writing large byte arrays (1 KB)
class LargeBytesWriteBenchmark extends BenchmarkBase {
  LargeBytesWriteBenchmark() : super('Bytes write: large (1 KB)');

  late BinaryWriter writer;
  late Uint8List data;

  @override
  void setup() {
    writer = BinaryWriter();
    data = Uint8List.fromList(List.generate(1024, (i) => i % 256));
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      writer.writeBytes(data);
    }
    writer.reset();
  }
}

/// Benchmark for writing very large byte arrays (64 KB)
class VeryLargeBytesWriteBenchmark extends BenchmarkBase {
  VeryLargeBytesWriteBenchmark() : super('Bytes write: very large (64 KB)');

  late BinaryWriter writer;
  late Uint8List data;

  @override
  void setup() {
    writer = BinaryWriter();
    data = Uint8List.fromList(List.generate(64 * 1024, (i) => i % 256));
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      writer.writeBytes(data);
    }
    writer.reset();
  }
}

/// Benchmark for writing VarBytes (length-prefixed byte arrays)
class VarBytesSmallWriteBenchmark extends BenchmarkBase {
  VarBytesSmallWriteBenchmark() : super('VarBytes write: small');

  late BinaryWriter writer;
  late Uint8List data;

  @override
  void setup() {
    writer = BinaryWriter();
    data = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      writer.writeVarBytes(data);
    }
    writer.reset();
  }
}

/// Benchmark for writing VarBytes with medium-sized data
class VarBytesMediumWriteBenchmark extends BenchmarkBase {
  VarBytesMediumWriteBenchmark() : super('VarBytes write: medium');

  late BinaryWriter writer;
  late Uint8List data;

  @override
  void setup() {
    writer = BinaryWriter();
    data = Uint8List.fromList(List.generate(256, (i) => i % 256));
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      writer.writeVarBytes(data);
    }
    writer.reset();
  }
}

/// Benchmark for writing VarBytes with large data
class VarBytesLargeWriteBenchmark extends BenchmarkBase {
  VarBytesLargeWriteBenchmark() : super('VarBytes write: large');

  late BinaryWriter writer;
  late Uint8List data;

  @override
  void setup() {
    writer = BinaryWriter();
    data = Uint8List.fromList(List.generate(4096, (i) => i % 256));
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      writer.writeVarBytes(data);
    }
    writer.reset();
  }
}

/// Benchmark for writing empty byte arrays
class EmptyBytesWriteBenchmark extends BenchmarkBase {
  EmptyBytesWriteBenchmark() : super('Bytes write: empty');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter();
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      writer.writeBytes([]);
    }
    writer.reset();
  }
}

/// Benchmark for mixed-size byte writes (realistic scenario)
class MixedBytesWriteBenchmark extends BenchmarkBase {
  MixedBytesWriteBenchmark() : super('Bytes write: mixed sizes (realistic)');

  late BinaryWriter writer;
  late Uint8List header;
  late List<Uint8List> payloads;
  late Uint8List checksum;

  @override
  void setup() {
    writer = BinaryWriter();
    header = Uint8List.fromList(List.generate(16, (j) => j));
    payloads = [
      Uint8List.fromList(List.generate(64, (j) => j % 256)),
      Uint8List.fromList(List.generate(128, (j) => j % 256)),
      Uint8List.fromList(List.generate(256, (j) => j % 256)),
    ];
    checksum = Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF]);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      writer
        ..writeBytes(header)
        ..writeBytes(payloads[i % 3])
        ..writeBytes(checksum);
    }
    writer.reset();
  }
}

/// Benchmark for alternating small and large writes
class AlternatingBytesWriteBenchmark extends BenchmarkBase {
  AlternatingBytesWriteBenchmark() : super('Bytes write: alternating sizes');

  late BinaryWriter writer;
  late Uint8List small;
  late Uint8List large;

  @override
  void setup() {
    writer = BinaryWriter();
    small = Uint8List.fromList([1, 2, 3, 4]);
    large = Uint8List.fromList(List.generate(512, (i) => i % 256));
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      writer
        ..writeBytes(small)
        ..writeBytes(large);
    }
    writer.reset();
  }
}

/// Benchmark for sequential small writes
class SequentialSmallWritesBenchmark extends BenchmarkBase {
  SequentialSmallWritesBenchmark()
    : super('Bytes write: sequential small writes');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter();
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

/// Benchmark for writing bytes from List of int
class ListIntWriteBenchmark extends BenchmarkBase {
  ListIntWriteBenchmark() : super('Bytes write: from List<int>');

  late BinaryWriter writer;
  late List<int> data;

  @override
  void setup() {
    writer = BinaryWriter();
    data = List.generate(64, (i) => i % 256);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      writer.writeBytes(data);
    }
    writer.reset();
  }
}

/// Benchmark for writing bytes from Uint8List view
class Uint8ListViewWriteBenchmark extends BenchmarkBase {
  Uint8ListViewWriteBenchmark() : super('Bytes write: Uint8List view');

  late BinaryWriter writer;
  late Uint8List data;
  late Uint8List view;

  @override
  void setup() {
    writer = BinaryWriter();
    data = Uint8List.fromList(List.generate(128, (i) => i % 256));
    view = Uint8List.view(data.buffer, 32, 64);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      writer.writeBytes(view);
    }
    writer.reset();
  }
}

void main() {
  test('Fixed-size writes benchmarks:', () {
    EmptyBytesWriteBenchmark().report();
    SmallBytesWriteBenchmark().report();
    MediumBytesWriteBenchmark().report();
    LargeBytesWriteBenchmark().report();
    VeryLargeBytesWriteBenchmark().report();
  }, tags: ['benchmark']);

  test('VarBytes (length-prefixed) benchmarks:', () {
    VarBytesSmallWriteBenchmark().report();
    VarBytesMediumWriteBenchmark().report();
    VarBytesLargeWriteBenchmark().report();
  }, tags: ['benchmark']);

  test('Realistic scenarios benchmarks:', () {
    MixedBytesWriteBenchmark().report();
    AlternatingBytesWriteBenchmark().report();
    SequentialSmallWritesBenchmark().report();
  }, tags: ['benchmark']);

  test('Special input types benchmarks:', () {
    ListIntWriteBenchmark().report();
    Uint8ListViewWriteBenchmark().report();
  }, tags: ['benchmark']);
}
