# pro_binary

[![pub package](https://img.shields.io/pub/v/pro_binary.svg)](https://pub.dev/packages/pro_binary)
[![Tests](https://github.com/pro100andrey/pro_binary/workflows/Tests/badge.svg)](https://github.com/pro100andrey/pro_binary/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

High-performance binary serialization library for Dart with zero-copy operations, efficient memory management, and Protocol Buffers-compatible VarInt encoding.

## Features

- 🚀 **Zero-copy reads**: Direct `Uint8List` views without data duplication
- ⚡ **Optimized writes**: Exponential buffer growth strategy (×1.5) with pooling support
- 🔢 **VarInt encoding**: Protocol Buffers-compatible variable-length integer encoding
- 🎯 **Type-safe API**: Full support for all Dart primitive types (int8-int64, float32/64, bool)
- 🌐 **Endianness support**: Both big-endian (default) and little-endian byte order
- 📦 **Memory efficient**: Automatic buffer management with configurable initial capacity
- 🧪 **Battle-tested**: 556+ tests with extensive edge case coverage

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
writer.writeInt32(-1000, .little);
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
final i32 = reader.readInt32(.little);
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
// or simply
writer.writeVarString(text);

// Read
final length = reader.readVarUint();
final text = reader.readString(length);
// or simply
final text = reader.readVarString();
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

## Architecture

### BinaryWriter

```dart
final writer = BinaryWriter(initialBufferSize: 128); // Default: 128 bytes
```

**Buffer Management:**

- Initial capacity: 128 bytes (configurable)
- Growth strategy: `newCapacity = max(currentCapacity * 1.5, currentCapacity + requiredBytes)` with 64-byte alignment
- Resets buffer without reallocation: `writer.reset()`
- Takes ownership of buffer: `writer.takeBytes()` (one-time use, resets writer)
- Creates view without reset: `writer.toBytes()` (reusable)

**Write Operations:**

- Fixed-width integers: `writeUint8`, `writeInt16`, `writeUint32`, `writeInt64`, etc.
- Variable-length integers: `writeVarUint` (unsigned), `writeVarInt` (ZigZag-encoded signed)
- Floating-point: `writeFloat32`, `writeFloat64`
- Binary data: `writeBytes`, `writeVarBytes` (length-prefixed)
- Strings: `writeString` (raw UTF-8), `writeVarString` (length-prefixed)
- Boolean: `writeBool` (1 byte: 0x00 or 0x01)

### BinaryReader

```dart
final reader = BinaryReader(bytes);
```

**Zero-Copy Design:**

- No buffer copying: operates on `Uint8List.view` of input data
- Direct memory access via `ByteData` for endianness handling
- Automatic offset tracking with bounds checking

**Read Operations:**

- Fixed-width integers: `readUint8`, `readInt16`, `readUint32`, `readInt64`, etc.
- Variable-length integers: `readVarUint`, `readVarInt` (ZigZag-decoded)
- Floating-point: `readFloat32`, `readFloat64`
- Binary data: `readBytes`, `readVarBytes`, `readRemainingBytes`
- Strings: `readString` (raw UTF-8), `readVarString` (length-prefixed)
- Boolean: `readBool`

**Navigation API:**

- `skip(int bytes)`: Move forward by N bytes
- `seek(int position)`: Jump to absolute position
- `rewind(int bytes)`: Move backward by N bytes
- `reset()`: Return to start
- `peekBytes(int length, [int offset])`: Look ahead without consuming
- `hasBytes(int count)`: Check if enough bytes available

**State Inspection:**

- `offset`: Current read position (0-based)
- `length`: Total buffer size
- `availableBytes`: Remaining unread bytes

## VarInt Encoding

VarInt uses fewer bytes for small numbers:

```dart
writer.writeVarUint(42);        // 1 byte  (vs 4 for Uint32)
writer.writeVarUint(300);       // 2 bytes
writer.writeVarUint(1000000);   // 3 bytes

writer.writeVarInt(-1);         // 1 byte  (ZigZag encoded)
writer.writeVarInt(-1000);      // 2 bytes
```

**Implementation Details:**

- Protocol Buffers Base 128 Varint encoding
- 7 data bits + 1 continuation bit per byte
- Maximum 10 bytes for 64-bit values
- ZigZag encoding for signed integers: `(n << 1) ^ (n >> 63)`
- Fast path optimization for single-byte values (0-127)

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

### Performance Optimization

**Pre-allocate buffers** for known data sizes:

```dart
// For ~1KB messages
final writer = BinaryWriter(initialBufferSize: 1024);

// Avoid multiple small allocations
final writer = BinaryWriter(initialBufferSize: 8192); // For bulk writes
```

**Use object pooling** for high-frequency operations:

```dart
// Acquire from pool
final writer = BinaryWriterPool.acquire();
try {
  writer.writeUint32(value);
  final bytes = writer.takeBytes();
  send(bytes);
} finally {
  // Return to pool for reuse
  BinaryWriterPool.release(writer);
}

// Pool statistics
print(BinaryWriterPool.poolSize);      // Available writers
print(BinaryWriterPool.peakPoolSize);  // High water mark
```

**Choose correct integer type**:

```dart
// VarInt for small values (lengths, counts)
writer.writeVarUint(items.length);  // 1 byte for length < 128

// Fixed-width for large/unpredictable values
writer.writeUint32(timestamp);      // Always 4 bytes, predictable
writer.writeUint64(uuid);           // Fixed 8 bytes
```

### Endianness

Default: **big-endian** (network byte order). Specify when needed:

```dart
// Explicit endianness
writer.writeUint32(value, .little);
writer.writeFloat64(3.14, .big);

// Reading must match writing
final value = reader.readUint32(.little);
```

**When to use little-endian:**

- Interop with x86/ARM systems (native byte order)
- Matching existing binary formats (e.g., RIFF, BMP)
- Performance-critical code on little-endian CPUs

### String Encoding

Always use **length-prefixed** encoding for variable-length strings:

```dart
// ✅ Good: Self-describing
writer.writeVarString('Hello');
// Equivalent to:
// writer.writeVarUint(utf8.encode('Hello').length);
// writer.writeString('Hello');

// ❌ Bad: No way to determine string boundaries
writer.writeString('Hello');
writer.writeString('World'); // Where does first string end?
```

For **fixed-length** strings, calculate UTF-8 byte length:

```dart
final text = 'Hello, 世界!';
final bytes = utf8.encode(text);
writer.writeUint16(bytes.length);  // Store byte length
writer.writeString(text);

// Reading
final byteLength = reader.readUint16();
final text = reader.readString(byteLength);
```

### Error Handling

All operations throw `RangeError` on invalid data or buffer overflow:

```dart
// Buffer underflow
try {
  final value = reader.readUint32(); // Not enough bytes
} on RangeError catch (e) {
  print('Buffer underflow: $e');
}

// Invalid VarInt
try {
  final value = reader.readVarInt(); // Malformed encoding
} on FormatException catch (e) {
  print('Invalid VarInt: $e');
}

// String decoding errors
try {
  final text = reader.readString(10, allowMalformed: false);
} on FormatException catch (e) {
  print('Invalid UTF-8: $e');
}
```

### Design Patterns

**Tagged unions** (discriminated unions):

```dart
enum MessageType { ping, data, ack }

void writeMessage(BinaryWriter w, MessageType type, dynamic payload) {
  w.writeUint8(type.index);
  switch (type) {
    case MessageType.ping:
      // No payload
      break;
    case MessageType.data:
      w.writeVarBytes(payload as List<int>);
      break;
    case MessageType.ack:
      w.writeUint32(payload as int); // Sequence number
      break;
  }
}
```

**Version-tolerant serialization**:

```dart
class Message {
  static const int version = 2;
  
  void writeTo(BinaryWriter w) {
    w.writeUint8(version);        // Version byte
    w.writeVarUint(id);            // Field 1
    w.writeVarString(text);        // Field 2
    // Version 2: added timestamp
    if (version >= 2) {
      w.writeUint64(timestamp);
    }
  }
  
  static Message readFrom(BinaryReader r) {
    final ver = r.readUint8();
    final id = r.readVarUint();
    final text = r.readVarString();
    final timestamp = ver >= 2 ? r.readUint64() : 0;
    return Message(id, text, timestamp);
  }
}
```

## Testing

Comprehensive test suite with **556 tests** covering:

- ✅ **Unit tests (417)**: Isolated BinaryReader/Writer method testing
  - All primitive types (int8-int64, float32/64, bool)
  - VarInt/VarUint encoding/decoding (70+ dedicated tests)
  - Boundary conditions and overflow detection
  - UTF-8 handling (multi-byte chars, emojis, malformed sequences)
  - Navigation API (seek, skip, rewind, peek)
  - Error handling and exception cases

- ✅ **Integration tests (92)**: End-to-end roundtrip validation
  - Write → Read consistency for all data types
  - Buffer expansion under load
  - Complex data structure serialization

- ✅ **Performance benchmarks (51)**: Optimization tracking
  - Read/write throughput for all operations
  - Buffer growth patterns
  - VarInt encoding efficiency by value range
  - Navigation operation costs

Run tests:

```bash
# Run unit + integration tests (skip benchmarks)
dart test -x benchmark

# Run performance benchmarks only  
dart test -t benchmark

# Run all tests including benchmarks
dart test

# Run specific test file
dart test test/unit/binary_reader_test.dart

# Run with coverage
dart pub global activate coverage
dart pub global run coverage:test_with_coverage -- -x benchmark

# Code analysis
dart analyze --fatal-infos
dart format --set-exit-if-changed .
```

## Contributing

Contributions are welcome! Please:

1. **Open an issue** first to discuss major changes
2. **Follow existing code style** (run `dart format`)
3. **Add tests** for new features (maintain >95% coverage)
4. **Update documentation** including README examples
5. **Run full test suite** before submitting PR

   ```bash
   dart analyze --fatal-infos
   dart format --set-exit-if-changed .
   dart test
   ```

See [CONTRIBUTING.md](./CONTRIBUTING.md) for detailed guidelines.

## License

MIT License - see [LICENSE](./LICENSE) for details.

---

Need help? Found a bug? Have a feature request?  
👉 [Open an issue](https://github.com/pro100andrey/pro_binary/issues)
