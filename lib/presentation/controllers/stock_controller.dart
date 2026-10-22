import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:station_service_app/core/database/database_helper.dart';
import 'package:station_service_app/data/models/stock_movement_model.dart';
import 'package:station_service_app/services/alert_monitoring_service.dart';

class StockController extends GetxController {
  final movements = <StockMovementModel>[].obs;
  final _isLoading = false.obs;

  bool get isLoading => _isLoading.value;

  Future<Database> get database => DatabaseHelper.instance.database;

  @override
  void onInit() {
    super.onInit();
    fetchMovements();
  }

  Future<void> fetchMovements() async {
    _isLoading.value = true;
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT sm.*, f.name as fuelName
      FROM stock_movements sm
      JOIN fuels f ON f.id = sm.fuelId
      ORDER BY date DESC
    ''');
    movements.value = rows
        .map((row) => StockMovementModel.fromMap(row))
        .toList();
    _isLoading.value = false;
  }

  Future<void> addMovement(StockMovementModel movement) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('stock_movements', movement.toMapForInsert());
    final sign = movement.type == 'entry' ? 1 : -1;
    await db.rawUpdate(
      'UPDATE fuels SET stockLiters = stockLiters + ? * ? WHERE id = ?',
      [sign, movement.liters, movement.fuelId],
    );
    await fetchMovements();
    await AlertMonitoringService.instance.runAlertChecks();
  }
}
