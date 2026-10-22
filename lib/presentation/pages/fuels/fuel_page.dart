import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:station_service_app/core/constants/app_strings.dart';
import 'package:station_service_app/core/utils/formatters.dart';
import 'package:station_service_app/data/models/fuel_model.dart';
import 'package:station_service_app/presentation/controllers/fuel_controller.dart';
import 'package:station_service_app/presentation/widgets/adaptive_modal.dart';
import 'package:station_service_app/presentation/widgets/responsive_scaffold.dart';

class FuelPage extends StatelessWidget {
  const FuelPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FuelController>();
    return ResponsiveScaffold(
      title: AppStrings.fuelsTitle,
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: controller.fuels
              .map(
                (fuel) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(fuel.name),
                    subtitle: Text(
                      'Fournisseur: ${fuel.supplier} • Prix: ${Formatters.cfa(fuel.pricePerLiter)}/L • Stock: ${fuel.stockLiters.toStringAsFixed(1)} L',
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Icon(
                      fuel.stockLiters <= fuel.lowStockThreshold
                          ? Icons.warning
                          : Icons.check_circle,
                      color: fuel.stockLiters <= fuel.lowStockThreshold
                          ? Colors.orange
                          : Colors.green,
                    ),
                    onTap: () => _showDetailsDialog(context, fuel),
                  ),
                ),
              )
              .toList(),
        );
      }),
    );
  }

  void _showDetailsDialog(
    BuildContext context,
    FuelModel fuel,
  ) {
    showAdaptiveModal(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails du carburant'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Nom'),
                controller: TextEditingController(text: fuel.name),
              ),
              TextField(
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Fournisseur'),
                controller: TextEditingController(text: fuel.supplier),
              ),
              TextField(
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Prix / L'),
                controller: TextEditingController(
                  text: '${Formatters.cfa(fuel.pricePerLiter)}',
                ),
              ),
              TextField(
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Stock (L)'),
                controller: TextEditingController(
                  text: fuel.stockLiters.toStringAsFixed(2),
                ),
              ),
              TextField(
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Seuil alerte'),
                controller: TextEditingController(
                  text: fuel.lowStockThreshold.toStringAsFixed(2),
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
