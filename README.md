# pro_binary

[![pub package](https://img.shields.io/pub/v/pro_binary.svg)](https://pub.dev/packages/pro_binary)
[![Tests](https://github.com/pro100andrey/pro_binary/workflows/Tests/badge.svg)](https://github.com/pro100andrey/pro_binary/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

**High-performance binary serialization and deserialization for Dart.** Optimized for high-frequency network protocols, real-time streaming, and fast local storage. Features zero-copy reads, object pooling, and transactional stream parsing.

## Table of Contents

- [pro\_binary](#pro_binary)
  - [Table of Contents](#table-of-contents)
  - [Key Features](#key-features)
  - [Installation](#installation)
  - [Quick Start](#quick-start)
  - [Recipes \& Patterns](#recipes--patterns)
    - [1. Efficient Object Serialization](#1-efficient-object-serialization)
    - [2. High-Frequency writes (Pooling)](#2-high-frequency-writes-pooling)
    - [3. Stream Parsing (Async Binary Messages)](#3-stream-parsing-async-binary-messages)
    - [4. Binary Packets (Manual navigation)](#4-binary-packets-manual-navigation)
  - [Examples](#examples)
  - [API Overview](#api-overview)
  - [Performance](#performance)
    - [String Encoding (One-Pass vs `utf8.encode`)](#string-encoding-one-pass-vs-utf8encode)
    - [Object Serialization \& Deserialization](#object-serialization--deserialization)
    - [Object Pooling](#object-pooling)
  - [Testing](#testing)
  - [Contributing](#contributing)
  - [License](#license)

## Key Features

- **Extreme Performance:** Built from the ground up for speed. Leverages Dart Extension Types for zero-overhead abstractions and direct memory manipulation.
- **Zero-Copy Reads:** Deserialization operations return `Uint8List` views instead of allocating new memory arrays, significantly reducing GC (Garbage Collector) pauses.
- **One-Pass String Encoding:** Features a highly optimized `writeVarString` with optimistic size estimation and native memory shifting. Up to **~30% faster** than standard `utf8.encode`.
- **Zero-Allocation Object Pooling:** Includes built-in `BinaryWriterPool` to reuse writer instances. Perfect for high-frequency network packets (e.g., game servers, WebSockets).
- **Compact Encoding:** Native support for VarInt and ZigZag encoding to shrink payload sizes for integers.
- **Transactional Stream Parsing:** Easily process fragmented asynchronous data chunks using `StreamBinaryReader` with `bookmark()` and `rollback()` capabilities.
- **Cross-Platform:** 100% pure Dart. Works seamlessly across Native (AOT/JIT) and Web (WASM/JS) with a consistent, predictable API.

## Installation

Add `pro_binary` to your `pubspec.yaml` manually:

```yaml
dependencies:
  pro_binary: <latest_version>
```

Or add it using the command line:

```bash
# For Dart projects
dart pub add pro_binary

# For Flutter projects
flutter pub add pro_binary
```

## Quick Start

```dart
import 'package:pro_binary/pro_binary.dart';

// Serialize
final writer = BinaryWriter()
  ..writeUint32(42)
  ..writeVarString('Dart 🚀')
  ..writeBool(true);

final bytes = writer.takeBytes(); // takes the buffer and resets the writer

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
    ..writeVarUint(id)       // compact integer encoding
    ..writeVarString(name);  // fast one-pass UTF-8 encoding

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

- [Basic Usage](example/basic/): Simple serialization and deserialization.
- [File Streaming](example/file_streaming/): Reading and writing large binary files using streams.
- [Network Streaming](example/network_streaming/): Implementing a custom protocol for TCP/Socket data.

## API Overview

[Full API documentation](https://pub.dev/documentation/pro_binary/latest/pro_binary/)

| Component | Description |
| --------- | ----------- |
| **BinaryWriter** | Fast encoder for fixed-width, VarInt/ZigZag, and one-pass strings. Features automatic expansion, pooling, and in-place buffer manipulation (`skip`, `shiftBytes`). |
| **BinaryReader** | Zero-copy decoder with advanced navigation (`seek`, `rewind`, `peek`). Optimized for performance. |
| **StreamBinaryReader** | Handles async data chunks seamlessly with a transactional `bookmark`/`rollback` model for partial data. |
| **BinaryStreamTransformer** | The easiest way to parse a `Stream<List<int>>` into a stream of typed messages or objects. |
| **BinaryWriterPool** | Object pool for `BinaryWriter` to eliminate GC pressure during high-frequency write operations. |

## Performance

`pro_binary` is built for extreme performance. Our AOT benchmarks show massive improvements over standard Dart approaches:

### String Encoding (One-Pass vs `utf8.encode`)

Our highly optimized one-pass string encoder is **up to 2.7x faster** than standard `utf8.encode`.

| Payload | `pro_binary` (One-Pass) | Standard (`utf8.encode`) | Speedup |
| :--- | :--- | :--- | :--- |
| **ASCII** | 0.79 μs | 2.15 μs | **2.7x** |
| **Mixed UTF-8** | 1.15 μs | 2.62 μs | **2.28x** |
| **Emoji / Complex** | 1.91 μs | 4.17 μs | **2.18x** |

### Object Serialization & Deserialization

Extremely low overhead for serializing and deserializing Dart objects.

| Scenario | Serialization | Deserialization |
| :--- | :--- | :--- |
| **Simple Message** | 0.31 μs | 0.14 μs |
| **Complex Profile** | 1.62 μs | 1.73 μs |
| **10K integers array** | 403.5 μs | 284.5 μs |

### Object Pooling

Using `BinaryWriterPool` reduces allocation overhead and virtually eliminates GC (Garbage Collector) pauses during high-frequency writes (like game servers or real-time trading).

---
Run these benchmarks yourself to see it in action:

```bash
# Serialization (Writer)
dart run benchmark_harness:bench --flavor aot --target  performance/serialization_bench.dart

# Deserialization (Reader)
dart run benchmark_harness:bench --flavor aot --target  performance/deserialization_bench.dart

# String encoding (One-pass vs Two-pass vs Standard)
dart run benchmark_harness:bench --flavor aot --target  performance/strings_bench.dart

# Object Pooling (GC impact mitigation)
dart run benchmark_harness:bench --flavor aot --target  performance/pool_bench.dart
```

## Testing

The library is heavily tested with over 200+ unit and integration tests.

```bash
# Run all tests
dart test

# Run tests with coverage
dart test --coverage=coverage
```

## Contributing

Contributions are welcome! Please ensure that all tests pass and code is formatted before submitting a Pull Request.

```bash
# Formatter
dart format .

# Analyzer
dart analyze

# Tests
dart test
```

## License

MIT License. See [LICENSE](LICENSE) for details.
