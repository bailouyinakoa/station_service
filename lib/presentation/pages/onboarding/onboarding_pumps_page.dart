import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:station_service_app/core/constants/app_colors.dart';
import 'package:station_service_app/core/routes/app_routes.dart';
import 'package:station_service_app/data/models/pump_model.dart';
import 'package:station_service_app/presentation/controllers/onboarding_controller.dart';

class OnboardingPumpsPage extends StatefulWidget {
  const OnboardingPumpsPage({super.key});

  @override
  State<OnboardingPumpsPage> createState() => _OnboardingPumpsPageState();
}

class _OnboardingPumpsPageState extends State<OnboardingPumpsPage> {
  final controller = Get.find<OnboardingController>();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addPump() async {
    if (_formKey.currentState!.validate()) {
      if (controller.selectedFuelId.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner un carburant')),
        );
        return;
      }

      try {
        final pump = PumpModel(
          id: 0,
          name: _nameController.text,
          fuelId: controller.selectedFuelId.value!,
          status: 'active',
          meterReading: 0,
          fuelName: '', // Will be set by controller
        );

        await controller.addPump(pump);
        if (!mounted) return;

        _nameController.clear();
        controller.selectedFuelId.value = null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pompe ajoutée avec succès (avec 2 pistolets)'),
          ),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration des Pompes'),
        centerTitle: true,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isWide = width >= 760;
          final horizontalPadding = width < 420 ? 12.0 : 16.0;

          return SingleChildScrollView(
            padding: EdgeInsets.all(horizontalPadding),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildProgressCard(),
                      const SizedBox(height: 24),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildPumpForm()),
                            const SizedBox(width: 20),
                            Expanded(child: _buildAddedPumpsList()),
                          ],
                        )
                      else ...[
                        _buildPumpForm(),
                        const SizedBox(height: 24),
                        _buildAddedPumpsList(),
                      ],
                      const SizedBox(height: 24),
                      _buildNavigationButtons(isWide: isWide),
                      if (controller.addedPumps.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Center(
                            child: Text(
                              'Ajoutez au moins une pompe pour continuer',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Étape 4 sur 6',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Veuillez configurer au moins une pompe. Chaque pompe sera équipée de 2 pistolets par défaut.',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPumpForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nom de la pompe *',
              hintText: 'Ex: Pompe A1, Pompe B2',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ce champ est requis';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            decoration: InputDecoration(
              labelText: 'Carburant *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            isExpanded: true,
            initialValue: controller.selectedFuelId.value,
            items: controller.addedFuels
                .map(
                  (fuel) => DropdownMenuItem(
                    value: fuel.id,
                    child: Text(fuel.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (value) {
              controller.selectedFuelId.value = value;
            },
            validator: (value) {
              if (value == null) {
                return 'Veuillez sélectionner un carburant';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: controller.isLoading ? null : _addPump,
            child: controller.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Ajouter cette pompe'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddedPumpsList() {
    if (controller.addedPumps.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Pompes ajoutées (${controller.addedPumps.length})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        ...controller.addedPumps.map((pump) {
          final fuel = controller.addedFuels.firstWhereOrNull(
            (f) => f.id == pump.fuelId,
          );
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pump.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Carburant: ${fuel?.name ?? "N/A"}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  const Text('Pistolets: 2', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNavigationButtons({required bool isWide}) {
    final backButton = ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300]),
      onPressed: () => Get.back(),
      child: const Text('Retour', style: TextStyle(color: Colors.black)),
    );

    final nextButton = ElevatedButton(
      onPressed: controller.addedPumps.isEmpty
          ? null
          : () {
              Get.toNamed(AppRoutes.onboardingProducts);
            },
      child: const Text('Suivant'),
    );

    if (isWide) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [backButton, nextButton],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [nextButton, const SizedBox(height: 10), backButton],
    );
  }
}
