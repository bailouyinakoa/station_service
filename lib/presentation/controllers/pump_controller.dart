import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:station_service_app/core/database/database_helper.dart';
import 'package:station_service_app/data/models/nozzle_model.dart';
import 'package:station_service_app/data/models/pump_model.dart';
import 'package:station_service_app/presentation/controllers/auth_controller.dart';

class PumpController extends GetxController {
  final pumps = <PumpModel>[].obs;
  final pumpNozzles = <int, List<NozzleModel>>{}.obs;
  final _isLoading = false.obs;

  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    fetchPumps();
  }

  Future<void> fetchPumps() async {
    _isLoading.value = true;
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT p.*, f.name as fuelName
      FROM pumps p
      JOIN fuels f ON f.id = p.fuelId
    ''');
    pumps.value = rows.map((row) => PumpModel.fromMap(row)).toList();
    await _fetchNozzles(db);
    _isLoading.value = false;
  }

  Future<void> _fetchNozzles(Database db) async {
    final rows = await db.query('pump_nozzles');
    final nozzles = rows.map((row) => NozzleModel.fromMap(row)).toList();
    final grouped = <int, List<NozzleModel>>{};
    for (final nozzle in nozzles) {
      grouped.putIfAbsent(nozzle.pumpId, () => []).add(nozzle);
    }
    pumpNozzles.assignAll(grouped);
  }

  Future<void> togglePumpStatus(PumpModel pump) async {
    final status = pump.status == 'active' ? 'inactive' : 'active';
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'pumps',
      {'status': status},
      where: 'id = ?',
      whereArgs: [pump.id],
    );
    pump.status = status;
    pumps.refresh();
  }

  Future<void> toggleNozzleStatus(NozzleModel nozzle) async {
    final status = nozzle.status == 'active' ? 'inactive' : 'active';
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'pump_nozzles',
      {'status': status},
      where: 'id = ?',
      whereArgs: [nozzle.id],
    );
    nozzle.status = status;
    pumpNozzles.refresh();
  }

  Future<void> addPump(PumpModel pump) async {
    if (!Get.find<AuthController>().requireAdmin(
      message: 'Seul l\'administrateur peut ajouter une pompe.',
    )) {
      return;
    }
    final db = await DatabaseHelper.instance.database;
    final pumpId = await db.insert('pumps', {
      'name': pump.name,
      'fuelId': pump.fuelId,
      'status': pump.status,
      'meterReading': pump.meterReading,
    });
    await _createDefaultNozzles(db, pumpId);
    await fetchPumps();
  }

  Future<void> deletePump(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('pump_nozzles', where: 'pumpId = ?', whereArgs: [id]);
    await db.delete('pumps', where: 'id = ?', whereArgs: [id]);
    await fetchPumps();
  }

  Future<void> saveMeter(int pumpId, double meterReading) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'pumps',
      {'meterReading': meterReading},
      where: 'id = ?',
      whereArgs: [pumpId],
    );
    final index = pumps.indexWhere((pump) => pump.id == pumpId);
    if (index != -1) {
      pumps[index].meterReading = meterReading;
      pumps.refresh();
    }
  }

  Future<void> _createDefaultNozzles(Database db, int pumpId) async {
    await db.insert('pump_nozzles', {
      'pumpId': pumpId,
      'name': 'Pistolet 1',
      'status': 'active',
    });
    await db.insert('pump_nozzles', {
      'pumpId': pumpId,
      'name': 'Pistolet 2',
      'status': 'active',
    });
  }
}
