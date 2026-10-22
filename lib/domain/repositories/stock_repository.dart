import 'package:station_service_app/domain/entities/stock_movement.dart';

abstract class StockRepository {
  Future<List<StockMovement>> getStockMovements();
  Future<void> addStockMovement(StockMovement movement);
}
