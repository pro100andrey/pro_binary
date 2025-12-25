import 'dart:convert';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:pro_binary/pro_binary.dart';

const string = 'Hello, World!';
const longString =
    'The quick brown fox 🦊 jumps over the lazy dog 🐕. '
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit 🔬. '
    'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua 🏋️. '
    'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi '
    'ut aliquip ex ea commodo consequat ☕. '
    'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum '
    'dolore eu fugiat nulla pariatur 🌈. '
    'Excepteur sint occaecat cupidatat non proident, '
    'sunt in culpa qui officia deserunt mollit anim id est laborum. 🎯 '
    '🚀 TEST EXTENSION: Adding a second long paragraph to truly stress the '
    'UTF-8 encoding logic. This includes more complex characters like the '
    'Zodiac signs ♒️ ♓️ ♈️ ♉️ and some CJK characters like 日本語. '
    'We also add a few more standard 4-byte emoji like a stack of money 💰, '
    'a ghost 👻, and a classic thumbs up 👍 to ensure maximum complexity '
    'in the string encoding process. The purpose of this extra length is to '
    'force the `_ensureSize` method to be called multiple times and ensure '
    'that the buffer resizing and copying overhead is measured correctly. '
    'This paragraph is deliberately longer to ensure that the total byte '
    'count for UTF-8 is significantly larger than the initial string length. '
    '🏁';

class BinaryReaderBenchmark extends BenchmarkBase {
  BinaryReaderBenchmark() : super('BinaryReader performance test');

  late final BinaryReader reader;

  @override
  void setup() {
    final writer = BinaryWriter()
      ..writeUint8(42)
      ..writeInt8(-42)
      ..writeUint16(65535, .little)
      ..writeInt16(-32768, .little)
      ..writeUint32(4294967295, .little)
      ..writeInt32(-2147483648, .little)
      ..writeUint64(9223372036854775807, .little)
      ..writeInt64(-9223372036854775808, .little)
      ..writeFloat32(3.14, .little)
      ..writeFloat64(3.141592653589793, .little)
      ..writeFloat64(2.718281828459045)
      ..writeVarString(string)
      ..writeVarString(longString)
      ..writeBytes([])
      ..writeBytes(List<int>.filled(120, 100));

    final buffer = writer.takeBytes();
    reader = BinaryReader(buffer);
  }

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      final _ = reader.readUint8();
      final _ = reader.readInt8();
      final _ = reader.readUint16(.little);
      final _ = reader.readInt16(.little);
      final _ = reader.readUint32(.little);
      final _ = reader.readInt32(.little);
      final _ = reader.readUint64(.little);
      final _ = reader.readInt64(.little);
      final _ = reader.readFloat32(.little);
      final _ = reader.readFloat64(.little);
      final _ = reader.readFloat64(.little);
      final _ = reader.readVarString();
      final _ = reader.readVarString();
      final _ = reader.readBytes(0);
      final _ = reader.readBytes(120);

      assert(reader.availableBytes == 0, 'Not all bytes were read');
      reader.reset();
    }
  }

  static void main() {
    BinaryReaderBenchmark().report();
  }
}

class GetStringLengthBenchmark extends BenchmarkBase {
  GetStringLengthBenchmark() : super('GetStringLength performance test');

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      final _ = getUtf8Length(string);
      final _ = getUtf8Length(longString);
      final _ = getUtf8Length(string);
      final _ = getUtf8Length(longString);
      final _ = getUtf8Length(string);
      final _ = getUtf8Length(longString);
      final _ = getUtf8Length(string);
      final _ = getUtf8Length(longString);
      final _ = getUtf8Length(string);
      final _ = getUtf8Length(longString);
      final _ = getUtf8Length(string);
      final _ = getUtf8Length(longString);
      final _ = getUtf8Length(string);
      final _ = getUtf8Length(longString);
    }
  }

  static void main() {
    GetStringLengthBenchmark().report();
  }
}

class GetStringLengthUtf8Benchmark extends BenchmarkBase {
  GetStringLengthUtf8Benchmark()
    : super('GetStringLengthUtf8 performance test');

  @override
  void exercise() => run();

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      final _ = utf8.encode(string).length;
      final _ = utf8.encode(longString).length;
      final _ = utf8.encode(string).length;
      final _ = utf8.encode(longString).length;
      final _ = utf8.encode(string).length;
      final _ = utf8.encode(longString).length;
      final _ = utf8.encode(string).length;
      final _ = utf8.encode(longString).length;
      final _ = utf8.encode(string).length;
      final _ = utf8.encode(longString).length;
      final _ = utf8.encode(string).length;
      final _ = utf8.encode(longString).length;
      final _ = utf8.encode(string).length;
      final _ = utf8.encode(longString).length;
    }
  }

  static void main() {
    GetStringLengthUtf8Benchmark().report();
  }
}

void main() {
  BinaryReaderBenchmark.main();
  GetStringLengthBenchmark.main();
  GetStringLengthUtf8Benchmark.main();
}
