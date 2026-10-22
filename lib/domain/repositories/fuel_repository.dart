import 'package:station_service_app/domain/entities/fuel.dart';

abstract class FuelRepository {
  Future<List<Fuel>> getFuels();
  Future<void> updateFuel(Fuel fuel);
}
