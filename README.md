# pro_binary

[![pub package](https://img.shields.io/pub/v/pro_binary.svg)](https://pub.dev/packages/pro_binary)
[![Tests](https://github.com/pro100andrey/pro_binary/workflows/Tests/badge.svg)](https://github.com/pro100andrey/pro_binary/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

**High-performance binary serialization for Dart.** Optimized for speed, zero-copy reads, and Protocol Buffers-compatible encoding.

## 🚀 Key Features

*   ⚡ **Zero-Copy Reads**: Operations return `Uint8List` views without allocation.
*   🚀 **One-Pass Strings**: Optimized `writeVarString` with optimistic shift (30% faster).
*   📦 **Smart Buffering**: Exponential growth (×1.5) and object pooling.
*   🔢 **Compact Encoding**: VarInt & ZigZag support (Protobuf compatible).
*   🌐 **Universal**: Supports Native & Web (WASM/JS) with consistent API.
*   🎯 **Modern API**: Leverages Dart Extension Types for zero-overhead abstractions.

## 📦 Installation

```yaml
dependencies:
  pro_binary: ^3.0.1
```

## ⚡ Quick Start

```dart
import 'package:pro_binary/pro_binary.dart';

// Serialize
final writer = BinaryWriter();
writer
  ..writeUint32(42)
  ..writeVarString('Dart 🚀')
  ..writeBool(true);
final bytes = writer.takeBytes();

// Deserialize
final reader = BinaryReader(bytes);
print(reader.readUint32());    // 42
print(reader.readVarString()); // Dart 🚀
print(reader.readBool());      // true
```

## 🛠️ Recipes & Patterns

### 1. Efficient Object Serialization
```dart
class User {
  final int id;
  final String name;

  User(this.id, this.name);

  void encode(BinaryWriter w) => w..writeVarUint(id)..writeVarString(name);

  factory User.decode(BinaryReader r) => User(r.readVarUint(), r.readVarString());
}
```

### 2. High-Frequency writes (Pooling)
Avoid GC pressure by reusing writer instances.
```dart
final writer = BinaryWriterPool.acquire();
try {
  writer.writeUint32(1);
  final data = writer.toBytes(); // View of the buffer
  // ... process data ...
} finally {
  BinaryWriterPool.release(writer);
}
```

### 3. Binary Packets (Manual navigation)
```dart
final reader = BinaryReader(bytes);
final type = reader[0]; // Absolute peek via operator []
reader.skip(1);
if (reader.hasBytes(4)) {
  final payload = reader(4); // Concise call syntax for readBytes
}
```

## 🔢 VarInt Efficiency

VarInt encoding reduces payload size by up to **75%** for small values:

| Value | VarInt Size | Fixed Uint32 | Savings |
| :--- | :--- | :--- | :--- |
| `0..127` | 1 byte | 4 bytes | **75%** |
| `128..16,383` | 2 bytes | 4 bytes | **50%** |
| `16,384..2,097,151` | 3 bytes | 4 bytes | **25%** |

*Use `writeVarUint` for lengths/counts and `writeVarInt` (ZigZag) for signed deltas.*

## 📚 API Reference Summary

### **BinaryWriter**
*   **Fixed:** `writeUint8`, `writeInt16`, `writeUint32`, `writeInt64`, `writeFloat64`, `writeBool`.
*   **Variable:** `writeVarUint` (unsigned), `writeVarInt` (signed).
*   **Data:** `writeBytes`, `writeVarBytes`, `writeString`, `writeVarString`.
*   **Management:** `takeBytes()` (reset), `toBytes()` (view), `reset()`.

### **BinaryReader**
*   **Fixed:** `readUint8`, `readInt16`, `readUint32`, `readInt64`, `readFloat64`, `readBool`.
*   **Variable:** `readVarUint`, `readVarInt`.
*   **Data:** `readBytes`, `readVarBytes`, `readString`, `readVarString`, `readRemainingBytes`.
*   **Navigation:** `skip(n)`, `seek(p)`, `rewind(n)`, `peekBytes(n)`, `[index]`.

## 🧪 Testing & Performance

We maintain a rigorous test suite:
*   ✅ **Native (JIT/AOT)**: Optimized for raw performance.
*   ✅ **Web (WASM/JS)**: Cross-platform consistency.

Run benchmarks to see it in action:
```bash
dart run benchmark_harness:bench --flavor aot --target test/performance/serialization_bench.dart
```

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.
