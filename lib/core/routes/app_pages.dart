import 'package:get/get.dart';
import 'package:station_service_app/core/routes/app_routes.dart';
import 'package:station_service_app/presentation/pages/auth/splash_page.dart';
import 'package:station_service_app/presentation/pages/auth/login_page.dart';
import 'package:station_service_app/presentation/pages/dashboard/dashboard_page.dart';
import 'package:station_service_app/presentation/pages/clients/client_page.dart';
import 'package:station_service_app/presentation/pages/fuels/fuel_page.dart';
import 'package:station_service_app/presentation/pages/pumps/pump_page.dart';
import 'package:station_service_app/presentation/pages/reports/report_page.dart';
import 'package:station_service_app/presentation/pages/sales/sale_page.dart';
import 'package:station_service_app/presentation/pages/settings/settings_page.dart';
import 'package:station_service_app/presentation/pages/stock/stock_page.dart';
import 'package:station_service_app/presentation/pages/refueling/refueling_page.dart';
import 'package:station_service_app/presentation/pages/suppliers/supplier_page.dart';
import 'package:station_service_app/presentation/pages/expenses/expense_page.dart';
import 'package:station_service_app/presentation/pages/accounting/accounting_page.dart';
import 'package:station_service_app/presentation/pages/onboarding/onboarding_station_page.dart';
import 'package:station_service_app/presentation/pages/onboarding/onboarding_users_page.dart';
import 'package:station_service_app/presentation/pages/onboarding/onboarding_fuels_page.dart';
import 'package:station_service_app/presentation/pages/onboarding/onboarding_pumps_page.dart';
import 'package:station_service_app/presentation/pages/onboarding/onboarding_products_page.dart';
import 'package:station_service_app/presentation/pages/onboarding/onboarding_complete_page.dart';

class AppPages {
  static const String initial = AppRoutes.splash;

  static final routes = <GetPage>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashPage(),
      maintainState: true,
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      maintainState: true,
    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardPage(),
      maintainState: true,
    ),
    GetPage(
      name: AppRoutes.pumps,
      page: () => const PumpPage(),
      maintainState: true,
    ),
    GetPage(
      name: AppRoutes.fuels,
      page: () => const FuelPage(),
      maintainState: true,
    ),
    GetPage(
      name: AppRoutes.sales,
      page: () => const SalePage(),
      maintainState: true,
    ),
    GetPage(
      name: AppRoutes.clients,
      page: () => const ClientPage(),
      maintainState: true,
    ),
    GetPage(
      name: AppRoutes.stock,
      page: () => const StockPage(),
      maintainState: true,
    ),
    GetPage(
      name: AppRoutes.refueling,
      page: () => const RefuelingPage(),
      maintainState: true,
    ),
    GetPage(
      name: AppRoutes.reports,
      page: () => const ReportPage(),
      maintainState: true,
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsPage(),
      maintainState: true,
    ),
    GetPage(
      name: AppRoutes.suppliers,
      page: () => const SupplierPage(),
      maintainState: true,
    ),
    GetPage(
      name: AppRoutes.expenses,
      page: () => const ExpensePage(),
      maintainState: true,
    ),
    GetPage(
      name: AppRoutes.accounting,
      page: () => const AccountingPage(),
      maintainState: true,
    ),
    GetPage(
      name: AppRoutes.onboardingUsers,
      page: () => const OnboardingUsersPage(),
      maintainState: true,
    ),
    GetPage(
      name: AppRoutes.onboardingStation,
      page: () => const OnboardingStationPage(),
      maintainState: true,
    ),
    GetPage(
      name: AppRoutes.onboardingFuels,
      page: () => const OnboardingFuelsPage(),
      maintainState: true,
    ),
    GetPage(
      name: AppRoutes.onboardingPumps,
      page: () => const OnboardingPumpsPage(),
      maintainState: true,
    ),
    GetPage(
      name: AppRoutes.onboardingProducts,
      page: () => const OnboardingProductsPage(),
      maintainState: true,
    ),
    GetPage(
      name: AppRoutes.onboardingComplete,
      page: () => const OnboardingCompletePage(),
      maintainState: true,
    ),
  ];
}
