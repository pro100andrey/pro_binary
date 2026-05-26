import 'dart:async';

import 'stream_binary_reader.dart';

/// A [StreamTransformer] that simplifies parsing binary messages from a stream.
///
/// It manages an internal [StreamBinaryReader] and handles
/// [NotEnoughDataException]  by automatically rolling back the reader state
/// and waiting for more data
/// from the stream.
///
/// To use it, extend this class and implement the [parse] method.
///
/// Example:
/// ```dart
/// class MyMessageTransformer extends BinaryStreamTransformer<MyMessage> {
///   @override
///   MyMessage? parse(StreamBinaryReader reader) {
///     final id = reader.readUint32();
///     final name = reader.readVarString();
///     return MyMessage(id, name);
///   }
/// }
///
/// // Usage:
/// stream.transform(MyMessageTransformer()).listen((msg) => print(msg.name));
/// ```
abstract class BinaryStreamTransformer<T>
    extends StreamTransformerBase<List<int>, T> {
  /// Creates a new [BinaryStreamTransformer].
  const BinaryStreamTransformer();

  @override
  Stream<T> bind(Stream<List<int>> stream) async* {
    final reader = StreamBinaryReader();

    await for (final chunk in stream) {
      reader.addChunk(chunk);
      yield* _parseLoop(reader);
    }

    // Final attempt to parse remaining data after stream is closed
    yield* _parseLoop(reader);
  }

  Stream<T> _parseLoop(StreamBinaryReader reader) async* {
    while (reader.availableBytes > 0) {
      reader.bookmark();
      final bytesBefore = reader.availableBytes;
      try {
        final result = parse(reader);
        if (result == null) {
          reader.rollback();
          break; // Wait for more data
        } else {
          reader.commit();
          if (reader.availableBytes == bytesBefore) {
            // parse() returned a result without consuming any data —
            // break to avoid an infinite loop
            break;
          }
          yield result;
        }
      } on NotEnoughDataException {
        reader.rollback();
        break; // Wait for more data
      } catch (e) {
        reader.rollback();
        rethrow;
      }
    }
  }

  /// Parses a single message from the [reader].
  ///
  /// Return the parsed object, or `null` if there is not enough data.
  /// Alternatively, throw [NotEnoughDataException] explicitly.
  /// Both approaches trigger automatic rollback and wait for more data.
  ///
  /// **Recommendation:** prefer throwing [NotEnoughDataException] for
  /// explicit control, or return `null` for simple "not yet ready" cases.
  T? parse(StreamBinaryReader reader);
}
