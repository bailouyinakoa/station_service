class ProductSaleModel {
  final int id;
  final int productId;
  final String productName;
  final double quantity;
  final double amount;
  final String date;
  final int? sessionId;

  ProductSaleModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.amount,
    required this.date,
    this.sessionId,
  });

  factory ProductSaleModel.fromMap(Map<String, Object?> map) {
    return ProductSaleModel(
      id: map['id'] as int,
      productId: map['productId'] as int,
      productName: (map['productName'] as String?) ?? 'Produit',
      quantity: (map['quantity'] as num).toDouble(),
      amount: (map['amount'] as num).toDouble(),
      date: map['date'] as String,
      sessionId: map['sessionId'] as int?,
    );
  }
}
