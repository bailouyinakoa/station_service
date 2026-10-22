import 'package:station_service_app/domain/entities/sales_product.dart';

class SalesProductModel extends SalesProduct {
  SalesProductModel({
    required super.id,
    required super.name,
    required super.category,
    required super.unitPrice,
    required super.stockQuantity,
    required super.lowStockThreshold,
  });

  factory SalesProductModel.fromMap(Map<String, Object?> map) {
    return SalesProductModel(
      id: map['id'] as int,
      name: map['name'] as String,
      category: map['category'] as String,
      unitPrice: (map['unitPrice'] as num).toDouble(),
      stockQuantity: (map['stockQuantity'] as num).toDouble(),
      lowStockThreshold: (map['lowStockThreshold'] as num?)?.toDouble() ?? 5,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'unitPrice': unitPrice,
      'stockQuantity': stockQuantity,
      'lowStockThreshold': lowStockThreshold,
    };
  }
}
