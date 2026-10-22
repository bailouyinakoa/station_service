import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:station_service_app/core/database/database_helper.dart';
import 'package:station_service_app/data/models/product_sale_model.dart';
import 'package:station_service_app/data/models/sale_model.dart';
import 'package:station_service_app/presentation/controllers/dashboard_controller.dart';
import 'package:station_service_app/presentation/controllers/report_controller.dart';
import 'package:station_service_app/services/alert_monitoring_service.dart';

class SaleController extends GetxController {
  final sales = <SaleModel>[].obs;
  final productSales = <ProductSaleModel>[].obs;
  final activeSession = Rxn<Map<String, Object?>>();
  final closedSessions = <Map<String, Object?>>[].obs;
  final _isLoading = false.obs;

  bool get isLoading => _isLoading.value;

  Future<Database> get database => DatabaseHelper.instance.database;

  @override
  void onInit() {
    super.onInit();
    fetchSales();
  }

  Future<void> fetchSales() async {
    _isLoading.value = true;
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT s.*, p.name as pumpName, f.name as fuelName, c.name as clientName,
             ss.code as sessionCode, ss.status as sessionStatus
      FROM sales s
      JOIN pumps p ON p.id = s.pumpId
      JOIN fuels f ON f.id = s.fuelId
      LEFT JOIN clients c ON c.id = s.clientId
      LEFT JOIN sales_sessions ss ON ss.id = s.sessionId
      ORDER BY date DESC
    ''');
    sales.value = rows.map((row) => SaleModel.fromMap(row)).toList();
    final productRows = await db.rawQuery('''
      SELECT ps.*, sp.name as productName
      FROM product_sales ps
      JOIN sales_products sp ON sp.id = ps.productId
      ORDER BY ps.date DESC
    ''');
    productSales.value = productRows
        .map((row) => ProductSaleModel.fromMap(row))
        .toList();
    await fetchActiveSession();
    await fetchClosedSessions();
    if (Get.isRegistered<DashboardController>()) {
      await Get.find<DashboardController>().loadDashboard();
    }
    if (Get.isRegistered<ReportController>()) {
      await Get.find<ReportController>().refreshReports();
    }
    _isLoading.value = false;
  }

  Future<void> fetchActiveSession() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT ss.*,
             GROUP_CONCAT(po.name, ', ') as pompistes
      FROM sales_sessions ss
      LEFT JOIN session_pompistes sp ON sp.sessionId = ss.id
      LEFT JOIN pompistes po ON po.id = sp.pompisteId
      WHERE ss.status = ?
      GROUP BY ss.id, ss.code, ss.openedAt, ss.closedAt, ss.status
      ORDER BY ss.openedAt DESC
      LIMIT 1
    ''',
      ['open'],
    );
    activeSession.value = rows.isEmpty ? null : rows.first;
  }

  bool get hasOpenSession => activeSession.value != null;

  Future<void> fetchClosedSessions() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT ss.id, ss.code, ss.openedAt, ss.closedAt, ss.status,
             COUNT(s.id) as totalSales,
             COALESCE(SUM(s.amount), 0) as totalAmount,
             COUNT(ps.id) as totalProductSales,
             COALESCE(SUM(ps.amount), 0) as totalProductAmount,
             GROUP_CONCAT(DISTINCT po.name) as pompistes
      FROM sales_sessions ss
      LEFT JOIN sales s ON s.sessionId = ss.id
      LEFT JOIN product_sales ps ON ps.sessionId = ss.id
      LEFT JOIN session_pompistes sp ON sp.sessionId = ss.id
      LEFT JOIN pompistes po ON po.id = sp.pompisteId
      WHERE ss.status = 'closed'
      GROUP BY ss.id, ss.code, ss.openedAt, ss.closedAt, ss.status
      ORDER BY ss.closedAt DESC
    ''');
    closedSessions.value = rows;
  }

  Future<void> openSession(List<int> pompisteIds) async {
    if (hasOpenSession) {
      throw Exception('Une session est deja ouverte');
    }
    if (pompisteIds.isEmpty) {
      throw Exception(
        'Selectionnez au moins un pompiste pour ouvrir la session.',
      );
    }
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final code =
        'SES-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    await db.transaction((txn) async {
      final sessionId = await txn.insert('sales_sessions', {
        'code': code,
        'openedAt': now.toIso8601String(),
        'status': 'open',
      });
      for (final pompisteId in pompisteIds) {
        await txn.insert('session_pompistes', {
          'sessionId': sessionId,
          'pompisteId': pompisteId,
        });
      }
    });
    await fetchSales();
    await AlertMonitoringService.instance.runAlertChecks();
  }

  Future<void> closeActiveSession() async {
    final session = activeSession.value;
    if (session == null) {
      throw Exception('Aucune session ouverte');
    }
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'sales_sessions',
      {'status': 'closed', 'closedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [session['id']],
    );
    await fetchSales();
  }

  Future<void> addSale(SaleModel sale) async {
    final db = await DatabaseHelper.instance.database;
    final session = activeSession.value;
    if (session == null || session['status'] != 'open') {
      throw Exception(
        'Session fermee. Ouvrez une session pour enregistrer des ventes.',
      );
    }

    // Vérifier le stock disponible
    final fuelRows = await db.query(
      'fuels',
      where: 'id = ?',
      whereArgs: [sale.fuelId],
    );
    if (fuelRows.isEmpty) {
      throw Exception('Carburant non trouvé');
    }
    final currentStock = (fuelRows.first['stockLiters'] as num).toDouble();
    if (currentStock < sale.liters) {
      throw Exception('Stock insuffisant. Stock disponible: ${currentStock}L');
    }

    try {
      final map = sale.toMap();
      map['sessionId'] = session['id'];
      final saleId = await db.insert('sales', map);
      print('Vente insérée avec ID: $saleId');

      print(
        'Mise à jour du stock: -${sale.liters}L pour fuelId=${sale.fuelId}',
      );
      final updateResult = await db.rawUpdate(
        'UPDATE fuels SET stockLiters = stockLiters - ? WHERE id = ?',
        [sale.liters, sale.fuelId],
      );
      print('Mise à jour affectée $updateResult lignes');
    } on DatabaseException catch (e) {
      print(
        'DatabaseException: ${e.toString()}, isUnique: ${e.isUniqueConstraintError()}, isSyntax: ${e.isSyntaxError()}, isReadOnly: ${e.isReadOnlyError()}',
      );
      if (e.isUniqueConstraintError()) {
        throw Exception(
          'Une contrainte d\'unicité a été violée. Vérifiez que la vente n\'existe pas déjà.',
        );
      } else {
        throw Exception('Erreur de base de données : ${e.toString()}');
      }
    } catch (e) {
      print('Autre exception: $e');
      throw Exception('Erreur inattendue: $e');
    }

    await fetchSales();
  }

  Future<void> addProductSale({
    required int productId,
    required double quantity,
    required double amount,
  }) async {
    final session = activeSession.value;
    if (session == null || session['status'] != 'open') {
      throw Exception(
        'Session fermee. Ouvrez une session pour enregistrer des ventes.',
      );
    }
    if (quantity <= 0 || amount <= 0) {
      throw Exception('Quantité et montant invalides.');
    }

    final db = await DatabaseHelper.instance.database;
    final productRows = await db.query(
      'sales_products',
      where: 'id = ?',
      whereArgs: [productId],
      limit: 1,
    );
    if (productRows.isEmpty) {
      throw Exception('Produit introuvable.');
    }
    final stock = (productRows.first['stockQuantity'] as num).toDouble();
    if (stock < quantity) {
      throw Exception(
        'Stock insuffisant. Quantité disponible: ${stock.toStringAsFixed(2)}',
      );
    }

    await db.transaction((txn) async {
      await txn.insert('product_sales', {
        'productId': productId,
        'quantity': quantity,
        'amount': amount,
        'date': DateTime.now().toIso8601String(),
        'sessionId': session['id'],
      });
      await txn.rawUpdate(
        'UPDATE sales_products SET stockQuantity = stockQuantity - ? WHERE id = ?',
        [quantity, productId],
      );
    });

    await fetchSales();
    await AlertMonitoringService.instance.runAlertChecks();
  }
}
