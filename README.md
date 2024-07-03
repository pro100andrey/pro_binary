# pro_binary - Binary Read/Write Library

This library provides efficient binary reading and writing capabilities in Dart. It supports various data types and endianness, making it ideal for low-level data manipulation and network protocols.

## Features

- Read and write operations for various data types (e.g., int8, uint8, int16, uint16, int32, uint32, int64, uint64, float32, float64).
- Support for both big-endian and little-endian formats.
- Efficient memory management with dynamic buffer resizing.

## Installation

Add this to your package's `pubspec.yaml` file:

``` yaml
dependencies:
  pro_binary: ^1.0.0
```

Then, run `pub get` to install the package.

## Usage

### Writing Binary Data

``` dart
import 'package:binary_rw/binary_writer.dart';

void main() {
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
  print(bytes);
}
```

### Reading Binary Data

``` dart
import 'package:binary_rw/binary_reader.dart';

void main() {
  final buffer = Uint8List.fromList([
    42, 214, 255, 255, 0, 128, 255, 255, 255, 255, 0, 0, 0, 128,
    255, 255, 255, 255, 255, 255, 255, 127, 0, 0, 0, 0, 0, 0, 0, 128,
    195, 245, 72, 64, 24, 45, 68, 84, 251, 33, 9, 64,
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 100, 200, 255, 72,
    72, 101, 108, 108, 111, 44, 32, 119, 111, 114, 108, 100, 33
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
  final bytes = reader.readBytes(13);
  final string = reader.readString(13);

  print([uint8, int8, uint16, int16, uint32, int32, uint64, int64, float32, float64, bytes, string]);
}
```

## Running Tests

To run the tests, use the following command:

``` bash
dart test
```

This will execute all tests in the `test` directory and provide a summary of the results.

## Contributing

Feel free to open issues or submit pull requests on GitHub. Contributions are always welcome!

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for more details.
