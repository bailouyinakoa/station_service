import 'package:get/get.dart';
import 'package:station_service_app/data/models/pompiste_model.dart';
import 'package:station_service_app/data/repositories/pompiste_repository_impl.dart';
import 'package:station_service_app/presentation/controllers/auth_controller.dart';

class PompisteController extends GetxController {
  final pompistes = <PompisteModel>[].obs;
  final _isLoading = false.obs;

  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    fetchPompistes();
  }

  Future<void> fetchPompistes() async {
    _isLoading.value = true;
    final repository = PompisteRepositoryImpl();
    pompistes.value = await repository.getPompistes();
    _isLoading.value = false;
  }

  Future<void> addPompiste(PompisteModel pompiste) async {
    if (!Get.find<AuthController>().requireAdmin(
      message: 'Seul l\'administrateur peut ajouter un pompiste.',
    )) {
      return;
    }
    final repository = PompisteRepositoryImpl();
    await repository.addPompiste(pompiste);
    await fetchPompistes();
  }

  Future<void> updatePompiste(PompisteModel pompiste) async {
    final repository = PompisteRepositoryImpl();
    await repository.updatePompiste(pompiste);
    await fetchPompistes();
  }

  Future<void> deletePompiste(int id) async {
    final repository = PompisteRepositoryImpl();
    await repository.deletePompiste(id);
    await fetchPompistes();
  }
}
