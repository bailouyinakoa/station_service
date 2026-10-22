import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:station_service_app/core/routes/app_routes.dart';
import 'package:station_service_app/presentation/widgets/app_drawer.dart';

class ResponsiveScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final TextStyle? titleStyle;

  const ResponsiveScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.titleStyle,
  });

  static const double desktopBreakpoint = 900;
  static const double drawerWidth = 280;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= desktopBreakpoint;

        if (!isDesktop) {
          return Scaffold(
            appBar: AppBar(
              title: Text(title, style: titleStyle),
              actions: actions,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFE5E7EB),
                ),
              ),
            ),
            body: body,
            floatingActionButton: floatingActionButton,
            bottomNavigationBar:
                bottomNavigationBar ?? const _MobileBottomNavigation(),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(title, style: titleStyle),
            actions: actions,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
            ),
          ),
          body: Row(
            children: [
              const SizedBox(
                width: drawerWidth,
                child: AppDrawer(isPermanent: true),
              ),
              const VerticalDivider(
                width: 1,
                thickness: 1,
                color: Color(0xFFE5E7EB),
              ),
              Expanded(child: body),
            ],
          ),
          floatingActionButton: floatingActionButton,
          bottomNavigationBar: bottomNavigationBar,
        );
      },
    );
  }
}

class _MobileBottomNavigation extends StatefulWidget {
  const _MobileBottomNavigation();

  static const _allItems = <({String route, String label, IconData icon})>[
    (
      route: AppRoutes.dashboard,
      label: 'Accueil',
      icon: Icons.dashboard_outlined,
    ),
    (
      route: AppRoutes.sales,
      label: 'Ventes',
      icon: Icons.point_of_sale_outlined,
    ),
    (
      route: AppRoutes.reports,
      label: 'Rapports',
      icon: Icons.assessment_outlined,
    ),
    (route: AppRoutes.clients, label: 'Clients', icon: Icons.people_outline),
    (route: AppRoutes.pumps, label: 'Pompes', icon: Icons.ev_station_outlined),
    (
      route: AppRoutes.fuels,
      label: 'Carburants',
      icon: Icons.local_gas_station_outlined,
    ),
    (route: AppRoutes.stock, label: 'Stock', icon: Icons.inventory_2_outlined),
    (
      route: AppRoutes.refueling,
      label: 'Ravitaillement',
      icon: Icons.add_circle_outline,
    ),
    (
      route: AppRoutes.expenses,
      label: 'Dépenses',
      icon: Icons.receipt_long_outlined,
    ),
    (
      route: AppRoutes.accounting,
      label: 'Comptabilité',
      icon: Icons.account_balance_wallet_outlined,
    ),
    (
      route: AppRoutes.settings,
      label: 'Paramètres',
      icon: Icons.settings_outlined,
    ),
  ];

  @override
  State<_MobileBottomNavigation> createState() =>
      _MobileBottomNavigationState();
}

class _MobileBottomNavigationState extends State<_MobileBottomNavigation>
    with AutomaticKeepAliveClientMixin {
  static double _lastScrollOffset = 0;

  late final ScrollController controller;

  @override
  void initState() {
    super.initState();
    controller = ScrollController(initialScrollOffset: _lastScrollOffset)
      ..addListener(_saveScrollOffset);
  }

  void _saveScrollOffset() {
    if (controller.hasClients) {
      _lastScrollOffset = controller.offset;
    }
  }

  @override
  void dispose() {
    _saveScrollOffset();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GetBuilder<GetMaterialController>(
      builder: (context) {
        final currentRoute = Get.currentRoute;

        return Material(
          elevation: 2,
          color: Colors.white,
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 76,
              child: Row(
                children: [
                  Expanded(
                    child: ListView.builder(
                      primary: false,
                      controller: controller,
                      key: const PageStorageKey<String>(
                        'mobile_bottom_navigation_scroll_view',
                      ),
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      itemCount: _MobileBottomNavigation._allItems.length,
                      itemBuilder: (context, index) {
                        final item = _MobileBottomNavigation._allItems[index];
                        return _BottomAction(
                          icon: item.icon,
                          label: item.label,
                          selected: currentRoute == item.route,
                          onTap: () {
                            if (item.route != currentRoute) {
                              Get.offNamed(item.route, preventDuplicates: true);
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF1D4ED8) : const Color(0xFF4B5563);
    return SizedBox(
      width: 78,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 2),
              Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
