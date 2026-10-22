import 'package:station_service_app/domain/entities/sale.dart';

class SaleModel extends Sale {
  SaleModel({
    required super.id,
    required super.pumpId,
    required super.fuelId,
    super.nozzleId,
    required super.liters,
    required super.amount,
    required super.date,
    super.clientId,
    super.sessionId,
    super.pumpName,
    super.fuelName,
    super.nozzleName,
    super.clientName,
    super.sessionCode,
    super.sessionStatus,
  });

  factory SaleModel.fromMap(Map<String, Object?> map) {
    return SaleModel(
      id: map['id'] as int,
      pumpId: map['pumpId'] as int,
      fuelId: map['fuelId'] as int,
      nozzleId: map['nozzleId'] as int?,
      liters: (map['liters'] as num).toDouble(),
      amount: (map['amount'] as num).toDouble(),
      date: map['date'] as String,
      clientId: map['clientId'] as int?,
      sessionId: map['sessionId'] as int?,
      pumpName: map['pumpName'] as String?,
      fuelName: map['fuelName'] as String?,
      nozzleName: map['nozzleName'] as String?,
      clientName: map['clientName'] as String?,
      sessionCode: map['sessionCode'] as String?,
      sessionStatus: map['sessionStatus'] as String?,
    );
  }

  @override
  Map<String, Object?> toMap() {
    final map = <String, Object?>{
      'pumpId': pumpId,
      'fuelId': fuelId,
      'liters': liters,
      'amount': amount,
      'date': date,
    };
    if (nozzleId != null) {
      map['nozzleId'] = nozzleId;
    }
    if (clientId != null) {
      map['clientId'] = clientId;
    }
    if (sessionId != null) {
      map['sessionId'] = sessionId;
    }
    if (id != 0) {
      map['id'] = id;
    }
    return map;
  }
}
