import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:station_service_app/core/constants/app_strings.dart';
import 'package:station_service_app/core/utils/formatters.dart';
import 'package:station_service_app/data/models/client_model.dart';
import 'package:station_service_app/presentation/controllers/client_controller.dart';
import 'package:station_service_app/presentation/widgets/adaptive_modal.dart';
import 'package:station_service_app/presentation/widgets/responsive_scaffold.dart';

class ClientPage extends StatelessWidget {
  const ClientPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ClientController>();
    return ResponsiveScaffold(
      title: AppStrings.clientsTitle,
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.clients.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('Aucun client. Ajoutez votre premier client.'),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.clients.length + 1,
          itemBuilder: (context, index) {
            if (index == controller.clients.length) {
              return const SizedBox(height: 100);
            }
            final client = controller.clients[index];
            return Card(
              elevation: 0.8,
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(client.name),
                subtitle: Text(
                  'Solde: ${Formatters.cfa(client.balance)} • Crédit: ${Formatters.cfa(client.credit)}',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                onTap: () => _showClientDialog(context, client, controller),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddClientDialog(context, controller),
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('Nouveau client'),
      ),
    );
  }

  void _showClientDialog(
    BuildContext context,
    ClientModel client,
    ClientController controller,
  ) {
    final balanceController = TextEditingController(
      text: client.balance.toString(),
    );
    final creditController = TextEditingController(
      text: client.credit.toString(),
    );
    showAdaptiveModal(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails client'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Carte: ${client.cardNumber ?? 'Aucune'}'),
              const SizedBox(height: 12),
              TextField(
                controller: balanceController,
                decoration: const InputDecoration(labelText: 'Solde'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: creditController,
                decoration: const InputDecoration(labelText: 'Crédit'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          FilledButton(
            onPressed: () {
              final updated = ClientModel(
                id: client.id,
                name: client.name,
                cardNumber: client.cardNumber,
                balance:
                    double.tryParse(balanceController.text) ?? client.balance,
                credit: double.tryParse(creditController.text) ?? client.credit,
              );
              controller.updateClient(updated);
              balanceController.clear();
              creditController.clear();
              Navigator.pop(context);
            },
            child: const Text('Mettre à jour'),
          ),
        ],
      ),
    );
  }

  void _showAddClientDialog(BuildContext context, ClientController controller) {
    final nameController = TextEditingController();
    final cardController = TextEditingController();
    final balanceController = TextEditingController(text: '0');
    final creditController = TextEditingController(text: '0');

    showAdaptiveModal(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un client'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              TextField(
                controller: cardController,
                decoration: const InputDecoration(
                  labelText: 'Numéro de carte (optionnel)',
                ),
              ),
              TextField(
                controller: balanceController,
                decoration: const InputDecoration(labelText: 'Solde initial'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: creditController,
                decoration: const InputDecoration(labelText: 'Crédit initial'),
                keyboardType: TextInputType.number,
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
              final name = nameController.text.trim();
              if (name.isEmpty) {
                Get.snackbar('Validation', 'Le nom du client est obligatoire');
                return;
              }
              await controller.addClient(
                name: name,
                cardNumber: cardController.text.trim(),
                balance: double.tryParse(balanceController.text) ?? 0,
                credit: double.tryParse(creditController.text) ?? 0,
              );
              nameController.clear();
              cardController.clear();
              balanceController.clear();
              creditController.clear();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}
