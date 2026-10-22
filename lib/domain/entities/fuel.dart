class Fuel {
  final int id;
  final String name;
  final String supplier;
  final double pricePerLiter;
  final double stockLiters;
  final double lowStockThreshold;

  Fuel({
    required this.id,
    required this.name,
    required this.supplier,
    required this.pricePerLiter,
    required this.stockLiters,
    required this.lowStockThreshold,
  });
}
