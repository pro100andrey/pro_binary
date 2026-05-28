# pro_binary

[![pub package](https://img.shields.io/pub/v/pro_binary.svg)](https://pub.dev/packages/pro_binary)
[![Tests](https://github.com/pro100andrey/pro_binary/workflows/Tests/badge.svg)](https://github.com/pro100andrey/pro_binary/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

**High-performance binary serialization for Dart.** Optimized for speed, zero-copy reads, and Protocol Buffers-compatible encoding.

## Key Features

* **Zero-Copy Reads**: Operations return `Uint8List` views without allocation.
* **One-Pass Strings**: Optimized `writeVarString` with optimistic shift (30% faster).
* **Smart Buffering**: Exponential growth (×1.5) and object pooling.
* **Compact Encoding**: VarInt & ZigZag support
* **Stream Parsing**: `StreamBinaryReader` and `BinaryStreamTransformer` for async data. Extensible via `TransactionalReader` and `TransactionalStreamTransformer`.
* **Universal**: Supports Native & Web (WASM/JS) with consistent API.
* **Modern API**: Leverages Dart Extension Types for zero-overhead abstractions.

## Installation

```yaml
dependencies:
  pro_binary: ^5.0.0
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

| Class | Description |
| ----- | ------------ |
| **BinaryWriter** | Encode data: fixed types, VarInt/ZigZag, strings, bytes. Supports `takeBytes()`, `toBytes()`, `reset()`, `seek()`. |
| **BinaryReader** | Decode data: all fixed/variable types, navigation (`skip`, `seek`, `rewind`, `peek`), `rebind()` for reuse. |
| **StreamBinaryReader** | Async streaming: chunk-based reading with `bookmark`/`rollback`/`commit` transactional model. |
| **BinaryStreamTransformer\<T\>** | Stream parser: extend and implement `parse()` to process binary streams. |
| **TransactionalStreamTransformer\<TMessage, TChunk, TReader\>** | Generic stream transformer: extend for custom chunk types and readers. |
| **BinaryWriterPool** | Object pool: `acquire()`/`release()` or `withWriter()` for high-frequency writes. |
| **getUtf8Length** | Utility: calculate UTF-8 byte length without encoding. |

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
