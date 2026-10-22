import 'package:station_service_app/domain/entities/nozzle.dart';

class NozzleModel extends Nozzle {
  NozzleModel({
    required super.id,
    required super.pumpId,
    required super.name,
    required super.status,
  });

  factory NozzleModel.fromMap(Map<String, Object?> map) {
    return NozzleModel(
      id: map['id'] as int,
      pumpId: map['pumpId'] as int,
      name: map['name'] as String,
      status: map['status'] as String,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'pumpId': pumpId,
      'name': name,
      'status': status,
    };
  }
}
