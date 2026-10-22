import 'package:station_service_app/domain/entities/client.dart';

abstract class ClientRepository {
  Future<List<Client>> getClients();
  Future<void> updateClient(Client client);
}
