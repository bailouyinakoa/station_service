import 'package:get/get.dart';
import 'package:station_service_app/core/database/database_helper.dart';
import 'package:station_service_app/data/models/fuel_model.dart';
import 'package:station_service_app/data/models/sales_product_model.dart';
import 'package:station_service_app/data/models/stock_movement_model.dart';
import 'package:station_service_app/presentation/controllers/auth_controller.dart';
import 'package:station_service_app/presentation/controllers/stock_controller.dart';

class RefuelingController extends GetxController {
  final fuels = <FuelModel>[].obs;
  final products = <SalesProductModel>[].obs;
  final _isLoading = false.obs;
  final _isSaving = false.obs;

  bool get isLoading => _isLoading.value;
  bool get isSaving => _isSaving.value;

  @override
  void onInit() {
    super.onInit();
    _loadRefuelingData();
  }

  Future<void> _loadRefuelingData() async {
    _isLoading.value = true;
    try {
      await Future.wait([_loadFuels(), _loadProducts()]);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _loadFuels() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('fuels', orderBy: 'id ASC');
    fuels.value = rows.map((row) => FuelModel.fromMap(row)).toList();
  }

  Future<void> _loadProducts() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('sales_products', orderBy: 'id ASC');
    products.value = rows.map((row) => SalesProductModel.fromMap(row)).toList();
  }

  Future<bool> refuelFuel({
    required int fuelId,
    required double liters,
    required String supplier,
    String? note,
  }) async {
    if (!Get.find<AuthController>().requireAdmin(
      message: 'Seul l\'administrateur peut ravitailler le carburant.',
    )) {
      return false;
    }
    _isSaving.value = true;
    try {
      final db = await DatabaseHelper.instance.database;

      // Get fuel name
      final fuelRows = await db.query(
        'fuels',
        where: 'id = ?',
        whereArgs: [fuelId],
      );
      if (fuelRows.isEmpty) {
        throw Exception('Carburant non trouvé');
      }
      final fuelName = fuelRows.first['name'] as String;

      // Create stock movement entry
      final movement = StockMovementModel(
        id: 0,
        fuelId: fuelId,
        type: 'entry',
        liters: liters,
        date: DateTime.now().toString(),
        note: note ?? 'Ravitaillement - $supplier',
        fuelName: fuelName,
      );

      // Insert movement
      await db.insert('stock_movements', movement.toMapForInsert());

      // Update fuel stock
      await db.rawUpdate(
        '''
        UPDATE fuels SET stockLiters = stockLiters + ? WHERE id = ?
      ''',
        [liters, fuelId],
      );

      // Reload data and notify
      await _loadFuels();
      if (Get.isRegistered<StockController>()) {
        await Get.find<StockController>().fetchMovements();
      }

      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de ravitailler le carburant: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      _isSaving.value = false;
    }
  }

  Future<bool> refuelProduct({
    required int productId,
    required double quantity,
    required String supplier,
    String? note,
  }) async {
    if (!Get.find<AuthController>().requireAdmin(
      message: 'Seul l\'administrateur peut ravitailler les produits.',
    )) {
      return false;
    }
    _isSaving.value = true;
    try {
      final db = await DatabaseHelper.instance.database;

      // Update product stock
      await db.rawUpdate(
        '''
        UPDATE sales_products SET stockQuantity = stockQuantity + ? WHERE id = ?
      ''',
        [quantity, productId],
      );

      // Log this as activity
      await db.insert('activity_logs', {
        'tableName': 'sales_products',
        'operation': 'UPDATE',
        'description':
            'Ravitaillement produit - $supplier - ${quantity.toString()} unités',
        'occurredAt': DateTime.now().toString(),
      });

      // Reload data
      await _loadProducts();

      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de ravitailler le produit: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      _isSaving.value = false;
    }
  }

  Future<void> refreshData() async {
    await _loadRefuelingData();
  }
}
