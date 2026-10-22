import 'package:get/get.dart';
import 'package:station_service_app/core/database/database_helper.dart';
import 'package:station_service_app/data/models/client_model.dart';

class ClientController extends GetxController {
  final clients = <ClientModel>[].obs;
  final _selectedClient = Rxn<ClientModel>();
  final _isLoading = false.obs;

  bool get isLoading => _isLoading.value;
  ClientModel? get selectedClient => _selectedClient.value;

  @override
  void onInit() {
    super.onInit();
    fetchClients();
  }

  Future<void> fetchClients() async {
    _isLoading.value = true;
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('clients');
    clients.value = rows.map((row) => ClientModel.fromMap(row)).toList();
    _isLoading.value = false;
  }

  void pickClient(ClientModel client) {
    _selectedClient.value = client;
  }

  Future<void> updateClient(ClientModel client) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'clients',
      client.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
    await fetchClients();
  }

  Future<void> addClient({
    required String name,
    String? cardNumber,
    double balance = 0,
    double credit = 0,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('clients', {
      'name': name.trim(),
      'cardNumber': (cardNumber?.trim().isEmpty ?? true)
          ? null
          : cardNumber?.trim(),
      'balance': balance,
      'credit': credit,
    });
    await fetchClients();
  }
}
