import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

/// Benchmark for writing ASCII strings (fast path)
class AsciiStringWriteBenchmark extends BenchmarkBase {
  AsciiStringWriteBenchmark() : super('String write: ASCII only');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 16384);
  }

  @override
  void run() {
    for (var i = 0; i < 100; i++) {
      writer.writeString('Hello, World! This is a test string 123456789');
    }
    writer.reset();
  }
}

/// Benchmark for writing short ASCII strings
class ShortAsciiStringWriteBenchmark extends BenchmarkBase {
  ShortAsciiStringWriteBenchmark() : super('String write: short ASCII');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 16384);
  }

  @override
  void run() {
    for (var i = 0; i < 125; i++) {
      writer
        ..writeString('Hi')
        ..writeString('Test')
        ..writeString('Hello')
        ..writeString('OK')
        ..writeString('Error')
        ..writeString('Success')
        ..writeString('123')
        ..writeString('ABC');
    }
    writer.reset();
  }
}

/// Benchmark for writing long ASCII strings
class LongAsciiStringWriteBenchmark extends BenchmarkBase {
  LongAsciiStringWriteBenchmark() : super('String write: long ASCII');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 32768);
  }

  @override
  void run() {
    const longString =
        'The quick brown fox jumps over the lazy dog. '
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
        'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '
        'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.';
    for (var i = 0; i < 100; i++) {
      writer.writeString(longString);
    }
    writer.reset();
  }
}

/// Benchmark for writing Cyrillic strings (2-byte UTF-8)
class CyrillicStringWriteBenchmark extends BenchmarkBase {
  CyrillicStringWriteBenchmark()
    : super('String write: Cyrillic (2-byte UTF-8)');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 16384);
  }

  @override
  void run() {
    for (var i = 0; i < 100; i++) {
      writer.writeString('Привет мир! Это тестовая строка на русском языке.');
    }
    writer.reset();
  }
}

/// Benchmark for writing CJK strings (3-byte UTF-8)
class CjkStringWriteBenchmark extends BenchmarkBase {
  CjkStringWriteBenchmark() : super('String write: CJK (3-byte UTF-8)');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 16384);
  }

  @override
  void run() {
    for (var i = 0; i < 100; i++) {
      writer.writeString('你好世界！这是一个测试字符串。日本語のテストも含まれています。');
    }
    writer.reset();
  }
}

/// Benchmark for writing emoji strings (4-byte UTF-8)
class EmojiStringWriteBenchmark extends BenchmarkBase {
  EmojiStringWriteBenchmark() : super('String write: Emoji (4-byte UTF-8)');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 16384);
  }

  @override
  void run() {
    for (var i = 0; i < 100; i++) {
      writer.writeString('🚀 🌍 🎉 👍 💻 🔥 ⚡ 🎯 🏆 💡 🌈 ✨ 🎨 🎭 🎪');
    }
    writer.reset();
  }
}

/// Benchmark for writing mixed Unicode strings
class MixedUnicodeStringWriteBenchmark extends BenchmarkBase {
  MixedUnicodeStringWriteBenchmark() : super('String write: mixed Unicode');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 16384);
  }

  @override
  void run() {
    for (var i = 0; i < 100; i++) {
      writer.writeString('Hello мир 世界 🌍! Test тест 测试 🚀');
    }
    writer.reset();
  }
}

/// Benchmark for writing VarString (length-prefixed strings)
class VarStringAsciiWriteBenchmark extends BenchmarkBase {
  VarStringAsciiWriteBenchmark() : super('VarString write: ASCII');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 16384);
  }

  @override
  void run() {
    for (var i = 0; i < 100; i++) {
      writer.writeVarString('Hello, World! This is a test string.');
    }
    writer.reset();
  }
}

/// Benchmark for writing VarString with mixed Unicode
class VarStringMixedWriteBenchmark extends BenchmarkBase {
  VarStringMixedWriteBenchmark() : super('VarString write: mixed Unicode');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 16384);
  }

  @override
  void run() {
    for (var i = 0; i < 100; i++) {
      writer.writeVarString('Hello мир 世界 🌍 Test тест 测试 🚀');
    }
    writer.reset();
  }
}

/// Benchmark for writing empty strings
class EmptyStringWriteBenchmark extends BenchmarkBase {
  EmptyStringWriteBenchmark() : super('String write: empty strings');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 8192);
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      writer.writeString('');
    }
    writer.reset();
  }
}

/// Benchmark for realistic message protocol with strings
class RealisticMessageWriteBenchmark extends BenchmarkBase {
  RealisticMessageWriteBenchmark() : super('String write: realistic message');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 32768);
  }

  @override
  void run() {
    for (var i = 0; i < 100; i++) {
      writer
        ..writeString('user')
        ..writeString('John Doe')
        ..writeString('email')
        ..writeString('john.doe@example.com')
        ..writeString('message')
        ..writeString('Hello 世界! 🌍')
        ..writeString('timestamp')
        ..writeString('2024-12-30T12:00:00Z')
        ..writeString('locale')
        ..writeString('ru-RU');
    }
    writer.reset();
  }
}

/// Benchmark for alternating short and long strings
class AlternatingStringWriteBenchmark extends BenchmarkBase {
  AlternatingStringWriteBenchmark()
    : super('String write: alternating lengths');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 32768);
  }

  @override
  void run() {
    const shortString = 'Hi';
    const longString =
        'This is a much longer string with more content to write and process';
    for (var i = 0; i < 500; i++) {
      writer
        ..writeString(shortString)
        ..writeString(longString);
    }
    writer.reset();
  }
}

/// Benchmark for writing very long strings (> 1KB)
class VeryLongStringWriteBenchmark extends BenchmarkBase {
  VeryLongStringWriteBenchmark() : super('String write: very long (>1KB)');

  late BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter(initialBufferSize: 65536);
  }

  @override
  void run() {
    final longString = 'Lorem ipsum dolor sit amet. ' * 80;
    for (var i = 0; i < 50; i++) {
      writer.writeString(longString);
    }
    writer.reset();
  }
}

void main() {
  test('ASCII string benchmarks:', () {
    AsciiStringWriteBenchmark().report();
    ShortAsciiStringWriteBenchmark().report();
    LongAsciiStringWriteBenchmark().report();
    EmptyStringWriteBenchmark().report();
  }, tags: ['benchmark']);

  test('UTF-8 multi-byte benchmarks:', () {
    CyrillicStringWriteBenchmark().report();
    CjkStringWriteBenchmark().report();
    EmojiStringWriteBenchmark().report();
    MixedUnicodeStringWriteBenchmark().report();
  }, tags: ['benchmark']);

  test('VarString benchmarks:', () {
    VarStringAsciiWriteBenchmark().report();
    VarStringMixedWriteBenchmark().report();
  }, tags: ['benchmark']);

  test('Realistic string scenarios:', () {
    RealisticMessageWriteBenchmark().report();
    AlternatingStringWriteBenchmark().report();
    VeryLongStringWriteBenchmark().report();
  }, tags: ['benchmark']);
}
