# Examples Structure

This directory contains examples demonstrating how to use `pro_binary` effectively in various scenarios.

## 1. [Basic Serialization & Streaming](basic/)

A self-contained example showing the core API:

* **Simple Serialization**: How to encode and decode a class.
* **Pool API**: Using `BinaryWriterPool` for high-performance applications.
* **Basic Streaming**: Implementing a `BinaryStreamTransformer` to parse objects from fragmented byte streams.

## 2. [Advanced Network Streaming](network_streaming/)

A multi-file architectural example simulating a real-world IoT/Telemetry protocol:

* **Protocol Framing**: Searching for sync bytes (magic bytes).
* **Nested Models**: Encoding/decoding complex structures with lists.
* **Fragmentation Resilience**: Proving that the parser can reconstruct packets from tiny network chunks.

## 3. [File Streaming (Big Data)](file_streaming/)

A high-performance example demonstrating how to process large binary files:

* **Incremental Processing**: Using `File.openRead()` to process data without loading the entire file into RAM.
* **Market Data Simulation**: Parsing 250,000+ trade records (Market Ticks) on-the-fly.
* **Memory Efficiency**: Maintaining a constant memory footprint regardless of file size.

---

## How to Run

You can run any example directly using the Dart CLI:

```bash
# Run the basic overview
dart example/basic/main.dart

# Run the advanced telemetry simulation
dart example/network_streaming/main.dart

# Run the big data file streaming example
dart example/file_streaming/main.dart
```