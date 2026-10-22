import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:station_service_app/core/routes/app_routes.dart';
import 'package:station_service_app/presentation/controllers/auth_controller.dart';
import 'package:station_service_app/presentation/controllers/navigation_controller.dart';

class AppDrawer extends StatelessWidget {
  final bool isPermanent;
  static TrackingScrollController scroller = TrackingScrollController();
  const AppDrawer({super.key, this.isPermanent = false});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final navController = Get.find<NavigationController>();

    return Obx(() {
      final currentRoute = navController.currentRoute.value;
      final drawerContent = Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Station Service',
                      style: TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      authController.user?.name ?? 'Utilisateur',
                      style: const TextStyle(color: Color(0xFF4B5563)),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      authController.user?.role.toUpperCase() ?? '',
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scroller,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 10),
                      _drawerTile(
                        context,
                        'Tableau de bord',
                        AppRoutes.dashboard,
                        Icons.dashboard_outlined,
                        selected: currentRoute == AppRoutes.dashboard,
                      ),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      _drawerTile(
                        context,
                        'Pompes',
                        AppRoutes.pumps,
                        Icons.ev_station_outlined,
                        selected: currentRoute == AppRoutes.pumps,
                      ),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      _drawerTile(
                        context,
                        'Carburants',
                        AppRoutes.fuels,
                        Icons.local_gas_station_outlined,
                        selected: currentRoute == AppRoutes.fuels,
                      ),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      _drawerTile(
                        context,
                        'Ventes',
                        AppRoutes.sales,
                        Icons.point_of_sale_outlined,
                        selected: currentRoute == AppRoutes.sales,
                      ),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      _drawerTile(
                        context,
                        'Clients',
                        AppRoutes.clients,
                        Icons.people_outline,
                        selected: currentRoute == AppRoutes.clients,
                      ),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      _drawerTile(
                        context,
                        'Stock',
                        AppRoutes.stock,
                        Icons.inventory_2_outlined,
                        selected: currentRoute == AppRoutes.stock,
                      ),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      _drawerTile(
                        context,
                        'Ravitaillement',
                        AppRoutes.refueling,
                        Icons.add_circle_outline,
                        selected: currentRoute == AppRoutes.refueling,
                      ),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      _drawerTile(
                        context,
                        'Rapports',
                        AppRoutes.reports,
                        Icons.assessment_outlined,
                        selected: currentRoute == AppRoutes.reports,
                      ),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      _drawerTile(
                        context,
                        'Dépenses',
                        AppRoutes.expenses,
                        Icons.receipt_long_outlined,
                        selected: currentRoute == AppRoutes.expenses,
                      ),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      _drawerTile(
                        context,
                        'Comptabilité',
                        AppRoutes.accounting,
                        Icons.account_balance_wallet_outlined,
                        selected: currentRoute == AppRoutes.accounting,
                      ),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      _drawerTile(
                        context,
                        'Paramètres',
                        AppRoutes.settings,
                        Icons.settings_outlined,
                        selected: currentRoute == AppRoutes.settings,
                      ),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      if (isPermanent) {
        return drawerContent;
      }

      return Drawer(child: drawerContent);
    });
  }

  Widget _drawerTile(
    BuildContext context,
    String title,
    String route,
    IconData icon, {
    required bool selected,
  }) {
    final navController = Get.find<NavigationController>();
    return Container(
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEFF6FF) : Colors.transparent,
        border: Border(
          left: BorderSide(
            color: selected ? const Color(0xFF1D4ED8) : Colors.transparent,
            width: 4,
          ),
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: selected ? const Color(0xFF1D4ED8) : const Color(0xFF374151),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: selected ? const Color(0xFF1D4ED8) : const Color(0xFF111827),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        onTap: () {
          if (!isPermanent) {
            Get.back();
          }
          navController.navigateTo(route);
        },
      ),
    );
  }
}
