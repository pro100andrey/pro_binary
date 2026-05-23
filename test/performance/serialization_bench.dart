import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:pro_binary/pro_binary.dart';

/// Benchmark for a simple message with fixed-size types.
class SimpleMessageWriteBenchmark extends BenchmarkBase {
  SimpleMessageWriteBenchmark() : super('Write: Simple Message');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 64);
  }

  @override
  void run() {
    writer
      ..reset()
      ..writeUint32(123456789)
      ..writeFloat32(3.14159)
      ..writeBool(true)
      ..writeInt16(-100)
      ..writeUint8(255);

    // Ensure data is "consumed" to prevent DCE
    if (writer.bytesWritten == 0) {
      throw Exception('DCE');
    }
  }
}

/// Benchmark for a complex profile with strings and collections.
class ComplexProfileWriteBenchmark extends BenchmarkBase {
  ComplexProfileWriteBenchmark() : super('Write: Complex Profile');

  late BinaryWriter writer;

  final nameString = 'John Alexander Doe';
  final email = 'john.doe.very.long.email.address@example.com';
  final List<int> scores = List.generate(20, (i) => i * 100);

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 512);
  }

  @override
  void run() {
    writer
      ..reset()
      ..writeVarUint(1001) // ID
      ..writeVarString(nameString)
      ..writeVarString(email)
      ..writeBool(false) // IsPremium
      ..writeVarUint(scores.length);
    for (final score in scores) {
      writer.writeVarInt(score);
    }

    if (writer.bytesWritten == 0) {
      throw Exception('DCE');
    }
  }
}

/// Benchmark for writing large arrays of data.
class LargeArrayWriteBenchmark extends BenchmarkBase {
  LargeArrayWriteBenchmark() : super('Write: Large Array (10K ints)');

  late BinaryWriter writer;
  late List<int> data;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 1024 * 64);
    data = List.generate(10000, (i) => i);
  }

  @override
  void run() {
    writer
      ..reset()
      ..writeVarUint(data.length);
    for (final val in data) {
      writer.writeUint32(val);
    }

    if (writer.bytesWritten == 0) {
      throw Exception('DCE');
    }
  }
}

void main() {
  SimpleMessageWriteBenchmark().report();
  ComplexProfileWriteBenchmark().report();
  LargeArrayWriteBenchmark().report();
}
