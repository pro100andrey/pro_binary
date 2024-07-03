import 'dart:typed_data';

import 'package:pro_binary/pro_binary.dart';

void main(List<String> args) {

  print('BinaryWriter\n');
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
    ..writeBytes([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 100, 200, 255])
    ..writeString('Hello, World!');

  final bytes = writer.takeBytes();
  // ignore: avoid_print
  print(bytes);

  print('BinaryReader\n');

  final buffer = Uint8List.fromList([
    42, 214, 255, 255, 0, 128, 255, 255, 255, 255, 0, 0, 0, 128, //
    255, 255, 255, 255, 255, 255, 255, 127, 0, 0, 0, 0, 0, 0, 0, 128, //
    195, 245, 72, 64, 24, 45, 68, 84, 251, 33, 9, 64, //
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 100, 200, 255, //
    72, 101, 108, 108, 111, 44, 32, 119, 111, 114, 108, 100, 33, //
  ]);

  final reader = BinaryReader(buffer);

  final uint8 = reader.readUint8();
  final int8 = reader.readInt8();
  final uint16 = reader.readUint16(Endian.little);
  final int16 = reader.readInt16(Endian.little);
  final uint32 = reader.readUint32(Endian.little);
  final int32 = reader.readInt32(Endian.little);
  final uint64 = reader.readUint64(Endian.little);
  final int64 = reader.readInt64(Endian.little);
  final float32 = reader.readFloat32(Endian.little);
  final float64 = reader.readFloat64(Endian.little);
  final bytesData = reader.readBytes(13);
  final string = reader.readString(13);

  // ignore: avoid_print
  print([
    uint8,
    int8,
    uint16,
    int16,
    uint32,
    int32,
    uint64,
    int64,
    float32,
    float64,
    bytesData,
    string,
  ]);
}
