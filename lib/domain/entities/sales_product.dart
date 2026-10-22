class SalesProduct {
  final int id;
  final String name;
  final String category;
  final double unitPrice;
  final double stockQuantity;
  final double lowStockThreshold;

  SalesProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.unitPrice,
    required this.stockQuantity,
    required this.lowStockThreshold,
  });
}
