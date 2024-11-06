import 'dart:convert';
import 'dart:typed_data';

import 'binary_writer_interface.dart';

const int _kInitialSize = 64;
const int _kRegularSize = 1024;

/// The [BinaryWriter] class is an implementation of the [BinaryWriterInterface]
/// used to encode various types of data into a binary format.
class BinaryWriter extends BinaryWriterInterface {
  final _builder = BytesBuilder(copy: false);

  Uint8List? _buffer;
  ByteData? _data;
  int _offset = 0;

  @override
  int get bytesWritten => _builder.length + _offset;

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeUint8(int value) {
    _ensureSize(1);
    _data!.setUint8(_offset, value);
    _offset += 1;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeInt8(int value) {
    _ensureSize(1);
    _data!.setInt8(_offset, value);
    _offset += 1;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeUint16(int value, [Endian endian = Endian.big]) {
    _ensureSize(2);
    _data!.setUint16(_offset, value, endian);
    _offset += 2;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeInt16(int value, [Endian endian = Endian.big]) {
    _ensureSize(2);
    _data!.setInt16(_offset, value, endian);
    _offset += 2;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeUint32(int value, [Endian endian = Endian.big]) {
    _ensureSize(4);
    _data!.setUint32(_offset, value, endian);
    _offset += 4;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeInt32(int value, [Endian endian = Endian.big]) {
    _ensureSize(4);
    _data!.setInt32(_offset, value, endian);
    _offset += 4;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeUint64(int value, [Endian endian = Endian.big]) {
    _ensureSize(8);
    _data!.setUint64(_offset, value, endian);
    _offset += 8;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeInt64(int value, [Endian endian = Endian.big]) {
    _ensureSize(8);
    _data!.setInt64(_offset, value, endian);
    _offset += 8;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeFloat32(double value, [Endian endian = Endian.big]) {
    _ensureSize(4);
    _data!.setFloat32(_offset, value, endian);
    _offset += 4;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeFloat64(double value, [Endian endian = Endian.big]) {
    _ensureSize(8);
    _data!.setFloat64(_offset, value, endian);
    _offset += 8;
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeBytes(List<int> bytes) {
    final length = bytes.length;

    _ensureSize(length);

    if (_offset == 0) {
      // we can add it directly
      _builder.add(bytes);
    } else {
      // If the list is Uint8List, we can copy it directly
      if (bytes is Uint8List) {
        _buffer!.setRange(
          _offset,
          _offset + length,
          bytes,
        );
      } else {
        // Otherwise, copy it byte by byte
        for (var i = 0; i < length; i++) {
          _buffer![_offset + i] = bytes[i];
        }
      }
      _offset += length;
    }
  }

  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  @override
  void writeString(String value) {
    final encoded = utf8.encode(value);
    writeBytes(encoded);
  }

  @override
  Uint8List takeBytes() {
    if (_builder.isEmpty) {
      // Get the view of the current scratch buffer
      final result = Uint8List.view(
        _buffer!.buffer,
        _buffer!.offsetInBytes,
        _offset,
      );

      // Reset the internal state
      _offset = 0;
      _buffer = null;
      _data = null;

      return result;
    } else {
      _appendScratchBuffer();

      return _builder.takeBytes();
    }
  }

  /// Ensures that the buffer has enough space to accommodate the specified
  /// size. If the buffer is null, it initializes it with a small scratch
  /// buffer and expands it later if needed. If the remaining space in the
  /// buffer is less than the specified size, it appends a new scratch buffer.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void _ensureSize(int size) {
    if (_buffer == null) {
      // start with small scratch buffer, expand to regular later if needed
      _buffer = Uint8List(_kInitialSize);
      _data = ByteData.view(_buffer!.buffer, _buffer!.offsetInBytes);
    }

    final remaining = _buffer!.length - _offset;

    if (remaining < size) {
      _appendScratchBuffer();
    }
  }

  /// Appends the current buffer to the builder and resets the offset.
  /// If the builder is not empty, a new buffer is allocated.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  void _appendScratchBuffer() {
    if (_offset > 0) {
      // Add the current buffer to the builder
      _builder.add(
        Uint8List.view(_buffer!.buffer, _buffer!.offsetInBytes, _offset),
      );

      // Reset offset
      _offset = 0;

      // Allocate a new buffer only if the builder is not empty
      _buffer = _builder.isEmpty
          ? Uint8List(_kInitialSize)
          : Uint8List(_kRegularSize);

      // Create ByteData view for the new buffer
      _data = ByteData.view(_buffer!.buffer, _buffer!.offsetInBytes);
    }
  }
}
