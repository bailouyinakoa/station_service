import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:station_service_app/core/constants/app_colors.dart';
import 'package:station_service_app/core/routes/app_routes.dart';
import 'package:station_service_app/presentation/controllers/auth_controller.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Attendre un peu pour que le UI soit bien rendu
    await Future.delayed(const Duration(seconds: 1));

    // Vérifier la licence et restaurer la session
    // _restoreSession() est appelée dans onInit du AuthController
    // mais on la force ici aussi pour s'assurer que la vérification est faite
    await authController.refreshLicenseStatus();

    if (!mounted) return;

    // Si la licence est valide, la session va se restaurer automatiquement
    // et rediriger vers le dashboard ou l'onboarding
    if (authController.licenceValide.value) {
      // La redirection sera faite par _restoreSession() du AuthController
      // Attendre un peu pour laisser le temps à la restauration
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted && Get.currentRoute == AppRoutes.splash) {
        Get.offAllNamed(AppRoutes.onboardingUsers);
      }
      return;
    }

    // Si licence non valide, aller à la page de login
    if (mounted && Get.currentRoute == AppRoutes.splash) {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo avec animation de rotation
            RotationTransition(
              turns: _animationController,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 4),
                ),
                child: Center(
                  child: Icon(
                    Icons.local_gas_station,
                    size: 50,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Texte de chargement
            Text(
              'Vérification de la licence...',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Indicateur de progression
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
