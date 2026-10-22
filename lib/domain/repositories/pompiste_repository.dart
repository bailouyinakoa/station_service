import 'package:station_service_app/data/models/pompiste_model.dart';

abstract class PompisteRepository {
  Future<List<PompisteModel>> getPompistes();
  Future<void> addPompiste(PompisteModel pompiste);
  Future<void> updatePompiste(PompisteModel pompiste);
  Future<void> deletePompiste(int id);
}