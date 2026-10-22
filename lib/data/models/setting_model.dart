import 'package:station_service_app/domain/entities/setting.dart';

class SettingModel extends Setting {
  SettingModel({
    super.id,
    required super.stationName,
    required super.stationAddress,
    required super.phone,
    required super.backupPath,
    super.adminEmail = '',
  });

  factory SettingModel.fromMap(Map<String, Object?> map) {
    return SettingModel(
      id: map['id'] as int?,
      stationName: map['stationName'] as String? ?? '',
      stationAddress: map['stationAddress'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      backupPath: map['backupPath'] as String? ?? '',
      adminEmail: map['adminEmail'] as String? ?? '',
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'stationName': stationName,
      'stationAddress': stationAddress,
      'phone': phone,
      'backupPath': backupPath,
      'adminEmail': adminEmail,
    };
  }
}
