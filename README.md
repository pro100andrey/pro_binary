# pro_binary

[![pub package](https://img.shields.io/pub/v/pro_binary.svg)](https://pub.dev/packages/pro_binary)
[![Tests](https://github.com/pro100andrey/pro_binary/workflows/Tests/badge.svg)](https://github.com/pro100andrey/pro_binary/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

**High-performance binary serialization and deserialization for Dart.** Optimized for high-frequency network protocols, real-time streaming, and fast local storage. Features zero-copy reads, object pooling, and transactional stream parsing.

## Key Features

* **Extreme Performance:** Built from the ground up for speed. Leverages Dart Extension Types for zero-overhead abstractions and direct memory manipulation.
* **Zero-Copy Reads:** Deserialization operations return `Uint8List` views instead of allocating new memory arrays, significantly reducing GC (Garbage Collector) pauses.
* **One-Pass String Encoding:** Features a highly optimized `writeVarString` with optimistic size estimation and native memory shifting. Up to **~30% faster** than standard `utf8.encode`.
* **Zero-Allocation Object Pooling:** Includes built-in `BinaryWriterPool` to reuse writer instances. Perfect for high-frequency network packets (e.g., game servers, WebSockets).
* **Compact Encoding:** Native support for VarInt and ZigZag encoding to shrink payload sizes for integers.
* **Transactional Stream Parsing:** Easily process fragmented asynchronous data chunks using `StreamBinaryReader` with `bookmark()` and `rollback()` capabilities.
* **Cross-Platform:** 100% pure Dart. Works seamlessly across Native (AOT/JIT) and Web (WASM/JS) with a consistent, predictable API.

## Installation

```yaml
dependencies:
  pro_binary: ^5.1.0
```

## Quick Start

```dart
import 'package:pro_binary/pro_binary.dart';

// Serialize
final writer = BinaryWriter()
  ..writeUint32(42)
  ..writeVarString('Dart 🚀')
  ..writeBool(true);

final bytes = writer.takeBytes();

// Deserialize
final reader = BinaryReader(bytes);
print(reader.readUint32());    // 42
print(reader.readVarString()); // Dart 🚀
print(reader.readBool());      // true

// From List<int>
final bytesList = <int>[0x01, 0x02, 0x03, 0x04];
final reader2 = BinaryReader.fromList(bytesList);
```

## Recipes & Patterns

### 1. Efficient Object Serialization

```dart
class User {
  final int id;
  final String name;

  User(this.id, this.name);

  void encode(BinaryWriter w) => w
    ..writeVarUint(id)
    ..writeVarString(name);

  factory User.decode(BinaryReader r) =>
    User(
      r.readVarUint(), 
      r.readVarString(),
    );
}
```

### 2. High-Frequency writes (Pooling)

Avoid GC pressure by reusing writer instances.

**Recommended (Safe & Concise):**

```dart
final data = BinaryWriterPool.withWriter((writer) {
  writer.writeUint32(1);
  writer.writeVarString('Dart Rocks!');
  
  // toBytes(): returns a zero-copy VIEW. Use for immediate processing (e.g. socket.add).
  // takeBytes(): detaches the buffer and RESETS the writer. Safe for returning data.
  return writer.takeBytes(); 
});
```

**Low-level API:**

```dart
final writer = BinaryWriterPool.acquire();
try {
  writer.writeUint32(1);
  writer.writeVarString('Dart Rocks!');
  
  final data = writer.toBytes();
  socket.add(data); // Process data BEFORE releasing back to the pool
} finally {
  BinaryWriterPool.release(writer);
}
```

### 3. Stream Parsing (Async Binary Messages)

Process binary data arriving in chunks over a stream.

**Custom Transformer:**

```dart
class MessageParser extends BinaryStreamTransformer<Message> {
  @override
  Message? parse(StreamBinaryReader reader) {
    // Return null when not enough data yet
    if (!reader.hasBytes(4))  {
      return null;
    }

    final id = reader.readUint32();
    final name = reader.readVarString();

    return Message(id, name);
  }
}

// Usage:
stream.transform(MessageParser()).listen((msg) => print(msg));
```

**Manual Chunk Reading:**

```dart
final reader = StreamBinaryReader();
reader.addChunk(chunk1);
reader.addChunk(chunk2);

reader.bookmark();
try {
  final id = reader.readUint32();
  final name = reader.readVarString();
  reader.commit(); // Success — consumed
} on NotEnoughDataException {
  reader.rollback(); // Wait for more data
}
```

### 4. Binary Packets (Manual navigation)

```dart
final reader = BinaryReader(bytes);
final type = reader[0]; // Absolute peek via operator []
reader.skip(1);
if (reader.hasBytes(4)) {
  final payload = reader(4); // Concise call syntax for readBytes.
}
```

## Examples

Explore the [example](example/) directory for complete, runnable projects:

* [Basic Usage](example/basic/): Simple serialization and deserialization.
* [File Streaming](example/file_streaming/): Reading and writing large binary files using streams.
* [Network Streaming](example/network_streaming/): Implementing a custom protocol for TCP/Socket data.

## API Overview

[Full API documentation](https://pub.dev/documentation/pro_binary/latest/pro_binary/)

| Component | Description |
| --------- | ----------- |
| **BinaryWriter** | Fast encoder for fixed-width, VarInt/ZigZag, and one-pass strings. Features automatic expansion and pooling. |
| **BinaryReader** | Zero-copy decoder with advanced navigation (`seek`, `rewind`, `peek`). Optimized for performance. |
| **StreamBinaryReader** | Handles async data chunks seamlessly with a transactional `bookmark`/`rollback` model for partial data. |
| **BinaryStreamTransformer** | The easiest way to parse a `Stream<List<int>>` into a stream of typed messages or objects. |
| **BinaryWriterPool** | Object pool for `BinaryWriter` to eliminate GC pressure during high-frequency write operations. |
| **getUtf8Length** | High-speed utility to calculate UTF-8 byte length without encoding (O(n) but heavily optimized). |
| **TransactionalReader** | Base interface for custom transactional readers. Used internally by `StreamBinaryReader`. |

## Performance

Run benchmarks to see it in action:

```bash
# Serialization (Writer)
dart run performance/serialization_bench.dart

# Deserialization (Reader)
dart run performance/deserialization_bench.dart

# String encoding (One-pass vs Two-pass vs Standard)
dart run performance/strings_bench.dart

# Object Pooling (GC impact mitigation)
dart run performance/pool_bench.dart
```

## Testing

The library is heavily tested with over 200+ unit and integration tests.

```bash
# Run all tests
dart test

# Run tests with coverage
dart test --coverage=coverage
```

## License

MIT License. See [LICENSE](LICENSE) for details.
