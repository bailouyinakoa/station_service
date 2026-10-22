import 'package:get/get.dart';
import 'package:station_service_app/core/database/database_helper.dart';
import 'package:station_service_app/data/models/sales_product_model.dart';
import 'package:station_service_app/presentation/controllers/auth_controller.dart';
import 'package:station_service_app/services/alert_monitoring_service.dart';

class SalesProductController extends GetxController {
  final products = <SalesProductModel>[].obs;
  final _isLoading = false.obs;

  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    _isLoading.value = true;
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('sales_products', orderBy: 'name ASC');
    products.value = rows.map((row) => SalesProductModel.fromMap(row)).toList();
    _isLoading.value = false;
  }

  Future<void> addProduct(SalesProductModel product) async {
    if (!Get.find<AuthController>().requireAdmin(
      message: 'Seul l\'administrateur peut ajouter un produit.',
    )) {
      return;
    }
    final db = await DatabaseHelper.instance.database;
    await db.insert('sales_products', {
      'name': product.name,
      'category': product.category,
      'unitPrice': product.unitPrice,
      'stockQuantity': product.stockQuantity,
      'lowStockThreshold': product.lowStockThreshold,
    });
    await fetchProducts();
    await AlertMonitoringService.instance.runAlertChecks();
  }

  Future<void> deleteProduct(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('sales_products', where: 'id = ?', whereArgs: [id]);
    await fetchProducts();
    await AlertMonitoringService.instance.runAlertChecks();
  }
}
