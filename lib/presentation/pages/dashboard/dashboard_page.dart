import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:station_service_app/core/constants/app_strings.dart';
import 'package:station_service_app/core/database/database_helper.dart';
import 'package:station_service_app/core/utils/formatters.dart';
import 'package:station_service_app/presentation/controllers/dashboard_controller.dart';
import 'package:station_service_app/presentation/widgets/responsive_scaffold.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final isMobile = MediaQuery.of(context).size.width < 600;

    return ResponsiveScaffold(
      title: AppStrings.dashboardTitle,
      titleStyle: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold),
      body: RefreshIndicator(
        onRefresh: controller.loadDashboard,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _loadStationInfo(),
          builder: (context, snapshot) {
            final stationName = snapshot.data?['stationName'] as String? ?? 'Station Service';
            final logoPath = snapshot.data?['logoPath'] as String?;
            
            return ListView(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              children: [
                // Header principal avec gradient et logo
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: isMobile ? 18 : 32,
                    horizontal: isMobile ? 14 : 24,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF283593),
                        Color(0xFF3949AB),
                        Color(0xFF5C6BC0),
                        Color(0xFF7986CB),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: [0.0, 0.3, 0.7, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.12),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo et titre
                      Row(
                        children: [
                          // Logo de la station
                          if (logoPath != null && logoPath.isNotEmpty && File(logoPath).existsSync())
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: isMobile ? 60 : 80,
                                height: isMobile ? 60 : 80,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(16),
                              ),
                                child: Image.file(
                                  File(logoPath),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          else
                            Container(
                              width: isMobile ? 60 : 80,
                              height: isMobile ? 60 : 80,
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(255, 255, 255, 0.25),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color.fromRGBO(255, 255, 255, 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.image_outlined,
                                color: Colors.white.withOpacity(0.5),
                                size: isMobile ? 28 : 36,
                              ),
                            ),
                          SizedBox(width: isMobile ? 12 : 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stationName,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isMobile ? 18 : 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: isMobile ? 4 : 8),
                                const Text(
                                  'Vue d\'ensemble de votre station-service',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isMobile ? 14 : 28),
                      Container(
                        padding: EdgeInsets.all(isMobile ? 14 : 20),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(255, 255, 255, 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color.fromRGBO(255, 255, 255, 0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.local_gas_station,
                                  color: const Color.fromRGBO(255, 255, 255, 0.9),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Statut de la station',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Obx(
                              () => Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  SizedBox(
                                    width: isMobile
                                        ? (MediaQuery.of(context).size.width - 56) / 2
                                        : (MediaQuery.of(context).size.width - 120) / 3,
                                    child: _statusChip(
                                      'CA Journalier',
                                      controller.dailyRevenue.value,
                                      Icons.today,
                                  const Color(0xFF4CAF50),
                                ),
                              ),
                              SizedBox(
                                width: isMobile
                                    ? (MediaQuery.of(context).size.width - 56) / 2
                                    : (MediaQuery.of(context).size.width - 120) / 3,
                                child: _statusChip(
                                  'CA Mensuel',
                                  controller.monthlyRevenue.value,
                                  Icons.calendar_month,
                                  const Color(0xFF2196F3),
                                ),
                              ),
                              SizedBox(
                                width: isMobile
                                    ? (MediaQuery.of(context).size.width - 56) / 2
                                    : (MediaQuery.of(context).size.width - 120) / 3,
                                child: _statusChip(
                                  'Stock Total',
                                  controller.totalStockValue.value,
                                  Icons.inventory_2,
                                  const Color(0xFFFF9800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Obx(
              () => Card(
                elevation: 0.9,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ventes produits (dashboard)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Aujourd\'hui: ${controller.dailyProductCount.value} ventes • ${Formatters.cfa(controller.dailyProductRevenue.value)}',
                      ),
                      const SizedBox(height: 10),
                      if (controller.recentProductSales.isEmpty)
                        const Text('Aucune vente produit récente.')
                      else
                        ...controller.recentProductSales.map((sale) {
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.shopping_bag_outlined, size: 18),
                            title: Text('${sale['productName'] ?? '-'}'),
                            subtitle: Text(
                              '${DateFormat('dd/MM HH:mm').format(DateTime.parse('${sale['date']}'))} • Qté: ${((sale['quantity'] as num?) ?? 0).toStringAsFixed(2)}',
                            ),
                            trailing: Text(
                              Formatters.cfa((sale['amount'] as num?)?.toDouble() ?? 0),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Stock carburants en temps réel',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF283593),
              ),
            ),
            const SizedBox(height: 12),
            Obx(
              () => Column(
                children: controller.fuelStock.entries.map((entry) {
                  final fuelType = entry.key;
                  final stock = entry.value;
                  final threshold = controller.fuelThresholds[fuelType] ?? 0.0;
                  final isLowStock = stock < threshold;

                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.95 + (value * 0.05),
                        child: Opacity(
                          opacity: value,
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            elevation: 1 + value,
                            shadowColor: (isLowStock ? Colors.red : Colors.blue).withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white,
                                    (isLowStock ? Colors.red : Colors.blue).withValues(alpha: 0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: (isLowStock ? Colors.red : Colors.blue).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isLowStock ? Icons.warning : Icons.local_gas_station,
                                    color: isLowStock ? Colors.red : Colors.blue,
                                    size: 24,
                                  ),
                                ),
                                title: Text(
                                  fuelType,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: isLowStock ? Colors.red[700] : Colors.black87,
                                  ),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: (isLowStock ? Colors.red : Colors.green).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: (isLowStock ? Colors.red : Colors.green).withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    '${stock.toStringAsFixed(1)} L',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isLowStock ? Colors.red[700] : Colors.green[700],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        );
          },
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _loadStationInfo() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final settings = await db.query('settings');
      if (settings.isNotEmpty) {
        return settings.first as Map<String, dynamic>;
      }
      return {
        'stationName': 'Station Service',
        'logoPath': null,
      };
    } catch (e) {
      return {
        'stationName': 'Station Service',
        'logoPath': null,
      };
    }
  }

  Widget _statusChip(String title, double value, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color.fromRGBO(255, 255, 255, 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: accentColor.withValues(alpha: 0.8),
                size: 13,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Formatters.cfa(value),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
