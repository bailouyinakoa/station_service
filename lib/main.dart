import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:station_service_app/app.dart';
import 'package:station_service_app/firebase_options.dart';
import 'package:station_service_app/presentation/controllers/accounting_controller.dart';
import 'package:station_service_app/presentation/controllers/auth_controller.dart';
import 'package:station_service_app/presentation/controllers/dashboard_controller.dart';
import 'package:station_service_app/presentation/controllers/expense_controller.dart';
import 'package:station_service_app/presentation/controllers/fuel_controller.dart';
import 'package:station_service_app/presentation/controllers/navigation_controller.dart';
import 'package:station_service_app/presentation/controllers/onboarding_controller.dart';
import 'package:station_service_app/presentation/controllers/pompiste_controller.dart';
import 'package:station_service_app/presentation/controllers/pump_controller.dart';
import 'package:station_service_app/presentation/controllers/report_controller.dart';
import 'package:station_service_app/presentation/controllers/sale_controller.dart';
import 'package:station_service_app/presentation/controllers/client_controller.dart';
import 'package:station_service_app/presentation/controllers/sales_product_controller.dart';
import 'package:station_service_app/presentation/controllers/settings_controller.dart';
import 'package:station_service_app/presentation/controllers/stock_controller.dart';
import 'package:station_service_app/presentation/controllers/supplier_controller.dart';
import 'package:station_service_app/presentation/controllers/refueling_controller.dart';
import 'package:station_service_app/services/alert_monitoring_service.dart';
import 'package:station_service_app/services/cloud_backup_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Firebase n est pas configure sur toutes les plateformes de dev.
  }
  Get.put(AuthController(), permanent: true);
  Get.put(NavigationController(), permanent: true);
  Get.put(OnboardingController(), permanent: true);
  Get.put(DashboardController(), permanent: true);
  Get.put(PumpController(), permanent: true);
  Get.put(FuelController(), permanent: true);
  Get.put(SaleController(), permanent: true);
  Get.put(ClientController(), permanent: true);
  Get.put(StockController(), permanent: true);
  Get.put(ReportController(), permanent: true);
  Get.put(SalesProductController(), permanent: true);
  Get.put(SettingsController(), permanent: true);
  Get.put(PompisteController(), permanent: true);
  Get.put(SupplierController(), permanent: true);
  Get.put(ExpenseController(), permanent: true);
  Get.put(AccountingController(), permanent: true);
  Get.put(RefuelingController(), permanent: true);

  // Initialize alert monitoring in background without blocking UI
  AlertMonitoringService.instance.initialize();
  CloudBackupService.instance.initialize();
  runApp(const StationServiceApp());
}
