import 'package:get/get.dart';
import 'package:station_service_app/core/database/database_helper.dart';
import 'package:station_service_app/presentation/controllers/accounting_controller.dart';

class ExpenseController extends GetxController {
  final expenses = <Map<String, Object?>>[].obs;
  final paymentTypes = <String>[].obs;
  final _isLoading = false.obs;

  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  Future<void> fetchData() async {
    _isLoading.value = true;
    final db = await DatabaseHelper.instance.database;
    final paymentRows = await db.query(
      'choice_options',
      where: 'type = ?',
      whereArgs: ['payment_type'],
      orderBy: 'value ASC',
    );
    paymentTypes.value = paymentRows.map((e) => '${e['value']}').toList();
    expenses.value = await db.rawQuery('''
      SELECT e.*, s.name as supplierName
      FROM expenses e
      LEFT JOIN suppliers s ON s.id = e.supplierId
      ORDER BY e.date DESC
    ''');
    _isLoading.value = false;
  }

  Future<void> addExpense({
    required String motif,
    required double amount,
    required String paymentType,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('expenses', {
      'motif': motif.trim(),
      'amount': amount,
      'date': DateTime.now().toIso8601String(),
      'paymentType': paymentType.trim(),
      'supplierId': null,
    });
    await fetchData();
    if (Get.isRegistered<AccountingController>()) {
      await Get.find<AccountingController>().refreshAccounting();
    }
  }
}
