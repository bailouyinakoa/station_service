import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:station_service_app/core/constants/app_colors.dart';
import 'package:station_service_app/presentation/controllers/onboarding_controller.dart';

class OnboardingCompletePage extends StatelessWidget {
  const OnboardingCompletePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final maxWidth = isMobile ? double.infinity : 600.0;
    final padding = isMobile ? 16.0 : 32.0;
    final controller = Get.find<OnboardingController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration Terminée'),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: SizedBox(
              width: maxWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  Icon(
                    Icons.check_circle_outline,
                    size: isMobile ? 80 : 100,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Configuration terminée',
                    style: TextStyle(
                      fontSize: isMobile ? 20 : 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Votre station est prête à être utilisée.',
                    style: TextStyle(fontSize: isMobile ? 14 : 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Summary of created elements
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.green.shade200,
                        width: 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 16 : 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Résumé de votre configuration',
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Divider(color: Colors.green.shade100, thickness: 1),
                          const SizedBox(height: 12),

                          // Station info
                          _buildSummaryItem(
                            context,
                            isMobile,
                            Icons.business,
                            'Station configurée',
                            controller.stationName.value.isNotEmpty
                                ? controller.stationName.value
                                : 'Non spécifié',
                          ),

                          // Fuels
                          _buildSummaryItem(
                            context,
                            isMobile,
                            Icons.local_gas_station,
                            'Carburants',
                            '${controller.addedFuels.length} configuré(s)',
                          ),

                          // Pumps
                          _buildSummaryItem(
                            context,
                            isMobile,
                            Icons.settings_input_component,
                            'Pompes',
                            '${controller.addedPumps.length} configurée(s)',
                          ),

                          // Products
                          _buildSummaryItem(
                            context,
                            isMobile,
                            Icons.shopping_bag,
                            'Produits',
                            '${controller.addedProducts.length} configuré(s)',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Next steps card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 16 : 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prochaines étapes',
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Divider(color: Colors.grey.shade200, thickness: 1),
                          const SizedBox(height: 12),

                          _buildNextStepItem(
                            context,
                            isMobile,
                            Icons.people,
                            'Gérer les pompistes',
                            'Ajoutez et gérez les employés de votre station',
                          ),

                          _buildNextStepItem(
                            context,
                            isMobile,
                            Icons.people_alt,
                            'Gérer les clients',
                            'Enregistrez vos clients réguliers pour un service personnalisé',
                          ),

                          _buildNextStepItem(
                            context,
                            isMobile,
                            Icons.receipt,
                            'Effectuer des ventes',
                            'Commencez à enregistrer les ventes de carburant et produits',
                          ),

                          _buildNextStepItem(
                            context,
                            isMobile,
                            Icons.analytics,
                            'Consulter les rapports',
                            'Suivez vos performances et générer des rapports détaillés',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16 : 24,
                            vertical: isMobile ? 12 : 16,
                          ),
                        ),
                        onPressed: controller.isLoading
                            ? null
                            : () async {
                                try {
                                  await controller.completeOnboarding();
                                } catch (e) {
                                  Get.snackbar(
                                    'Erreur',
                                    'Impossible de terminer la configuration: $e',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                }
                              },
                        child: controller.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Accéder au tableau de bord'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    bool isMobile,
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.green.shade700,
              size: isMobile ? 20 : 24,
            ),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepItem(
    BuildContext context,
    bool isMobile,
    IconData icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: isMobile ? 20 : 24,
            ),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
