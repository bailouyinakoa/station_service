import 'package:station_service_app/domain/entities/setting.dart';

abstract class SettingRepository {
  Future<Setting?> getSettings();
  Future<void> saveSettings(Setting setting);
}
