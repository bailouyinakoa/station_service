import 'package:get/get.dart';
import 'package:station_service_app/core/database/database_helper.dart';

class AccountingController extends GetxController {
  final totalFuelSales = 0.0.obs;
  final totalProductSales = 0.0.obs;
  final totalExpenses = 0.0.obs;
  final totalProfit = 0.0.obs;
  final expensesRows = <Map<String, Object?>>[].obs;
  final salesTrend = <Map<String, Object>>[].obs;
  final expensesTrend = <Map<String, Object>>[].obs;
  final profitTrend = <Map<String, Object>>[].obs;
  final _isLoading = false.obs;

  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    refreshAccounting();
  }

  Future<void> refreshAccounting() async {
    _isLoading.value = true;
    final db = await DatabaseHelper.instance.database;
    final fuel = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM sales',
    );
    final products = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM product_sales',
    );
    final expenses = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM expenses',
    );
    totalFuelSales.value = (fuel.first['total'] as num?)?.toDouble() ?? 0;
    totalProductSales.value = (products.first['total'] as num?)?.toDouble() ?? 0;
    totalExpenses.value = (expenses.first['total'] as num?)?.toDouble() ?? 0;
    totalProfit.value =
        totalFuelSales.value + totalProductSales.value - totalExpenses.value;

    expensesRows.value = await db.rawQuery('''
      SELECT e.date, e.motif, e.amount, e.paymentType, s.name as supplierName
      FROM expenses e
      LEFT JOIN suppliers s ON s.id = e.supplierId
      ORDER BY e.date DESC
      LIMIT 30
    ''');

    final salesByDay = await db.rawQuery('''
      SELECT day, SUM(total) as total FROM (
        SELECT substr(date, 1, 10) as day, amount as total FROM sales
        UNION ALL
        SELECT substr(date, 1, 10) as day, amount as total FROM product_sales
      )
      GROUP BY day
      ORDER BY day ASC
    ''');
    final expensesByDay = await db.rawQuery('''
      SELECT substr(date, 1, 10) as day, SUM(amount) as total
      FROM expenses
      GROUP BY day
      ORDER BY day ASC
    ''');

    final salesMap = {
      for (final r in salesByDay) (r['day'] as String): (r['total'] as num).toDouble(),
    };
    final expenseMap = {
      for (final r in expensesByDay) (r['day'] as String): (r['total'] as num).toDouble(),
    };
    final days = <String>{...salesMap.keys, ...expenseMap.keys}.toList()..sort();
    salesTrend.value = days
        .map((day) => {'day': day, 'value': salesMap[day] ?? 0.0})
        .toList();
    expensesTrend.value = days
        .map((day) => {'day': day, 'value': expenseMap[day] ?? 0.0})
        .toList();
    profitTrend.value = days
        .map((day) => {
              'day': day,
              'value': (salesMap[day] ?? 0.0) - (expenseMap[day] ?? 0.0),
            })
        .toList();
    _isLoading.value = false;
  }
}
