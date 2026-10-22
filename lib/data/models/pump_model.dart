import 'package:station_service_app/domain/entities/pump.dart';

class PumpModel extends Pump {
  PumpModel({
    required super.id,
    required super.name,
    required super.fuelId,
    required super.status,
    required super.meterReading,
    required super.fuelName,
  });

  factory PumpModel.fromMap(Map<String, Object?> map) {
    return PumpModel(
      id: map['id'] as int,
      name: map['name'] as String,
      fuelId: map['fuelId'] as int,
      status: map['status'] as String,
      meterReading: (map['meterReading'] as num).toDouble(),
      fuelName: map['fuelName'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'fuelId': fuelId,
      'status': status,
      'meterReading': meterReading,
    };
  }
}
