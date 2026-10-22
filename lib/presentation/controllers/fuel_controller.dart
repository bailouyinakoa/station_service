import 'package:get/get.dart';
import 'package:station_service_app/core/database/database_helper.dart';
import 'package:station_service_app/data/models/fuel_model.dart';
import 'package:station_service_app/presentation/controllers/auth_controller.dart';
import 'package:station_service_app/services/alert_monitoring_service.dart';

class FuelController extends GetxController {
  final fuels = <FuelModel>[].obs;
  final _isLoading = false.obs;

  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    fetchFuels();
  }

  Future<void> fetchFuels() async {
    _isLoading.value = true;
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('fuels');
    fuels.value = rows.map((row) => FuelModel.fromMap(row)).toList();
    _isLoading.value = false;
  }

  Future<void> addFuel(FuelModel fuel) async {
    if (!Get.find<AuthController>().requireAdmin(
      message: 'Seul l\'administrateur peut ajouter un carburant.',
    )) {
      return;
    }
    final db = await DatabaseHelper.instance.database;
    await db.insert('fuels', {
      "name": fuel.name,
      "supplier": fuel.supplier,
      "pricePerLiter": fuel.pricePerLiter,
      "stockLiters": fuel.stockLiters,
      "lowStockThreshold": fuel.lowStockThreshold,
    });
    await fetchFuels();
    await AlertMonitoringService.instance.runAlertChecks();
  }

  Future<void> updateFuel(FuelModel fuel) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'fuels',
      fuel.toMap(),
      where: 'id = ?',
      whereArgs: [fuel.id],
    );
    final index = fuels.indexWhere((item) => item.id == fuel.id);
    if (index != -1) {
      fuels[index] = fuel;
      fuels.refresh();
    } else {
      await fetchFuels();
    }
    await AlertMonitoringService.instance.runAlertChecks();
  }

  Future<void> deleteFuel(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('fuels', where: 'id = ?', whereArgs: [id]);
    await fetchFuels();
    await AlertMonitoringService.instance.runAlertChecks();
  }
}
