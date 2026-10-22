import 'package:get/get.dart';
import 'package:station_service_app/core/database/database_helper.dart';
import 'package:station_service_app/data/models/report_summary_model.dart';

class ReportController extends GetxController {
  final dailyReport = Rxn<ReportSummaryModel>();
  final monthlyReport = Rxn<ReportSummaryModel>();
  final annualReport = Rxn<ReportSummaryModel>();
  final dailyItemBreakdown = <Map<String, Object>>[].obs;
  final _isLoading = false.obs;

  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    refreshReports();
  }

  Future<void> refreshReports() async {
    _isLoading.value = true;
    final db = await DatabaseHelper.instance.database;
    final daily = await db.rawQuery('''
      SELECT
        (SELECT COUNT(*) FROM sales WHERE date LIKE date('now') || '%') as fuelSales,
        (SELECT COALESCE(SUM(amount), 0) FROM sales WHERE date LIKE date('now') || '%') as fuelRevenue,
        (SELECT COUNT(*) FROM product_sales WHERE date LIKE date('now') || '%') as productSales,
        (SELECT COALESCE(SUM(amount), 0) FROM product_sales WHERE date LIKE date('now') || '%') as productRevenue
    ''');
    final monthly = await db.rawQuery('''
      SELECT
        (SELECT COUNT(*) FROM sales WHERE strftime('%Y-%m', date) = strftime('%Y-%m', 'now')) as fuelSales,
        (SELECT COALESCE(SUM(amount), 0) FROM sales WHERE strftime('%Y-%m', date) = strftime('%Y-%m', 'now')) as fuelRevenue,
        (SELECT COUNT(*) FROM product_sales WHERE strftime('%Y-%m', date) = strftime('%Y-%m', 'now')) as productSales,
        (SELECT COALESCE(SUM(amount), 0) FROM product_sales WHERE strftime('%Y-%m', date) = strftime('%Y-%m', 'now')) as productRevenue
    ''');
    final annual = await db.rawQuery('''
      SELECT
        (SELECT COUNT(*) FROM sales WHERE strftime('%Y', date) = strftime('%Y', 'now')) as fuelSales,
        (SELECT COALESCE(SUM(amount), 0) FROM sales WHERE strftime('%Y', date) = strftime('%Y', 'now')) as fuelRevenue,
        (SELECT COUNT(*) FROM product_sales WHERE strftime('%Y', date) = strftime('%Y', 'now')) as productSales,
        (SELECT COALESCE(SUM(amount), 0) FROM product_sales WHERE strftime('%Y', date) = strftime('%Y', 'now')) as productRevenue
    ''');

    dailyReport.value = ReportSummaryModel.fromMap(daily.first);
    monthlyReport.value = ReportSummaryModel.fromMap(monthly.first);
    annualReport.value = ReportSummaryModel.fromMap(annual.first);
    final dailyItems = await db.rawQuery('''
      SELECT label, SUM(amount) as totalAmount FROM (
        SELECT f.name as label, s.amount as amount
        FROM sales s
        JOIN fuels f ON f.id = s.fuelId
        WHERE s.date LIKE date('now') || '%'
        UNION ALL
        SELECT sp.name as label, ps.amount as amount
        FROM product_sales ps
        JOIN sales_products sp ON sp.id = ps.productId
        WHERE ps.date LIKE date('now') || '%'
      )
      GROUP BY label
      ORDER BY totalAmount DESC
    ''');
    dailyItemBreakdown.value = dailyItems
        .map(
          (e) => {
            'label': '${e['label'] ?? '-'}',
            'amount': (e['totalAmount'] as num?)?.toDouble() ?? 0.0,
          },
        )
        .toList();
    _isLoading.value = false;
  }
}
