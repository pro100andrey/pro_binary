# pro_binary

[![pub package](https://img.shields.io/pub/v/pro_binary.svg)](https://pub.dev/packages/pro_binary)
[![Tests](https://github.com/pro100andrey/pro_binary/workflows/Tests/badge.svg)](https://github.com/pro100andrey/pro_binary/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Efficient binary serialization library for Dart with comprehensive boundary checks and detailed error messages.

## Features

- ✅ Read/write operations for all primitive types (int8/16/32/64, uint8/16/32/64, float32/64)
- ✅ Big-endian and little-endian support
- ✅ Comprehensive boundary checks with detailed error messages
- ✅ UTF-8 string encoding with multibyte character support
- ✅ Dynamic buffer resizing with efficient memory management
- ✅ Zero-copy operations where possible

## Installation

Add this to your package's `pubspec.yaml` file:

``` yaml
dependencies:
  pro_binary: ^2.0.0
```

Then, run `pub get` to install the package.

## Quick Start

### Writing

```dart
import 'package:pro_binary/pro_binary.dart';

void main() {
  final writer = BinaryWriter()
    ..writeUint8(42)
    ..writeUint32(1000000, Endian.little)
    ..writeFloat64(3.14159)
    ..writeString('Hello');

  final bytes = writer.takeBytes();
  print('Written ${bytes.length} bytes');
}
```

### Reading

```dart
import 'dart:typed_data';
import 'package:pro_binary/pro_binary.dart';

void main() {
  final data = Uint8List.fromList([42, 64, 66, 15, 0]);
  final reader = BinaryReader(data);

  final value1 = reader.readUint8();           // 42
  final value2 = reader.readUint32(Endian.little); // 1000000
  
  print('Read: $value1, $value2');
  print('Remaining: ${reader.availableBytes} bytes');
}
```

## API Overview

### BinaryWriter

```dart
final writer = BinaryWriter(initialBufferSize: 64);

// Write operations
writer.writeUint8(255);
writer.writeInt32(-1000, Endian.big);
writer.writeFloat64(3.14);
writer.writeBytes([1, 2, 3]);
writer.writeString('text');

// Buffer operations
final bytes = writer.toBytes();      // Get copy without reset
final result = writer.takeBytes();   // Get and reset
writer.clear();                       // Reset without returning
print(writer.bytesWritten);          // Check written size
```

### BinaryReader

```dart
final reader = BinaryReader(buffer);

// Read operations
final u8 = reader.readUint8();
final i32 = reader.readInt32(Endian.little);
final f64 = reader.readFloat64();
final bytes = reader.readBytes(10);
final text = reader.readString(5);

// Navigation
reader.skip(4);                      // Skip bytes
final pos = reader.offset;           // Current position
reader.reset();                      // Reset to start
print(reader.availableBytes);        // Remaining bytes
```

## Error Handling

All read operations validate boundaries and provide detailed error messages:

```dart
try {
  reader.readUint32(); // Not enough bytes
} catch (e) {
  // RangeError: Not enough bytes to read Uint32: 
  // required 4 bytes, available 2 bytes at offset 10
}
```

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on:

- How to set up the development environment
- Running tests and coverage
- Code style and formatting
- Submitting pull requests

For bugs and features, use the [issue templates](https://github.com/pro100andrey/pro_binary/issues/new/choose).

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for more details.
