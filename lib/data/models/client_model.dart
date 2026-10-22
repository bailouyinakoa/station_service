import 'package:station_service_app/domain/entities/client.dart';

class ClientModel extends Client {
  ClientModel({
    required super.id,
    required super.name,
    super.cardNumber,
    required super.balance,
    required super.credit,
  });

  factory ClientModel.fromMap(Map<String, Object?> map) {
    return ClientModel(
      id: map['id'] as int,
      name: map['name'] as String,
      cardNumber: map['cardNumber'] as String?,
      balance: (map['balance'] as num).toDouble(),
      credit: (map['credit'] as num).toDouble(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'cardNumber': cardNumber,
      'balance': balance,
      'credit': credit,
    };
  }
}
