import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:station_service_app/core/constants/app_strings.dart';
import 'package:station_service_app/data/models/pump_model.dart';
import 'package:station_service_app/presentation/controllers/pump_controller.dart';
import 'package:station_service_app/presentation/widgets/adaptive_modal.dart';
import 'package:station_service_app/presentation/widgets/responsive_scaffold.dart';

class PumpPage extends StatelessWidget {
  const PumpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PumpController>();
    return ResponsiveScaffold(
      title: AppStrings.pumpsTitle,
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.pumps.length,
          itemBuilder: (context, index) {
            final pump = controller.pumps[index];
            final nozzles = controller.pumpNozzles[pump.id] ?? [];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(pump.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${pump.fuelName} • Compteur ${pump.meterReading.toStringAsFixed(1)} L',
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pistolets',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    if (nozzles.isEmpty)
                      const Text('Chargement des pistolets...')
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: nozzles.map((nozzle) {
                          return ActionChip(
                            label: Text(
                              '${nozzle.name} • ${nozzle.status == 'active' ? 'Actif' : 'Inactif'}',
                            ),
                            backgroundColor: nozzle.status == 'active'
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            onPressed: () =>
                                controller.toggleNozzleStatus(nozzle),
                          );
                        }).toList(),
                      ),
                  ],
                ),
                isThreeLine: true,
                trailing: Switch(
                  value: pump.status == 'active',
                  activeThumbColor: Colors.green,
                  onChanged: (_) => controller.togglePumpStatus(pump),
                ),
                onTap: () => _showMeterDialog(context, pump, controller),
              ),
            );
          },
        );
      }),
    );
  }

  void _showMeterDialog(
    BuildContext context,
    PumpModel pump,
    PumpController controller,
  ) {
    final meterController = TextEditingController(
      text: pump.meterReading.toStringAsFixed(1),
    );
    showAdaptiveModal(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Relevé compteur'),
        content: TextField(
          controller: meterController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Lecture en litres'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final reading =
                  double.tryParse(meterController.text) ?? pump.meterReading;
              controller.saveMeter(pump.id, reading);
              meterController.clear();
              Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
