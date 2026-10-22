import 'package:station_service_app/domain/entities/stock_movement.dart';

class StockMovementModel extends StockMovement {
  StockMovementModel({
    required super.id,
    required super.fuelId,
    required super.type,
    required super.liters,
    required super.date,
    super.note,
    required super.fuelName,
  });

  factory StockMovementModel.fromMap(Map<String, Object?> map) {
    return StockMovementModel(
      id: map['id'] as int,
      fuelId: map['fuelId'] as int,
      type: map['type'] as String,
      liters: (map['liters'] as num).toDouble(),
      date: map['date'] as String,
      note: map['note'] as String?,
      fuelName: map['fuelName'] as String,
    );
  }

  @override
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'fuelId': fuelId,
      'type': type,
      'liters': liters,
      'date': date,
      'note': note,
    };
  }

  Map<String, Object?> toMapForInsert() {
    return {
      'fuelId': fuelId,
      'type': type,
      'liters': liters,
      'date': date,
      'note': note,
    };
  }
}
