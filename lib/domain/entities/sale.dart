class Sale {
  final int id;
  final int pumpId;
  final int fuelId;
  final int? nozzleId;
  final double liters;
  final double amount;
  final String date;
  final int? clientId;
  final int? sessionId;
  final String? pumpName;
  final String? fuelName;
  final String? nozzleName;
  final String? clientName;
  final String? sessionCode;
  final String? sessionStatus;

  Sale({
    required this.id,
    required this.pumpId,
    required this.fuelId,
    this.nozzleId,
    required this.liters,
    required this.amount,
    required this.date,
    this.clientId,
    this.sessionId,
    this.pumpName,
    this.fuelName,
    this.nozzleName,
    this.clientName,
    this.sessionCode,
    this.sessionStatus,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'pumpId': pumpId,
      'fuelId': fuelId,
      'nozzleId': nozzleId,
      'liters': liters,
      'amount': amount,
      'date': date,
      'clientId': clientId,
      'sessionId': sessionId,
    };
  }
}
