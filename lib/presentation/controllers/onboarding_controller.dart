import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:station_service_app/core/database/database_helper.dart';
import 'package:station_service_app/core/routes/app_routes.dart';
import 'package:station_service_app/data/models/fuel_model.dart';
import 'package:station_service_app/data/models/pump_model.dart';
import 'package:station_service_app/data/models/sales_product_model.dart';
import 'package:station_service_app/services/alert_monitoring_service.dart';
import 'package:station_service_app/presentation/controllers/dashboard_controller.dart';
import 'package:station_service_app/presentation/controllers/fuel_controller.dart';
import 'package:station_service_app/presentation/controllers/pump_controller.dart';
import 'package:station_service_app/presentation/controllers/sale_controller.dart';
import 'package:station_service_app/presentation/controllers/client_controller.dart';
import 'package:station_service_app/presentation/controllers/stock_controller.dart';
import 'package:station_service_app/presentation/controllers/sales_product_controller.dart';
import 'package:station_service_app/presentation/controllers/settings_controller.dart';
import 'dart:io';

class OnboardingController extends GetxController {
  static const String _onboardingCompleteKey = 'onboarding_complete';

  final currentStep = 0.obs;
  final _isLoading = false.obs;

  bool get isLoading => _isLoading.value;

  // Data for onboarding

  final RxList<FuelModel> addedFuels = <FuelModel>[].obs;
  final RxList<PumpModel> addedPumps = <PumpModel>[].obs;
  final RxList<SalesProductModel> addedProducts = <SalesProductModel>[].obs;

  // Station info form data
  final stationName = ''.obs;
  final stationAddress = ''.obs;
  final stationPhone = ''.obs;
  final logoPath = Rxn<String>();

  // Fuel form data
  final fuelName = ''.obs;
  final fuelSupplier = ''.obs;
  final fuelPrice = 0.0.obs;
  final fuelStock = 0.0.obs;
  final fuelLowStockThreshold = 0.0.obs;

  // Pump form data
  final pumpName = ''.obs;
  final selectedFuelId = Rxn<int>();

  // Product form data
  final productName = ''.obs;
  final productCategory = ''.obs;
  final productPrice = 0.0.obs;
  final productStock = 0.0.obs;

  // Check if this is first launch
  Future<bool> isFirstLaunch() async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Check if there are fuels, pumps, or products in the database
      final fuelCount = await db.rawQuery(
        'SELECT COUNT(*) as count FROM fuels',
      );
      final pumpCount = await db.rawQuery(
        'SELECT COUNT(*) as count FROM pumps',
      );
      final productCount = await db.rawQuery(
        'SELECT COUNT(*) as count FROM sales_products',
      );

      final fuelsExist = ((fuelCount.first['count'] as int?) ?? 0) > 0;
      final pumpsExist = ((pumpCount.first['count'] as int?) ?? 0) > 0;
      final productsExist = ((productCount.first['count'] as int?) ?? 0) > 0;

      // First launch is when no data exists
      return !fuelsExist && !pumpsExist && !productsExist;
    } catch (e) {
      return false;
    }
  }

  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  Future<void> markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompleteKey, true);
  }

  // Add fuel and create pumps automatically
  Future<void> addFuel(FuelModel fuel) async {
    try {
      _isLoading.value = true;
      final db = await DatabaseHelper.instance.database;

      final id = await db.insert('fuels', {
        'name': fuel.name,
        'supplier': fuel.supplier,
        'pricePerLiter': fuel.pricePerLiter,
        'stockLiters': fuel.stockLiters,
        'lowStockThreshold': fuel.lowStockThreshold,
      });

      addedFuels.add(
        FuelModel(
          id: id,
          name: fuel.name,
          supplier: fuel.supplier,
          pricePerLiter: fuel.pricePerLiter,
          stockLiters: fuel.stockLiters,
          lowStockThreshold: fuel.lowStockThreshold,
        ),
      );

      _isLoading.value = false;
    } catch (e) {
      _isLoading.value = false;
      rethrow;
    }
  }

  // Add pump with default nozzles
  Future<void> addPump(PumpModel pump) async {
    try {
      _isLoading.value = true;
      final db = await DatabaseHelper.instance.database;

      final pumpId = await db.insert('pumps', {
        'name': pump.name,
        'fuelId': pump.fuelId,
        'status': 'active',
        'meterReading': 0,
      });

      // Create default nozzles (pistolets)
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

      // Get fuel name for the model
      final fuelName =
          addedFuels.firstWhereOrNull((f) => f.id == pump.fuelId)?.name ??
          'N/A';

      addedPumps.add(
        PumpModel(
          id: pumpId,
          name: pump.name,
          fuelId: pump.fuelId,
          status: 'active',
          meterReading: 0,
          fuelName: fuelName,
        ),
      );

      _isLoading.value = false;
    } catch (e) {
      _isLoading.value = false;
      rethrow;
    }
  }

  // Add product
  Future<void> addProduct(SalesProductModel product) async {
    try {
      _isLoading.value = true;
      final db = await DatabaseHelper.instance.database;

      final id = await db.insert('sales_products', {
        'name': product.name,
        'category': product.category,
        'unitPrice': product.unitPrice,
        'stockQuantity': product.stockQuantity,
        'lowStockThreshold': product.lowStockThreshold,
      });

      addedProducts.add(
        SalesProductModel(
          id: id,
          name: product.name,
          category: product.category,
          unitPrice: product.unitPrice,
          stockQuantity: product.stockQuantity,
          lowStockThreshold: product.lowStockThreshold,
        ),
      );

      _isLoading.value = false;
    } catch (e) {
      _isLoading.value = false;
      rethrow;
    }
  }

  // Complete onboarding and navigate
  Future<void> completeOnboarding() async {
    try {
      _isLoading.value = true;

      await markOnboardingComplete();
      await AlertMonitoringService.instance.runAlertChecks();

      // Refresh all controllers to load the newly initialized data
      await _refreshAllControllers();

      Get.offAllNamed(AppRoutes.dashboard);
    } finally {
      _isLoading.value = false;
    }
  }

  // Refresh all controllers with new data
  Future<void> _refreshAllControllers() async {
    if (Get.isRegistered<DashboardController>()) {
      await Get.find<DashboardController>().loadDashboard();
    }
    if (Get.isRegistered<FuelController>()) {
      await Get.find<FuelController>().fetchFuels();
    }
    if (Get.isRegistered<PumpController>()) {
      await Get.find<PumpController>().fetchPumps();
    }
    if (Get.isRegistered<SaleController>()) {
      await Get.find<SaleController>().fetchSales();
    }
    if (Get.isRegistered<ClientController>()) {
      await Get.find<ClientController>().fetchClients();
    }
    if (Get.isRegistered<StockController>()) {
      await Get.find<StockController>().fetchMovements();
    }
    if (Get.isRegistered<SalesProductController>()) {
      await Get.find<SalesProductController>().fetchProducts();
    }
    if (Get.isRegistered<SettingsController>()) {
      await Get.find<SettingsController>().loadSettings();
    }
  }

  // Reset form
  void resetFuelForm() {
    fuelName.value = '';
    fuelSupplier.value = '';
    fuelPrice.value = 0.0;
    fuelStock.value = 0.0;
    fuelLowStockThreshold.value = 0.0;
  }

  void resetPumpForm() {
    pumpName.value = '';
    selectedFuelId.value = null;
  }

  void resetProductForm() {
    productName.value = '';
    productCategory.value = '';
    productPrice.value = 0.0;
    productStock.value = 0.0;
  }

  void resetAllForms() {
    resetFuelForm();
    resetPumpForm();
    resetProductForm();
  }

  // Save station info
  Future<void> saveStationInfo() async {
    try {
      _isLoading.value = true;
      final db = await DatabaseHelper.instance.database;

      // Check if settings row exists
      final existingSettings = await db.query('settings');

      if (existingSettings.isEmpty) {
        await db.insert('settings', {
          'stationName': stationName.value,
          'stationAddress': stationAddress.value,
          'phone': stationPhone.value,
          'logoPath': logoPath.value,
          'backupPath': '',
          'adminEmail': '',
        });
      } else {
        await db.update(
          'settings',
          {
            'stationName': stationName.value,
            'stationAddress': stationAddress.value,
            'phone': stationPhone.value,
            'logoPath': logoPath.value,
          },
          where: 'id = ?',
          whereArgs: [existingSettings.first['id']],
        );
      }

      _isLoading.value = false;
    } catch (e) {
      _isLoading.value = false;
      rethrow;
    }
  }

  // Copy and save logo locally
  Future<void> setLogoFile(File file) async {
    try {
      _isLoading.value = true;

      // Get the appropriate directory for the platform
      final appDir = await getApplicationDocumentsDirectory();
      final logosDir = Directory('${appDir.path}/logos');

      if (!await logosDir.exists()) {
        await logosDir.create(recursive: true);
      }

      // Save logo with timestamp to avoid conflicts
      final fileName =
          'station_logo_${DateTime.now().millisecondsSinceEpoch}.png';
      final savedFile = File('${logosDir.path}/$fileName');
      await file.copy(savedFile.path);

      logoPath.value = savedFile.path;
      _isLoading.value = false;
    } catch (e) {
      _isLoading.value = false;
      rethrow;
    }
  }

  // Get logo file
  File? getLogoFile() {
    final path = logoPath.value;
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    if (file.existsSync()) return file;
    return null;
  }

  void resetStationForm() {
    stationName.value = '';
    stationAddress.value = '';
    stationPhone.value = '';
    logoPath.value = null;
  }
}
