import 'package:station_service_app/domain/entities/pump.dart';

abstract class PumpRepository {
  Future<List<Pump>> getPumps();
  Future<void> updatePumpStatus(int pumpId, String status);
  Future<void> updateMeter(int pumpId, double meterReading);
}
