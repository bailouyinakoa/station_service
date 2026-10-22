import 'package:station_service_app/domain/entities/pompiste.dart';

class PompisteModel extends Pompiste {
  PompisteModel({
    required super.id,
    required super.name,
    super.phone,
    super.address,
    required super.hireDate,
    required super.status,
  });

  factory PompisteModel.fromMap(Map<String, Object?> map) {
    return PompisteModel(
      id: map['id'] as int,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      hireDate: map['hireDate'] as String,
      status: map['status'] as String,
    );
  }

  Map<String, Object?> toMap() {
    final map = <String, Object?>{
      'name': name,
      'hireDate': hireDate,
      'status': status,
    };
    if (phone != null) {
      map['phone'] = phone;
    }
    if (address != null) {
      map['address'] = address;
    }
    if (id != 0) {
      map['id'] = id;
    }
    return map;
  }
}