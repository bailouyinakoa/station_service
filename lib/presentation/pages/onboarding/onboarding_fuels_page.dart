import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:station_service_app/core/constants/app_colors.dart';
import 'package:station_service_app/core/routes/app_routes.dart';
import 'package:station_service_app/data/models/fuel_model.dart';
import 'package:station_service_app/presentation/controllers/onboarding_controller.dart';

class OnboardingFuelsPage extends StatefulWidget {
  const OnboardingFuelsPage({super.key});

  @override
  State<OnboardingFuelsPage> createState() => _OnboardingFuelsPageState();
}

class _OnboardingFuelsPageState extends State<OnboardingFuelsPage> {
  final controller = Get.find<OnboardingController>();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _supplierController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _thresholdController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _supplierController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  void _addFuel() async {
    if (_formKey.currentState!.validate()) {
      try {
        final fuel = FuelModel(
          id: 0,
          name: _nameController.text,
          supplier: _supplierController.text,
          pricePerLiter: double.parse(_priceController.text),
          stockLiters: double.parse(_stockController.text),
          lowStockThreshold: double.parse(_thresholdController.text),
        );

        await controller.addFuel(fuel);
        _nameController.clear();
        _supplierController.clear();
        _priceController.clear();
        _stockController.clear();
        _thresholdController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Carburant ajouté avec succès')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final maxWidth = isMobile ? double.infinity : 600.0;
    final padding = isMobile ? 16.0 : 32.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration des Carburants'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: SizedBox(
              width: maxWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress indicator
                  Container(
                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Étape 3 sur 6',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 14 : 16,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: isMobile ? 6 : 8),
                        Text(
                          'Veuillez configurer au moins un carburant pour démarrer votre station service.',
                          style: TextStyle(fontSize: isMobile ? 12 : 14),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isMobile ? 16 : 24),

                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Nom du carburant *',
                            hintText: 'Ex: Essence, Diesel, GPL',
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
                        TextFormField(
                          controller: _supplierController,
                          decoration: InputDecoration(
                            labelText: 'Fournisseur',
                            hintText: 'Ex: TotalEnergies, Shell',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _priceController,
                          decoration: InputDecoration(
                            labelText: 'Prix par litre *',
                            hintText: '550',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ce champ est requis';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Veuillez entrer un nombre valide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _stockController,
                          decoration: InputDecoration(
                            labelText: 'Stock initial (litres) *',
                            hintText: '5000',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ce champ est requis';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Veuillez entrer un nombre valide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _thresholdController,
                          decoration: InputDecoration(
                            labelText: 'Seuil minimum stock (litres) *',
                            hintText: '500',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ce champ est requis';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Veuillez entrer un nombre valide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: Obx(
                            () => ElevatedButton(
                              onPressed: controller.isLoading ? null : _addFuel,
                              child: controller.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Ajouter ce carburant'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // List of added fuels
                  if (controller.addedFuels.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Carburants ajoutés (${controller.addedFuels.length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...controller.addedFuels.map(
                          (fuel) => Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fuel.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Fournisseur: ${fuel.supplier}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Prix: ${fuel.pricePerLiter} / litre',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),

                  // Navigation buttons
                  const SizedBox(height: 16),

                  Obx(() {
                    if (controller.addedFuels.isNotEmpty) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 16 : 24,
                                vertical: isMobile ? 12 : 16,
                              ),
                            ),
                            onPressed: () => Get.back(),
                            child: const Text(
                              'Annuler',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 16 : 24,
                                vertical: isMobile ? 12 : 16,
                              ),
                            ),
                            onPressed: () {
                              Get.toNamed(AppRoutes.onboardingPumps);
                            },
                            child: const Text('Suivant'),
                          ),
                        ],
                      );
                    } else {
                      return Center(
                        child: Text(
                          'Ajoutez au moins un carburant pour continuer',

                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: isMobile ? 12 : 14,
                          ),
                        ),
                      );
                    }
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
