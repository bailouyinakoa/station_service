import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:station_service_app/core/utils/formatters.dart';
import 'package:station_service_app/presentation/controllers/expense_controller.dart';
import 'package:station_service_app/presentation/widgets/adaptive_modal.dart';
import 'package:station_service_app/presentation/widgets/responsive_scaffold.dart';

class ExpensePage extends StatelessWidget {
  const ExpensePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ExpenseController>();
    return ResponsiveScaffold(
      title: 'Dépenses',
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (controller.expenses.isEmpty)
              const Text('Aucune dépense enregistrée.')
            else
              ...controller.expenses.map(
                (expense) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 0.8,
                  child: ListTile(
                    title: Text('${expense['motif'] ?? '-'}'),
                    subtitle: Text(
                      '${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse('${expense['date']}'))} • ${expense['paymentType'] ?? '-'} • ${expense['supplierName'] ?? 'Sans fournisseur'}',
                    ),
                    trailing: Text(
                      Formatters.cfa(
                        (expense['amount'] as num?)?.toDouble() ?? 0,
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 100),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseDialog(context, controller),
        icon: const Icon(Icons.add_card_outlined),
        label: const Text('Nouvelle dépense'),
      ),
    );
  }

  void _showAddExpenseDialog(
    BuildContext context,
    ExpenseController controller,
  ) {
    final motif = TextEditingController();
    final amount = TextEditingController();
    final selectedPayment = Rx<String?>(
      controller.paymentTypes.isNotEmpty ? controller.paymentTypes.first : null,
    );

    showAdaptiveModal(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ajouter dépense'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: motif,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Motif (détails)'),
              ),
              TextField(
                controller: amount,
                decoration: const InputDecoration(labelText: 'Montant'),
                keyboardType: TextInputType.number,
              ),
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
              final parsedAmount = double.tryParse(amount.text) ?? 0;
              if (motif.text.trim().isEmpty || parsedAmount <= 0) {
                Get.snackbar('Validation', 'Motif et montant valides requis');
                return;
              }
              await controller.addExpense(
                motif: motif.text,
                amount: parsedAmount,
                paymentType: selectedPayment.value ?? 'Espèces',
              );
              motif.clear();
              amount.clear();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
