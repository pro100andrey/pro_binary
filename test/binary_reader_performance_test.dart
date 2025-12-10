import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:pro_binary/pro_binary.dart';

class BinaryReaderBenchmark extends BenchmarkBase {
  BinaryReaderBenchmark() : super('BinaryReader performance test');

  late final BinaryReader reader;

  @override
  void setup() {
    const string = 'Hello, World!';
    const longString =
        'Some more data to increase buffer usage. '
        'The quick brown fox jumps over the lazy dog.';

    final writer = BinaryWriter()
      ..writeUint8(42)
      ..writeInt8(-42)
      ..writeUint16(65535, Endian.little)
      ..writeInt16(-32768, Endian.little)
      ..writeUint32(4294967295, Endian.little)
      ..writeInt32(-2147483648, Endian.little)
      ..writeUint64(9223372036854775807, Endian.little)
      ..writeInt64(-9223372036854775808, Endian.little)
      ..writeFloat32(3.14, Endian.little)
      ..writeFloat64(3.141592653589793, Endian.little)
      ..writeFloat64(2.718281828459045)
      ..writeInt8(string.length)
      ..writeString(string)
      ..writeInt32(longString.length)
      ..writeString(longString)
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
      final _ = reader.readUint16(Endian.little);
      final _ = reader.readInt16(Endian.little);
      final _ = reader.readUint32(Endian.little);
      final _ = reader.readInt32(Endian.little);
      final _ = reader.readUint64(Endian.little);
      final _ = reader.readInt64(Endian.little);
      final _ = reader.readFloat32(Endian.little);
      final _ = reader.readFloat64(Endian.little);
      final _ = reader.readFloat64(Endian.little);
      final length = reader.readInt8();
      final _ = reader.readString(length);
      final longLength = reader.readInt32();
      final _ = reader.readString(longLength);
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

void main() {
  BinaryReaderBenchmark.main();
}
