import 'dart:async';

import 'stream_binary_reader.dart';
import 'transactional_reader.dart';
import 'transactional_stream_transformer.dart';

/// A [StreamTransformer] that simplifies parsing binary messages from a stream.
///
/// It manages an internal [StreamBinaryReader] and handles
/// [NotEnoughDataException] by automatically rolling back the reader state
/// and waiting for more data
/// from the stream.
///
/// To use it, extend this class and implement the [parse] method.
/// Return the parsed object, or `null` if there is not enough data yet.
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
    extends TransactionalStreamTransformer<T, List<int>, StreamBinaryReader> {
  /// Creates a new [BinaryStreamTransformer].
  const BinaryStreamTransformer();

  @override
  StreamBinaryReader createReader() => StreamBinaryReader();

  /// Parses a single message from the [reader].
  ///
  /// Return the parsed object, or `null` if there is not enough data.
  /// Alternatively, throw [NotEnoughDataException] explicitly.
  /// Both approaches trigger automatic rollback and wait for more data.
  ///
  /// **Recommendation:** prefer throwing [NotEnoughDataException] for
  /// explicit control, or return `null` for simple "not yet ready" cases.
  @override
  T? parse(StreamBinaryReader reader);
}
