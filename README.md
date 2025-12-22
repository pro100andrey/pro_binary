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
  pro_binary: ^2.1.0
```

Then, run `pub get` to install the package.

## Quick Start

### Writing

```dart
import 'package:pro_binary/pro_binary.dart';

void main() {
  final writer = BinaryWriter()
    ..writeUint8(42)
    ..writeUint32(1000000, .little)
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
  final value2 = reader.readUint32(.little); // 1000000
  
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
writer.writeInt8(-128);
writer.writeUint16(65535, .big);
writer.writeInt16(-32768, .big);
writer.writeUint32(4294967295, .big);
writer.writeInt32(-1000, .big);
writer.writeUint64(9223372036854775807, .big);
writer.writeInt64(-9223372036854775808, .big);
writer.writeFloat32(3.14, .big);
writer.writeFloat64(3.14159, .big);
writer.writeBytes([1, 2, 3]);
writer.writeString('text');

// Buffer operations
final bytes = writer.toBytes();      // Get view without reset
final result = writer.takeBytes();   // Get view and reset
writer.reset();                       // Reset without returning
print(writer.bytesWritten);          // Check written size
```

### BinaryReader

```dart
final reader = BinaryReader(buffer);

// Read operations
final u8 = reader.readUint8();
final i8 = reader.readInt8();
final u16 = reader.readUint16(.big);
final i16 = reader.readInt16(.big);
final u32 = reader.readUint32(.big);
final i32 = reader.readInt32(.little);
final u64 = reader.readUint64(.big);
final i64 = reader.readInt64(.big);
final f32 = reader.readFloat32(.big);
final f64 = reader.readFloat64(.big);
final bytes = reader.readBytes(10);
final text = reader.readString(5);

// Peek without advancing position
final peeked = reader.peekBytes(4);  // View without consuming

// Navigation
reader.skip(4);                      // Skip bytes
final pos = reader.offset;           // Current position
final used = reader.usedBytes;       // Bytes read so far
reader.reset();                      // Reset to start
print(reader.availableBytes);        // Remaining bytes
```

## Error Handling

All read operations validate boundaries and provide detailed error messages:

```dart
try {
  reader.readUint32(); // Not enough bytes
} catch (e) {
  // AssertionError: Not enough bytes to read Uint32: 
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

## Testing

The library includes comprehensive test coverage with **279+ tests** covering:

- **Basic operations**: All read/write methods for each data type
- **Endianness**: Big-endian and little-endian operations
- **Edge cases**: Boundary conditions, overflow, special values (NaN, Infinity)
- **UTF-8 handling**: Multi-byte characters, emoji, malformed sequences
- **Buffer management**: Expansion, growth strategy, memory efficiency
- **Integration tests**: Complete read-write cycles and round-trip validation
- **Performance tests**: Benchmark measurements for optimization

Run tests with:

```bash
dart test
```

Analyze code quality:

```bash
dart analyze
```

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for more details.
