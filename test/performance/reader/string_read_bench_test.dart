import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:pro_binary/pro_binary.dart';
import 'package:test/test.dart';

/// Benchmark for reading ASCII strings (fast path)
///
/// ASCII-only strings use the fast path in UTF-8 decoding,
/// processing multiple bytes at once. This is the most common case.
class AsciiStringReadBenchmark extends BenchmarkBase {
  AsciiStringReadBenchmark() : super('String read: ASCII only');

  late BinaryReader reader;
  late Uint8List buffer;
  late int stringLength;

  @override
  void setup() {
    final writer = BinaryWriter();
    const asciiString = 'Hello, World! This is a test string 123456789';
    stringLength = asciiString.length;

    for (var i = 0; i < 1000; i++) {
      writer.writeString(asciiString);
    }

    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readString(stringLength);
    }
    reader.reset();
  }
}

/// Benchmark for reading short ASCII strings (< 16 chars)
class ShortAsciiStringReadBenchmark extends BenchmarkBase {
  ShortAsciiStringReadBenchmark() : super('String read: short ASCII');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter();
    const strings = [
      'Hi',
      'Test',
      'Hello',
      'OK',
      'Error',
      'Success',
      '123',
      'ABC',
    ];

    // Write 1000 short strings
    for (var i = 0; i < 1000; i++) {
      strings.forEach(writer.writeString);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void run() {
    // Read in same pattern
    for (var i = 0; i < 1000; i++) {
      reader
        ..readString(2) // Hi
        ..readString(4) // Test
        ..readString(5) // Hello
        ..readString(2) // OK
        ..readString(5) // Error
        ..readString(7) // Success
        ..readString(3) // 123
        ..readString(3); // ABC
    }
    reader.reset();
  }
}

/// Benchmark for reading long ASCII strings (> 100 chars)
class LongAsciiStringReadBenchmark extends BenchmarkBase {
  LongAsciiStringReadBenchmark() : super('String read: long ASCII');

  late BinaryReader reader;
  late Uint8List buffer;
  late int stringLength;

  @override
  void setup() {
    final writer = BinaryWriter();
    const longString =
        'The quick brown fox jumps over the lazy dog. '
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
        'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '
        'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.';
    stringLength = longString.length;

    // Write 1000 long ASCII strings
    for (var i = 0; i < 1000; i++) {
      writer.writeString(longString);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readString(stringLength);
    }
    reader.reset();
  }
}

/// Benchmark for reading Cyrillic strings (2-byte UTF-8)
class CyrillicStringReadBenchmark extends BenchmarkBase {
  CyrillicStringReadBenchmark() : super('String read: Cyrillic (2-byte UTF-8)');

  late BinaryReader reader;
  late Uint8List buffer;
  late int byteLength;

  @override
  void setup() {
    final writer = BinaryWriter();
    const cyrillicString = 'Привет мир! Это тестовая строка на русском языке.';
    byteLength = getUtf8Length(cyrillicString);

    // Write 1000 Cyrillic strings
    for (var i = 0; i < 1000; i++) {
      writer.writeString(cyrillicString);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readString(byteLength);
    }
    reader.reset();
  }
}

/// Benchmark for reading CJK strings (3-byte UTF-8)
class CjkStringReadBenchmark extends BenchmarkBase {
  CjkStringReadBenchmark() : super('String read: CJK (3-byte UTF-8)');

  late BinaryReader reader;
  late Uint8List buffer;
  late int byteLength;

  @override
  void setup() {
    final writer = BinaryWriter();
    const cjkString = '你好世界！这是一个测试字符串。日本語のテストも含まれています。';
    byteLength = getUtf8Length(cjkString);

    // Write 1000 CJK strings
    for (var i = 0; i < 1000; i++) {
      writer.writeString(cjkString);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readString(byteLength);
    }
    reader.reset();
  }
}

/// Benchmark for reading emoji strings (4-byte UTF-8)
class EmojiStringReadBenchmark extends BenchmarkBase {
  EmojiStringReadBenchmark() : super('String read: Emoji (4-byte UTF-8)');

  late BinaryReader reader;
  late Uint8List buffer;
  late int byteLength;

  @override
  void setup() {
    final writer = BinaryWriter(initialBufferSize: 16384);
    const emojiString = '🚀 🌍 🎉 👍 💻 🔥 ⚡ 🎯 🏆 💡 🌈 ✨ 🎨 🎭 🎪';
    byteLength = getUtf8Length(emojiString);

    // Write 1000 emoji strings
    for (var i = 0; i < 1000; i++) {
      writer.writeString(emojiString);
    }

    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readString(byteLength);
    }
    reader.reset();
  }
}

/// Benchmark for reading mixed Unicode strings
///
/// Real-world strings often contain a mix of ASCII, Latin Extended,
/// Cyrillic, CJK, and emoji characters.
class MixedUnicodeStringReadBenchmark extends BenchmarkBase {
  MixedUnicodeStringReadBenchmark() : super('String read: mixed Unicode');

  late BinaryReader reader;
  late Uint8List buffer;
  late int byteLength;

  @override
  void setup() {
    final writer = BinaryWriter();
    const mixedString = 'Hello мир 世界 🌍! Test тест 测试 🚀';
    byteLength = getUtf8Length(mixedString);

    // Write 1000 mixed strings
    for (var i = 0; i < 1000; i++) {
      writer.writeString(mixedString);
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readString(byteLength);
    }
    reader.reset();
  }
}

/// Benchmark for reading VarString (length-prefixed strings)
class VarStringAsciiReadBenchmark extends BenchmarkBase {
  VarStringAsciiReadBenchmark() : super('VarString read: ASCII');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter();
    const asciiString = 'Hello, World! This is a test string.';

    // Write 1000 VarStrings
    for (var i = 0; i < 1000; i++) {
      writer.writeVarString(asciiString);
    }

    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readVarString();
    }
    reader.reset();
  }
}

/// Benchmark for reading VarString with mixed Unicode
class VarStringMixedReadBenchmark extends BenchmarkBase {
  VarStringMixedReadBenchmark() : super('VarString read: mixed Unicode');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter();
    const mixedString = 'Hello мир 世界 🌍 Test тест 测试 🚀';

    // Write 1000 VarStrings
    for (var i = 0; i < 1000; i++) {
      writer.writeVarString(mixedString);
    }

    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readVarString();
    }
    reader.reset();
  }
}

/// Benchmark for reading empty strings
class EmptyStringReadBenchmark extends BenchmarkBase {
  EmptyStringReadBenchmark() : super('String read: empty strings');

  late BinaryReader reader;
  late Uint8List buffer;

  @override
  void setup() {
    final writer = BinaryWriter();

    // Write 1000 empty strings
    for (var i = 0; i < 1000; i++) {
      writer.writeString('');
    }
    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readString(0);
    }
    reader.reset();
  }
}

/// Benchmark for realistic message protocol with strings
///
/// Simulates reading a typical JSON-like message structure with
/// multiple string fields of varying types and lengths.
class RealisticMessageReadBenchmark extends BenchmarkBase {
  RealisticMessageReadBenchmark() : super('String read: realistic message');

  late BinaryReader reader;
  late Uint8List buffer;
  late List<int> fieldLengths;

  @override
  void setup() {
    final writer = BinaryWriter();

    // Typical message fields
    const fields = [
      'user', // Field name (ASCII)
      'John Doe', // Value (ASCII)
      'email', // Field name (ASCII)
      'john.doe@example.com', // Value (ASCII)
      'message', // Field name (ASCII)
      'Hello 世界! 🌍', // Value (mixed Unicode)
      'timestamp', // Field name (ASCII)
      '2024-12-30T12:00:00Z', // Value (ASCII)
      'locale', // Field name (ASCII)
      'ru-RU', // Value (ASCII)
    ];

    fieldLengths = fields.map(getUtf8Length).toList();

    // Write 1000 messages
    for (var i = 0; i < 1000; i++) {
      fields.forEach(writer.writeString);
    }

    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      fieldLengths.forEach(reader.readString);
    }
    reader.reset();
  }
}

/// Benchmark for alternating short and long strings
class AlternatingStringReadBenchmark extends BenchmarkBase {
  AlternatingStringReadBenchmark() : super('String read: alternating lengths');

  late BinaryReader reader;
  late Uint8List buffer;
  late int shortLength;
  late int longLength;

  @override
  void setup() {
    final writer = BinaryWriter();
    const shortString = 'Hi';
    const longString =
        'This is a much longer string with more content to read and process';

    shortLength = shortString.length;
    longLength = longString.length;

    // Alternate between short and long strings
    for (var i = 0; i < 1000; i++) {
      writer
        ..writeString(shortString)
        ..writeString(longString);
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
        ..readString(shortLength)
        ..readString(longLength);
    }
    reader.reset();
  }
}

/// Benchmark for reading very long strings (> 1KB)
class VeryLongStringReadBenchmark extends BenchmarkBase {
  VeryLongStringReadBenchmark() : super('String read: very long (>1KB)');

  late BinaryReader reader;
  late Uint8List buffer;
  late int stringLength;

  @override
  void setup() {
    final writer = BinaryWriter();
    // Create a ~2KB string
    final longString = 'Lorem ipsum dolor sit amet. ' * 80;
    stringLength = longString.length;

    // Write 1000 very long strings
    for (var i = 0; i < 1000; i++) {
      writer.writeString(longString);
    }

    buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      reader.readString(stringLength);
    }
    reader.reset();
  }
}

void main() {
  test('ASCII string benchmarks:', () {
    AsciiStringReadBenchmark().report();
    ShortAsciiStringReadBenchmark().report();
    LongAsciiStringReadBenchmark().report();
    EmptyStringReadBenchmark().report();
  }, tags: ['benchmark']);

  test('UTF-8 multi-byte benchmarks:', () {
    CyrillicStringReadBenchmark().report();
    CjkStringReadBenchmark().report();
    EmojiStringReadBenchmark().report();
    MixedUnicodeStringReadBenchmark().report();
  }, tags: ['benchmark']);

  test('VarString benchmarks:', () {
    VarStringAsciiReadBenchmark().report();
    VarStringMixedReadBenchmark().report();
  }, tags: ['benchmark']);

  test('Realistic string scenarios:', () {
    RealisticMessageReadBenchmark().report();
    AlternatingStringReadBenchmark().report();
    VeryLongStringReadBenchmark().report();
  }, tags: ['benchmark']);
}
