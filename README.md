# pro_binary

[![pub package](https://img.shields.io/pub/v/pro_binary.svg)](https://pub.dev/packages/pro_binary)
[![Tests](https://github.com/pro100andrey/pro_binary/workflows/Tests/badge.svg)](https://github.com/pro100andrey/pro_binary/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

High-performance binary serialization for Dart. Fast, type-safe, and easy to use.

## Why pro_binary?

- 🚀 **Fast**: Optimized for performance with zero-copy operations
- 🎯 **Type-safe**: Full support for all Dart primitive types
- 🔍 **Developer-friendly**: Clear error messages in debug mode
- 📦 **Smart**: Auto-expanding buffers, VarInt encoding for smaller payloads
- 🌐 **Flexible**: Big-endian and little-endian support

## Installation

```yaml
dependencies:
  pro_binary: ^3.0.0
```

## Quick Start

```dart
import 'package:pro_binary/pro_binary.dart';

// Writing data
final writer = BinaryWriter();
writer.writeUint32(42);
writer.writeString('Hello, World!');
final bytes = writer.takeBytes();

// Reading data
final reader = BinaryReader(bytes);
final number = reader.readUint32();    // 42
final text = reader.readString(13);     // 'Hello, World!'
```

## Core API

### Writing Data

```dart
final writer = BinaryWriter();

// Integers (8, 16, 32, 64-bit signed/unsigned)
writer.writeUint8(255);
writer.writeInt32(-1000, Endian.little);
writer.writeUint64(9999999);

// Floats
writer.writeFloat32(3.14);
writer.writeFloat64(3.14159265359);

// Variable-length integers (space-efficient!)
writer.writeVarUint(42);        // Unsigned VarInt
writer.writeVarInt(-42);        // Signed VarInt with ZigZag

// Strings
writer.writeString('text');     // Fixed UTF-8 string (you control length)
writer.writeVarString('Hello'); // Length-prefixed UTF-8 string (auto length)

// Get result
final bytes = writer.takeBytes();  // Gets bytes and resets
// or
final view = writer.toBytes();     // Gets bytes, keeps state
```

### Reading Data

```dart
final reader = BinaryReader(bytes);

// Read primitives (matching write order)
final u8 = reader.readUint8();
final i32 = reader.readInt32(Endian.little);
final f64 = reader.readFloat64();

// Variable-length integers
final count = reader.readVarUint();
final delta = reader.readVarInt();

// Strings
final text = reader.readString(10);     // Read 10 UTF-8 bytes (you specify length)
final message = reader.readVarString(); // Read length-prefixed string (auto length)

// Navigation
reader.skip(4);                    // Skip bytes
final peek = reader.peekBytes(2);  // Look ahead without consuming
reader.reset();                    // Go back to start

// Check state
print(reader.offset);              // Current position
print(reader.availableBytes);      // Bytes left to read
```

## Real-World Examples

### Protocol Messages

```dart
// Encode message
final writer = BinaryWriter();
writer.writeUint8(0x42);           // Message type
writer.writeVarUint(payload.length);
writer.writeBytes(payload);
sendToServer(writer.takeBytes());

// Decode message
final reader = BinaryReader(received);
final type = reader.readUint8();
final length = reader.readVarUint();
final payload = reader.readBytes(length);
```

### Length-Prefixed Strings

```dart
// Write
final text = 'Hello, 世界! 🌍';
final encoded = utf8.encode(text);
writer.writeVarUint(encoded.length);
writer.writeString(text);

// Read
final length = reader.readVarUint();
final text = reader.readString(length);
```

### Struct-like Data

```dart
class Player {
  final int id;
  final String name;
  final double x, y;

  void writeTo(BinaryWriter w) {
    w.writeUint32(id);
    final nameBytes = utf8.encode(name);
    w.writeVarUint(nameBytes.length);
    w.writeString(name);
    w.writeFloat64(x);
    w.writeFloat64(y);
  }

  static Player readFrom(BinaryReader r) {
    final id = r.readUint32();
    final nameLen = r.readVarUint();
    final name = r.readString(nameLen);
    final x = r.readFloat64();
    final y = r.readFloat64();
    return Player(id, name, x, y);
  }
}
```

## VarInt Encoding

VarInt uses fewer bytes for small numbers:

```dart
writer.writeVarUint(42);        // 1 byte  (vs 4 for Uint32)
writer.writeVarUint(300);       // 2 bytes
writer.writeVarUint(1000000);   // 3 bytes

writer.writeVarInt(-1);         // 1 byte  (ZigZag encoded)
writer.writeVarInt(-1000);      // 2 bytes
```

**Use VarUint** for: lengths, counts, IDs  
**Use VarInt** for: deltas, offsets, signed values

## Encoding Efficiency

VarInt encoding significantly reduces payload size for small values:

| Value | VarInt | Fixed Uint32 | Savings |
| ------- | -------- | -------------- | --------- |
| 0 | 1 byte | 4 bytes | **75%** |
| 42 | 1 byte | 4 bytes | **75%** |
| 127 | 1 byte | 4 bytes | **75%** |
| 128 | 2 bytes | 4 bytes | **50%** |
| 300 | 2 bytes | 4 bytes | **50%** |
| 16,384 | 3 bytes | 4 bytes | **25%** |
| 1,000,000 | 3 bytes | 4 bytes | **25%** |
| 268,435,455 | 4 bytes | 4 bytes | **0%** |

**Use VarInt for:** lengths, counts, sizes, small IDs  
**Use fixed-width for:** timestamps, coordinates, fixed-size IDs

## Tips & Best Practices

**Buffer Sizing**: Writer starts at 128 bytes and auto-expands. For large data, set initial size:

```dart
final writer = BinaryWriter(initialBufferSize: 1024);
```

**Endianness**: Defaults to big-endian. Specify when needed:

```dart
writer.writeUint32(value, Endian.little);
```

**String Encoding**: Always use length-prefix for variable strings:

```dart
// ✅ Good
final bytes = utf8.encode(text);
writer.writeVarUint(bytes.length);
writer.writeString(text);

// ❌ Bad - no way to know where string ends
writer.writeString(text);
```

**Error Handling**: Invalid data and out-of-bounds reads/writes throw `RangeError`. Catch errors for user input:

```dart
try {
  final value = reader.readUint32();
} catch (e) {
  print('Invalid data: $e');
}
```

## Testing

Comprehensive test suite with **336+ tests** covering:

- ✅ **VarInt/VarUint encoding** - 70+ dedicated tests for variable-length integers
- ✅ **All data types** - Exhaustive testing of read/write operations
- ✅ **Edge cases** - Boundary conditions, overflow, special values
- ✅ **UTF-8 handling** - Multi-byte characters, emojis, malformed sequences
- ✅ **Round-trip validation** - Ensures data integrity through encode/decode cycles
- ✅ **Performance benchmarks** - Tracks optimization effectiveness

Run tests:

```bash
dart test -x benchmark            # Run unit/integration tests (skip benchmarks)
dart test -t benchmark            # Run performance benchmarks only
dart test                         # Run everything (including benchmarks)
dart test test/binary_reader_test.dart  # Run a single test file
dart analyze                 # Check code quality
```

## Contributing

Found a bug or have a feature idea? [Open an issue](https://github.com/pro100andrey/pro_binary/issues) or submit a PR!

## License

MIT License - see [LICENSE](./LICENSE) for details.
