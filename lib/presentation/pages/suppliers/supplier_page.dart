import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:station_service_app/presentation/controllers/supplier_controller.dart';
import 'package:station_service_app/presentation/widgets/adaptive_modal.dart';
import 'package:station_service_app/presentation/widgets/responsive_scaffold.dart';

class SupplierPage extends StatelessWidget {
  const SupplierPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SupplierController>();
    return ResponsiveScaffold(
      title: 'Fournisseurs',
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (controller.suppliers.isEmpty)
              const Text('Aucun fournisseur enregistré.')
            else
              ...controller.suppliers.map(
                (supplier) => Card(
                  elevation: 0.8,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text('${supplier['name'] ?? '-'}'),
                    subtitle: Text(
                      '${supplier['category'] ?? '-'} • ${((supplier['quantity'] as num?) ?? 0).toStringAsFixed(2)} ${supplier['unit']} x ${((supplier['unitPrice'] as num?) ?? 0).toStringAsFixed(2)} • ${supplier['paymentType']}',
                    ),
                    trailing: Text(
                      '${((supplier['paymentType'] ?? '').toString().toLowerCase().contains('crédit')) ? 'Crédit' : 'Débit'}\n${((supplier['totalAmount'] as num?) ?? 0).toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 100),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSupplierDialog(context, controller),
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Nouveau fournisseur'),
      ),
    );
  }

  void _showAddSupplierDialog(
    BuildContext context,
    SupplierController controller,
  ) {
    final name = TextEditingController();
    final phone = TextEditingController();
    final unitPrice = TextEditingController();
    final quantity = TextEditingController();
    final selectedCategory = Rx<String?>(
      controller.categories.isNotEmpty ? controller.categories.first : null,
    );
    final selectedPayment = Rx<String?>(
      controller.paymentTypes.isNotEmpty ? controller.paymentTypes.first : null,
    );
    showAdaptiveModal(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ajouter fournisseur'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              const SizedBox(height: 8),
              Obx(
                () => DropdownButtonFormField<String>(
                  initialValue: selectedCategory.value,
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                  items: controller.categories
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: (value) => selectedCategory.value = value,
                ),
              ),
              TextField(
                controller: phone,
                decoration: const InputDecoration(labelText: 'Téléphone'),
              ),
              TextField(
                controller: unitPrice,
                decoration: const InputDecoration(labelText: 'Prix unitaire'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: quantity,
                decoration: const InputDecoration(labelText: 'Quantité'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              Obx(
                () => DropdownButtonFormField<String>(
                  initialValue: selectedPayment.value,
                  decoration: const InputDecoration(
                    labelText: 'Type de paiement',
                  ),
                  items: controller.paymentTypes
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: (value) => selectedPayment.value = value,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              if (name.text.trim().isEmpty || selectedCategory.value == null) {
                Get.snackbar('Validation', 'Nom et catégorie obligatoires');
                return;
              }
              final price = double.tryParse(unitPrice.text) ?? 0;
              final qty = double.tryParse(quantity.text) ?? 0;
              if (price <= 0 ||
                  qty <= 0 ||
                  selectedCategory.value == null ||
                  selectedPayment.value == null) {
                Get.snackbar(
                  'Validation',
                  'Prix, quantité et choix obligatoires',
                );
                return;
              }
              final unit = selectedCategory.value?.toLowerCase() == 'carburant'
                  ? 'litre'
                  : 'nombre';
              await controller.addSupplier(
                name: name.text,
                category: selectedCategory.value!,
                paymentType: selectedPayment.value!,
                phone: phone.text,
                unitPrice: price,
                quantity: qty,
                unit: unit,
              );
              name.clear();
              phone.clear();
              unitPrice.clear();
              quantity.clear();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
