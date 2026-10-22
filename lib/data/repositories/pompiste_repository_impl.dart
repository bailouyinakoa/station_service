import 'package:station_service_app/core/database/database_helper.dart';
import 'package:station_service_app/data/models/pompiste_model.dart';
import 'package:station_service_app/domain/repositories/pompiste_repository.dart';

class PompisteRepositoryImpl implements PompisteRepository {
  @override
  Future<List<PompisteModel>> getPompistes() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('pompistes');
    return rows.map((row) => PompisteModel.fromMap(row)).toList();
  }

  @override
  Future<void> addPompiste(PompisteModel pompiste) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('pompistes', pompiste.toMap());
  }

  @override
  Future<void> updatePompiste(PompisteModel pompiste) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'pompistes',
      pompiste.toMap(),
      where: 'id = ?',
      whereArgs: [pompiste.id],
    );
  }

  @override
  Future<void> deletePompiste(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('pompistes', where: 'id = ?', whereArgs: [id]);
  }
}