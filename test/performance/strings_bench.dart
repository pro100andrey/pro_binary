import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:pro_binary/pro_binary.dart';

/// Benchmark for string operations with different encodings.
class StringBenchmark extends BenchmarkBase {
  StringBenchmark(String name, this.payload) : super('String: $name');

  final String payload;
  late BinaryWriter writer;
  late BinaryReader reader;
  late Uint8List buffer;
  var _checksum = 0;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: payload.length * 3 + 10);
    writer.writeVarString(payload);
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    // Benchmark Write
    writer
      ..reset()
      ..writeVarString(payload);

    // Benchmark Read
    reader.reset();
    _checksum += reader.readVarString().length;
  }

  @override
  void teardown() {
    if (_checksum == 0) {
      //
      // ignore: avoid_print
      print('Prevent DCE');
    }
  }
}

void main() {
  const ascii = 'This is a pure ASCII string for fast path testing.';
  const mixed = 'Mixed content: Русский текст, 世界, with some English.';
  final emoji = 'Emoji test: 🌍🚀🔥' * 5;

  StringBenchmark('ASCII', ascii).report();
  StringBenchmark('Mixed (UTF-8)', mixed).report();
  StringBenchmark('Emoji/Complex', emoji).report();
}
