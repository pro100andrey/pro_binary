import 'package:pro_binary/pro_binary.dart';
import 'models.dart';

/// A transformer that parses [TelemetryPacket]s from a raw byte stream.
///
/// It uses a "Length-Prefixed" protocol format:
/// [1 byte: Magic (0xAA)] [VarUint: Length of Payload] [Payload: Packet]
///
/// Thanks to [BinaryStreamTransformer] and its transactional model,
/// we don't need to manually buffer data or handle partial reads.
class TelemetryTransformer extends BinaryStreamTransformer<TelemetryPacket> {
  static const magicByte = 0xAA;

  @override
  TelemetryPacket? parse(StreamBinaryReader reader) {
    // 1. Sync check: Look for the magic byte
    // If not found, skip until we find it or run out of data.
    while (reader.availableBytes > 0) {
      if (reader.readUint8() == magicByte) {
        break;
      }
    }

    // If we finished the loop without finding magicByte, it means we don't
    // have enough data yet to even start a packet header.
    if (reader.availableBytes == 0) {
      return null;
    }

    // 2. Transactional block:
    // We use readVarBytes() which automatically:
    // - Reads the VarUint length
    // - Reads the payload bytes
    // - Throws NotEnoughDataException if any part is missing
    //
    // BinaryStreamTransformer will catch the exception and perform
    // an automatic rollback to the state BEFORE this parse() call.
    final payload = reader.readVarBytes();

    // 3. Success: All data is present.
    // Since we now have a contiguous Uint8List payload, we can use
    // the faster BinaryReader for the final decoding step.
    return TelemetryPacket.decode(BinaryReader(payload));
  }
}
