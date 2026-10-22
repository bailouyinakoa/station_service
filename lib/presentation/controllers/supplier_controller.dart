import 'package:get/get.dart';
import 'package:station_service_app/core/database/database_helper.dart';
import 'package:station_service_app/presentation/controllers/accounting_controller.dart';
import 'package:station_service_app/presentation/controllers/expense_controller.dart';

class SupplierController extends GetxController {
  final suppliers = <Map<String, Object?>>[].obs;
  final paymentTypes = <String>[].obs;
  final categories = <String>[].obs;
  final _isLoading = false.obs;

  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    fetchSuppliers();
  }

  Future<void> fetchSuppliers() async {
    _isLoading.value = true;
    final db = await DatabaseHelper.instance.database;
    suppliers.value = await db.query('suppliers', orderBy: 'name ASC');
    final paymentRows = await db.query(
      'choice_options',
      where: 'type = ?',
      whereArgs: ['payment_type'],
      orderBy: 'value ASC',
    );
    final categoryRows = await db.query(
      'choice_options',
      where: 'type = ?',
      whereArgs: ['supplier_category'],
      orderBy: 'value ASC',
    );
    paymentTypes.value = paymentRows.map((e) => '${e['value']}').toList();
    categories.value = categoryRows.map((e) => '${e['value']}').toList();
    _isLoading.value = false;
  }

  Future<void> addSupplier({
    required String name,
    required String category,
    required String paymentType,
    String? phone,
    required double unitPrice,
    required double quantity,
    required String unit,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final totalAmount = unitPrice * quantity;
    await db.insert('suppliers', {
      'name': name.trim(),
      'category': category.trim(),
      'phone': (phone?.trim().isEmpty ?? true) ? null : phone?.trim(),
      'paymentType': paymentType.trim(),
      'unitPrice': unitPrice,
      'quantity': quantity,
      'unit': unit,
      'totalAmount': totalAmount,
    });
    await db.insert('expenses', {
      'motif': 'Approvisionnement ${name.trim()} (${category.trim()})',
      'amount': totalAmount,
      'date': DateTime.now().toIso8601String(),
      'paymentType': paymentType.trim(),
      'supplierId': null,
    });
    await fetchSuppliers();
    if (Get.isRegistered<ExpenseController>()) {
      await Get.find<ExpenseController>().fetchData();
    }
    if (Get.isRegistered<AccountingController>()) {
      await Get.find<AccountingController>().refreshAccounting();
    }
  }
}
