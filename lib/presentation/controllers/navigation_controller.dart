import 'package:get/get.dart';

class NavigationController extends GetxController {
  final currentRoute = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    // Initialiser avec la route actuelle
    Future.microtask(() {
      currentRoute.value = Get.currentRoute;
    });
  }

  void navigateTo(String route) {
    if (route != Get.currentRoute) {
      // Mettre à jour immédiatement pour le feedback visuel
      currentRoute.value = route;
      Get.toNamed(route)?.then((_) {
        // Confirmer la mise à jour après la navigation
        currentRoute.value = Get.currentRoute;
      });
    }
  }
}
