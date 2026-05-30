import 'dart:async';

import 'transactional_reader.dart';

/// A [StreamTransformer] that simplifies parsing messages from a stream
/// using a transactional reader.
///
/// It manages an internal [TransactionalReader] and handles
/// [NotEnoughDataException] by automatically rolling back the reader state
/// and waiting for more data from the stream.
abstract class TransactionalStreamTransformer<
  TMessage,
  TChunk,
  TReader extends TransactionalReader<TChunk>
>
    extends StreamTransformerBase<TChunk, TMessage> {
  /// Creates a new [TransactionalStreamTransformer].
  const TransactionalStreamTransformer();

  /// Creates the reader instance to be used for this stream.
  TReader createReader();

  @override
  Stream<TMessage> bind(Stream<TChunk> stream) async* {
    final reader = createReader();

    await for (final chunk in stream) {
      reader.addChunk(chunk);
      yield* _parseLoop(reader);
    }

    // Final attempt to parse remaining data after stream is closed
    yield* _parseLoop(reader);
  }

  Stream<TMessage> _parseLoop(TReader reader) async* {
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
          yield result;
          if (reader.availableBytes == bytesBefore) {
            // parse() returned a result without consuming any data —
            // break to avoid an infinite loop
            break;
          }
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
  TMessage? parse(TReader reader);
}
