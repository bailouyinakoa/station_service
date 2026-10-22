import 'package:station_service_app/domain/entities/sale.dart';

abstract class SaleRepository {
  Future<List<Sale>> getSales();
  Future<void> addSale(Sale sale);
}
