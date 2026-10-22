import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:station_service_app/presentation/controllers/auth_controller.dart';
import 'package:station_service_app/presentation/controllers/refueling_controller.dart';
import 'package:station_service_app/presentation/widgets/adaptive_modal.dart';
import 'package:station_service_app/presentation/widgets/responsive_scaffold.dart';

class RefuelingPage extends StatefulWidget {
  const RefuelingPage({super.key});

  @override
  State<RefuelingPage> createState() => _RefuelingPageState();
}

class _RefuelingPageState extends State<RefuelingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RefuelingController>();

    return ResponsiveScaffold(
      title: 'Ravitaillement',
      body: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.local_gas_station), text: 'Carburants'),
                Tab(icon: Icon(Icons.shopping_cart), text: 'Produits'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFuelsTab(controller),
                _buildProductsTab(controller),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuelsTab(RefuelingController controller) {
    final authController = Get.find<AuthController>();
    return Obx(() {
      if (controller.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.fuels.isEmpty) {
        return const Center(child: Text('Aucun carburant enregistré'));
      }

      return RefreshIndicator(
        onRefresh: () => controller.refreshData(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.fuels.length,
          itemBuilder: (context, index) {
            final fuel = controller.fuels[index];
            final isLowStock = fuel.stockLiters <= fuel.lowStockThreshold;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: isLowStock
                  ? Colors.red.shade50
                  : Theme.of(context).colorScheme.surface,
              child: ListTile(
                leading: Icon(
                  Icons.local_gas_station,
                  color: isLowStock
                      ? Colors.red
                      : Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
                title: Text(
                  fuel.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      'Fournisseur: ${fuel.supplier}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: (fuel.stockLiters / (fuel.lowStockThreshold * 2))
                          .clamp(0.0, 1.0),
                      backgroundColor: Colors.grey.shade300,
                      minHeight: 6,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stock: ${fuel.stockLiters.toStringAsFixed(1)}L / Seuil: ${fuel.lowStockThreshold.toStringAsFixed(1)}L',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isLowStock ? Colors.red : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                trailing: ElevatedButton.icon(
                  onPressed: authController.isAdmin
                      ? () => _showRefuelFuelDialog(
                          context,
                          controller,
                          fuel.id,
                          fuel.name,
                          fuel.supplier,
                        )
                      : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Ravitailler'),
                ),
                isThreeLine: true,
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildProductsTab(RefuelingController controller) {
    final authController = Get.find<AuthController>();
    return Obx(() {
      if (controller.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.products.isEmpty) {
        return const Center(child: Text('Aucun produit enregistré'));
      }

      return RefreshIndicator(
        onRefresh: () => controller.refreshData(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.products.length,
          itemBuilder: (context, index) {
            final product = controller.products[index];
            final isLowStock =
                product.stockQuantity <= product.lowStockThreshold;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: isLowStock
                  ? Colors.red.shade50
                  : Theme.of(context).colorScheme.surface,
              child: ListTile(
                leading: Icon(
                  Icons.shopping_bag,
                  color: isLowStock
                      ? Colors.red
                      : Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
                title: Text(
                  product.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      'Catégorie: ${product.category}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value:
                          (product.stockQuantity /
                                  (product.lowStockThreshold * 2))
                              .clamp(0.0, 1.0),
                      backgroundColor: Colors.grey.shade300,
                      minHeight: 6,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stock: ${product.stockQuantity.toStringAsFixed(1)} unités / Seuil: ${product.lowStockThreshold.toStringAsFixed(1)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isLowStock ? Colors.red : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                trailing: ElevatedButton.icon(
                  onPressed: authController.isAdmin
                      ? () => _showRefuelProductDialog(
                          context,
                          controller,
                          product.id,
                          product.name,
                        )
                      : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Ravitailler'),
                ),
                isThreeLine: true,
              ),
            );
          },
        ),
      );
    });
  }

  void _showRefuelFuelDialog(
    BuildContext context,
    RefuelingController controller,
    int fuelId,
    String fuelName,
    String defaultSupplier,
  ) {
    final litersController = TextEditingController();
    final supplierController = TextEditingController(text: defaultSupplier);
    final noteController = TextEditingController();
    final isSaving = false.obs;

    showAdaptiveModal(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ravitailler - $fuelName'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: litersController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Quantité (litres)',
                  prefixIcon: const Icon(Icons.local_gas_station),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: supplierController,
                decoration: InputDecoration(
                  labelText: 'Fournisseur',
                  prefixIcon: const Icon(Icons.business),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Remarques (optionnel)',
                  hintText: 'Numéro de commande, etc.',
                  prefixIcon: const Icon(Icons.notes),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Obx(() {
            return TextButton(
              onPressed: isSaving.value ? null : () => Navigator.pop(context),
              child: const Text('Annuler'),
            );
          }),
          Obx(() {
            return ElevatedButton(
              onPressed: isSaving.value
                  ? null
                  : () async {
                      if (litersController.text.isEmpty) {
                        Get.snackbar(
                          'Erreur',
                          'Veuillez entrer la quantité',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                        return;
                      }

                      final liters = double.tryParse(litersController.text);
                      if (liters == null || liters <= 0) {
                        Get.snackbar(
                          'Erreur',
                          'Quantité invalide',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                        return;
                      }

                      final success = await controller.refuelFuel(
                        fuelId: fuelId,
                        liters: liters,
                        supplier: supplierController.text,
                        note: noteController.text.isNotEmpty
                            ? noteController.text
                            : null,
                      );

                      if (success && context.mounted) {
                        Get.snackbar(
                          'Succès',
                          'Ravitaillement enregistré',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                        );
                        Navigator.pop(context);
                      }
                    },
              child: isSaving.value
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Ravitailler'),
            );
          }),
        ],
      ),
    );
  }

  void _showRefuelProductDialog(
    BuildContext context,
    RefuelingController controller,
    int productId,
    String productName,
  ) {
    final quantityController = TextEditingController();
    final supplierController = TextEditingController();
    final noteController = TextEditingController();
    final isSaving = false.obs;

    showAdaptiveModal(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ravitailler - $productName'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quantityController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Quantité (unités)',
                  prefixIcon: const Icon(Icons.shopping_bag),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: supplierController,
                decoration: InputDecoration(
                  labelText: 'Fournisseur',
                  prefixIcon: const Icon(Icons.business),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Remarques (optionnel)',
                  hintText: 'Numéro de commande, etc.',
                  prefixIcon: const Icon(Icons.notes),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Obx(() {
            return TextButton(
              onPressed: isSaving.value ? null : () => Navigator.pop(context),
              child: const Text('Annuler'),
            );
          }),
          Obx(() {
            return ElevatedButton(
              onPressed: isSaving.value
                  ? null
                  : () async {
                      if (quantityController.text.isEmpty) {
                        Get.snackbar(
                          'Erreur',
                          'Veuillez entrer la quantité',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                        return;
                      }

                      final quantity = double.tryParse(quantityController.text);
                      if (quantity == null || quantity <= 0) {
                        Get.snackbar(
                          'Erreur',
                          'Quantité invalide',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                        return;
                      }

                      final success = await controller.refuelProduct(
                        productId: productId,
                        quantity: quantity,
                        supplier: supplierController.text,
                        note: noteController.text.isNotEmpty
                            ? noteController.text
                            : null,
                      );

                      if (success && context.mounted) {
                        Get.snackbar(
                          'Succès',
                          'Ravitaillement enregistré',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.green,
                          colorText: Colors.white,
                        );
                        Navigator.pop(context);
                      }
                    },
              child: isSaving.value
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Ravitailler'),
            );
          }),
        ],
      ),
    );
  }
}
