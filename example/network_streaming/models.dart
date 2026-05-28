import 'package:pro_binary/pro_binary.dart';

/// Represents data from a single sensor.
class SensorData {
  SensorData({
    required this.id,
    required this.value,
    required this.timestamp,
  });

  /// Decodes [SensorData] from a [BinaryReader].
  factory SensorData.decode(BinaryReader r) => SensorData(
    id: r.readVarString(),
    value: r.readFloat64(),
    timestamp: r.readUint64(),
  );

  /// Decodes [SensorData] from a [StreamBinaryReader].
  factory SensorData.decodeStream(StreamBinaryReader r) => SensorData(
    id: r.readVarString(),
    value: r.readFloat64(),
    timestamp: r.readUint64(),
  );

  final String id;
  final double value;
  final int timestamp;

  /// Encodes [SensorData] using a standard [BinaryWriter].
  void encode(BinaryWriter w) {
    w
      ..writeVarString(id)
      ..writeFloat64(value)
      ..writeUint64(timestamp);
  }

  @override
  String toString() => 'Sensor(id: $id, val: ${value.toStringAsFixed(2)})';
}

/// A telemetry packet containing multiple sensor readings.
class TelemetryPacket {
  TelemetryPacket({required this.packetId, required this.readings});

  /// Decodes a full packet from a [BinaryReader].
  factory TelemetryPacket.decode(BinaryReader r) {
    final id = r.readUint32();
    final count = r.readVarUint();
    final readings = List.generate(count, (_) => SensorData.decode(r));

    return TelemetryPacket(packetId: id, readings: readings);
  }

  /// Decodes a full packet from a [StreamBinaryReader].
  factory TelemetryPacket.decodeStream(StreamBinaryReader r) {
    final id = r.readUint32();
    final count = r.readVarUint();
    final readings = List.generate(count, (_) => SensorData.decodeStream(r));

    return TelemetryPacket(packetId: id, readings: readings);
  }

  final int packetId;
  final List<SensorData> readings;

  /// Encodes the packet.
  void encode(BinaryWriter w) {
    w
      ..writeUint32(packetId)
      ..writeVarUint(readings.length);

    for (final reading in readings) {
      reading.encode(w);
    }
  }

  @override
  String toString() => 'Packet #$packetId [${readings.length} readings]';
}
