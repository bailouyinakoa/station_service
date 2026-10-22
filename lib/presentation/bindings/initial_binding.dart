import 'package:get/get.dart';
import 'package:station_service_app/presentation/controllers/auth_controller.dart';
import 'package:station_service_app/presentation/controllers/dashboard_controller.dart';
import 'package:station_service_app/presentation/controllers/pump_controller.dart';
import 'package:station_service_app/presentation/controllers/fuel_controller.dart';
import 'package:station_service_app/presentation/controllers/sale_controller.dart';
import 'package:station_service_app/presentation/controllers/client_controller.dart';
import 'package:station_service_app/presentation/controllers/stock_controller.dart';
import 'package:station_service_app/presentation/controllers/report_controller.dart';
import 'package:station_service_app/presentation/controllers/sales_product_controller.dart';
import 'package:station_service_app/presentation/controllers/settings_controller.dart';
import 'package:station_service_app/presentation/controllers/pompiste_controller.dart';
import 'package:station_service_app/presentation/controllers/supplier_controller.dart';
import 'package:station_service_app/presentation/controllers/expense_controller.dart';
import 'package:station_service_app/presentation/controllers/accounting_controller.dart';
import 'package:station_service_app/presentation/controllers/refueling_controller.dart';
import 'package:station_service_app/presentation/controllers/navigation_controller.dart';
import 'package:station_service_app/presentation/controllers/onboarding_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NavigationController>(
      () => NavigationController(),
      fenix: true,
    );
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
    Get.lazyPut<OnboardingController>(
      () => OnboardingController(),
      fenix: true,
    );
    Get.lazyPut<DashboardController>(() => DashboardController(), fenix: true);
    Get.lazyPut<PumpController>(() => PumpController(), fenix: true);
    Get.lazyPut<FuelController>(() => FuelController(), fenix: true);
    Get.lazyPut<SaleController>(() => SaleController(), fenix: true);
    Get.lazyPut<ClientController>(() => ClientController(), fenix: true);
    Get.lazyPut<StockController>(() => StockController(), fenix: true);
    Get.lazyPut<RefuelingController>(() => RefuelingController(), fenix: true);
    Get.lazyPut<ReportController>(() => ReportController(), fenix: true);
    Get.lazyPut<SalesProductController>(
      () => SalesProductController(),
      fenix: true,
    );
    Get.lazyPut<SettingsController>(() => SettingsController(), fenix: true);
    Get.lazyPut<PompisteController>(() => PompisteController(), fenix: true);
    Get.lazyPut<SupplierController>(() => SupplierController(), fenix: true);
    Get.lazyPut<ExpenseController>(() => ExpenseController(), fenix: true);
    Get.lazyPut<AccountingController>(
      () => AccountingController(),
      fenix: true,
    );
  }
}
