import 'dart:convert';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:pro_binary/pro_binary.dart';

/// Current optimized approach (One-pass optimistic shift)
class OnePassStringBench extends BenchmarkBase {
  OnePassStringBench(String name, this.payload)
    : super('String [$name] (One-Pass)');

  final String payload;
  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: payload.length * 3 + 10);
  }

  @override
  void run() {
    writer
      ..reset()
      ..writeVarString(payload);

    if (writer.bytesWritten == 0) {
      throw Exception();
    }
  }
}

/// Old two-pass approach (getUtf8Length + writeString)
class TwoPassStringBench extends BenchmarkBase {
  TwoPassStringBench(String name, this.payload)
    : super('String [$name] (Two-Pass)');
  final String payload;
  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: payload.length * 3 + 10);
  }

  void _oldWriteVarString(String value) {
    final utf8Length = getUtf8Length(value);
    writer
      ..writeVarUint(utf8Length)
      ..writeString(value);
  }

  @override
  void run() {
    writer.reset();
    _oldWriteVarString(payload);
    if (writer.bytesWritten == 0) {
      throw Exception();
    }
  }
}

/// Standard Dart approach (utf8.encode + bytes.length)
/// This is the most common "correct" way without pro_binary.
class StandardDartCorrectBench extends BenchmarkBase {
  StandardDartCorrectBench(String name, this.payload)
    : super('String [$name] (utf8.encode + bytes.length)');

  final String payload;
  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: payload.length * 3 + 10);
  }

  @override
  void run() {
    writer.reset();
    final bytes = utf8.encode(payload);
    writer
      ..writeVarUint(bytes.length)
      ..writeBytes(bytes);
    if (writer.bytesWritten == 0) {
      throw Exception();
    }
  }
}

/// Naive Dart approach (utf8.encode + string.length)
/// Used as a baseline for "theoretical maximum" speed if length was already
/// known.
class StandardDartNaiveBench extends BenchmarkBase {
  StandardDartNaiveBench(String name, this.payload)
    : super('String [$name] (utf8.encode + string.length)');

  final String payload;
  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: payload.length * 3 + 10);
  }

  @override
  void run() {
    writer.reset();
    final bytes = utf8.encode(payload);
    writer
      ..writeVarUint(payload.length) // Using character length
      ..writeBytes(bytes);
    if (writer.bytesWritten == 0) {
      throw Exception();
    }
  }
}

class FixedStringBench extends BenchmarkBase {
  FixedStringBench(String name, this.payload, this.encoding)
    : super('String [$name] (Fixed ${encoding.name})');

  final String payload;
  final LengthEncoding encoding;
  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: payload.length * 3 + 10);
  }

  @override
  void run() {
    writer
      ..reset()
      ..writeStringFixed(payload, lengthEncoding: encoding);

    if (writer.bytesWritten == 0) {
      throw Exception();
    }
  }
}

void runComparison(String name, String payload) {
  OnePassStringBench(name, payload).report();
  FixedStringBench(name, payload, .u32).report();
  TwoPassStringBench(name, payload).report();
  StandardDartCorrectBench(name, payload).report();
  StandardDartNaiveBench(name, payload).report();
}

void main() {
  const ascii = 'This is a pure ASCII string for fast path testing.';
  const mixed = 'Mixed content: Русский текст, 世界, with some English.';
  final emoji = 'Emoji test: 🌍🚀🔥' * 5;

  runComparison('ASCII', ascii);
  runComparison('Mixed UTF-8', mixed);
  runComparison('Emoji/Complex', emoji);
}
