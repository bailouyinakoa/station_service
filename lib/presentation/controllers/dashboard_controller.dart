import 'package:get/get.dart';
import 'package:station_service_app/core/database/database_helper.dart';

class DashboardController extends GetxController {
  final salesToday = 0.0.obs;
  final fuelStock = <String, double>{}.obs;
  final fuelThresholds = <String, double>{}.obs;
  final dailyRevenue = 0.0.obs;
  final monthlyRevenue = 0.0.obs;
  final dailyProductRevenue = 0.0.obs;
  final dailyProductCount = 0.obs;
  final recentProductSales = <Map<String, Object?>>[].obs;
  final totalStockValue = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    final db = await DatabaseHelper.instance.database;
    final sales = await db.rawQuery(
      "SELECT SUM(amount) as total FROM sales WHERE date LIKE date('now') || '%';",
    );
    dailyRevenue.value = (sales.first['total'] as num?)?.toDouble() ?? 0;

    final monthly = await db.rawQuery(
      "SELECT SUM(amount) as total FROM sales WHERE strftime('%Y-%m', date) = strftime('%Y-%m', 'now');",
    );
    monthlyRevenue.value = (monthly.first['total'] as num?)?.toDouble() ?? 0;

    final dailyProducts = await db.rawQuery(
      "SELECT COUNT(*) as totalCount, COALESCE(SUM(amount), 0) as totalAmount FROM product_sales WHERE date LIKE date('now') || '%';",
    );
    dailyProductCount.value = (dailyProducts.first['totalCount'] as num?)?.toInt() ?? 0;
    dailyProductRevenue.value = (dailyProducts.first['totalAmount'] as num?)?.toDouble() ?? 0;

    final productRows = await db.rawQuery('''
      SELECT ps.quantity, ps.amount, ps.date, sp.name as productName
      FROM product_sales ps
      JOIN sales_products sp ON sp.id = ps.productId
      ORDER BY ps.date DESC
      LIMIT 5
    ''');
    recentProductSales.value = productRows;

    final fuelRows = await db.query('fuels');
    fuelStock.clear();
    fuelThresholds.clear();
    for (final row in fuelRows) {
      fuelStock[row['name'] as String] = (row['stockLiters'] as num).toDouble();
      fuelThresholds[row['name'] as String] = (row['lowStockThreshold'] as num).toDouble();
    }

    await _calculateTotalStockValue();
  }

  Future<void> _calculateTotalStockValue() async {
    final db = await DatabaseHelper.instance.database;

    // Calculer la valeur totale des carburants
    final fuelValue = await db.rawQuery('''
      SELECT COALESCE(SUM(stockLiters * pricePerLiter), 0) as totalValue FROM fuels
    ''');
    final fuelTotalValue = (fuelValue.first['totalValue'] as num?)?.toDouble() ?? 0;

    // Calculer la valeur totale des produits
    final productValue = await db.rawQuery('''
      SELECT COALESCE(SUM(stockQuantity * unitPrice), 0) as totalValue FROM sales_products
    ''');
    final productTotalValue = (productValue.first['totalValue'] as num?)?.toDouble() ?? 0;

    totalStockValue.value = fuelTotalValue + productTotalValue;
  }
}
