import 'package:station_service_app/domain/entities/fuel.dart';

class FuelModel extends Fuel {
  FuelModel({
    required super.id,
    required super.name,
    required super.supplier,
    required super.pricePerLiter,
    required super.stockLiters,
    required super.lowStockThreshold,
  });

  factory FuelModel.fromMap(Map<String, Object?> map) {
    return FuelModel(
      id: map['id'] as int,
      name: map['name'] as String,
      supplier: (map['supplier'] as String?) ?? 'N/A',
      pricePerLiter: (map['pricePerLiter'] as num).toDouble(),
      stockLiters: (map['stockLiters'] as num).toDouble(),
      lowStockThreshold: (map['lowStockThreshold'] as num).toDouble(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'supplier': supplier,
      'pricePerLiter': pricePerLiter,
      'stockLiters': stockLiters,
      'lowStockThreshold': lowStockThreshold,
    };
  }
}
