import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:pro_binary/pro_binary.dart';

const longStringWithEmoji =
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

const shortString = 'Hello, World!';

final listUint8 = Uint8List.fromList([
  1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 100, 200, 255, 0, 128, 64, //
]);

final listUint16 = Uint16List.fromList([
  1, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65535, //
]);

final listUint32 = Uint32List.fromList([
  1, 65536, 131072, 262144, 524288, 1048576, 2097152, 4194304, 8388608,
  16777216, 33554432, 67108864, 134217728, 268435456, 536870912, 1073741824,
  2147483648, 4294967295, //
]);

final listFloat32 = Float32List.fromList([
  3.14, 2.71, 1.618, 0.5772, 1.4142, 0.6931, 2.3025, 1.732, 0.0, -1.0, -3.14, //
]).buffer.asUint8List();

class BinaryWriterBenchmark extends BenchmarkBase {
  BinaryWriterBenchmark() : super('BinaryWriter performance test');

  late final BinaryWriter writer;

  @override
  void setup() {
    writer = BinaryWriter();
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      writer
        ..writeUint8(42)
        ..writeInt8(-42)
        ..writeUint16(65535, .little)
        ..writeUint16(10)
        ..writeInt16(-32768, .little)
        ..writeInt16(-10)
        ..writeUint32(4294967295, .little)
        ..writeUint32(100)
        ..writeInt32(-2147483648, .little)
        ..writeInt32(-100)
        ..writeUint64(9223372036854775807, .little)
        ..writeUint64(1000)
        ..writeInt64(-9223372036854775808, .little)
        ..writeInt64(-1000)
        ..writeFloat32(3.14, .little)
        ..writeFloat32(2.71)
        ..writeFloat64(3.141592653589793, .little)
        ..writeFloat64(2.718281828459045)
        ..writeBytes(listUint8)
        ..writeBytes(listUint16)
        ..writeBytes(listUint32)
        ..writeBytes(listFloat32)
        ..writeString(shortString)
        ..writeString(longStringWithEmoji);

      final bytes = writer.takeBytes();

      if (writer.bytesWritten != 0) {
        throw StateError('bytesWritten should be reset to 0 after takeBytes()');
      }

      if (bytes.length != 1432) {
        throw StateError('Unexpected byte length: ${bytes.length}');
      }
    }
  }

  @override
  void exercise() => run();
  static void main() {
    BinaryWriterBenchmark().report();
  }
}

class FastBinaryWriterBenchmark extends BenchmarkBase {
  FastBinaryWriterBenchmark() : super('FastBinaryWriter performance test');

  late final FastBinaryWriter writer;

  @override
  void setup() {
    writer = FastBinaryWriter();
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      writer
        ..writeUint8(42)
        ..writeInt8(-42)
        ..writeUint16(65535, .little)
        ..writeUint16(10)
        ..writeInt16(-32768, .little)
        ..writeInt16(-10)
        ..writeUint32(4294967295, .little)
        ..writeUint32(100)
        ..writeInt32(-2147483648, .little)
        ..writeInt32(-100)
        ..writeUint64(9223372036854775807, .little)
        ..writeUint64(1000)
        ..writeInt64(-9223372036854775808, .little)
        ..writeInt64(-1000)
        ..writeFloat32(3.14, .little)
        ..writeFloat32(2.71)
        ..writeFloat64(3.141592653589793, .little)
        ..writeFloat64(2.718281828459045)
        ..writeBytes(listUint8)
        ..writeBytes(listUint16)
        ..writeBytes(listUint32)
        ..writeBytes(listFloat32)
        ..writeString(shortString)
        ..writeString(longStringWithEmoji);

      final bytes = writer.takeBytes();

      if (writer.bytesWritten != 0) {
        throw StateError('bytesWritten should be reset to 0 after takeBytes()');
      }

      if (bytes.length != 1432) {
        throw StateError('Unexpected byte length: ${bytes.length}');
      }
    }
  }

  @override
  void exercise() => run();
  static void main() {
    FastBinaryWriterBenchmark().report();
  }
}

void main() {
  BinaryWriterBenchmark.main();
  FastBinaryWriterBenchmark.main();
}
