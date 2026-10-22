class StockMovement {
  final int id;
  final int fuelId;
  final String type;
  final double liters;
  final String date;
  final String? note;
  final String fuelName;

  StockMovement({
    required this.id,
    required this.fuelId,
    required this.type,
    required this.liters,
    required this.date,
    this.note,
    required this.fuelName,
  });

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
}
