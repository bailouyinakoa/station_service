import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:station_service_app/core/constants/app_strings.dart';
import 'package:station_service_app/data/models/fuel_model.dart';
import 'package:station_service_app/data/models/pompiste_model.dart';
import 'package:station_service_app/data/models/pump_model.dart';
import 'package:station_service_app/data/models/sales_product_model.dart';
import 'package:station_service_app/data/models/setting_model.dart';
import 'package:station_service_app/domain/entities/user.dart';
import 'package:station_service_app/presentation/controllers/auth_controller.dart';
import 'package:station_service_app/presentation/controllers/fuel_controller.dart';
import 'package:station_service_app/presentation/controllers/pompiste_controller.dart';
import 'package:station_service_app/presentation/controllers/pump_controller.dart';
import 'package:station_service_app/presentation/controllers/sales_product_controller.dart';
import 'package:station_service_app/presentation/controllers/settings_controller.dart';
import 'package:station_service_app/presentation/widgets/responsive_scaffold.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();
    final fuelController = Get.find<FuelController>();
    final pumpController = Get.find<PumpController>();
    final productController = Get.find<SalesProductController>();
    final pompisteController = Get.put(PompisteController());
    final authController = Get.find<AuthController>();

    return ResponsiveScaffold(
      title: AppStrings.settingsTitle,
      body: DefaultTabController(
        length: 7,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const TabBar(
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(icon: Icon(Icons.settings), text: 'Station'),
                  Tab(icon: Icon(Icons.local_gas_station), text: 'Carburants'),
                  Tab(icon: Icon(Icons.ev_station), text: 'Pompes'),
                  Tab(icon: Icon(Icons.shopping_bag), text: 'Produits'),
                  Tab(icon: Icon(Icons.person), text: 'Pompistes'),
                  Tab(icon: Icon(Icons.manage_accounts), text: 'Utilisateurs'),
                  Tab(icon: Icon(Icons.tune), text: 'Choix'),
                ],
              ),
            ),
            Expanded(
              child: PrimaryScrollController.none(
                child: TabBarView(
                  children: [
                    _buildStationSettings(controller),
                    _buildFuelSettings(fuelController),
                    _buildPumpSettings(pumpController, fuelController),
                    _buildProductSettings(productController),
                    _buildPompisteSettings(pompisteController),
                    _buildUserSwitcher(authController),
                    _buildChoiceSettings(controller),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationSettings(SettingsController controller) {
    final authController = Get.find<AuthController>();
    final stationController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    final adminEmailController = TextEditingController();
    final selectedExportPeriod = ExportPeriod.daily.obs;
    final selectedEmailPeriod = ExportPeriod.daily.obs;
    final selectedEmailDocument = EmailDocumentType.reportPdf.obs;

    return Obx(() {
      if (controller.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      final settings = controller.setting.value;
      stationController.text = settings?.stationName ?? '';
      addressController.text = settings?.stationAddress ?? '';
      phoneController.text = settings?.phone ?? '';
      adminEmailController.text = settings?.adminEmail ?? '';

      return SingleChildScrollView(
        primary: false,
        padding: const EdgeInsets.all(12),
        child: Card(
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildLicenseCard(authController),
                const SizedBox(height: 16),
                Obx(
                  () => SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: controller.stockNotificationsEnabled.value,
                    title: const Text('Notifications stock/licence'),
                    subtitle: const Text(
                      'Alerte a l ouverture puis rappel chaque heure.',
                    ),
                    onChanged: controller.setStockNotificationsEnabled,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade100, Colors.blue.shade200],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.business, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Informations de la station',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: stationController,
                  decoration: InputDecoration(
                    labelText: 'Nom de la station',
                    prefixIcon: Icon(Icons.store, color: Colors.blue.shade600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: InputDecoration(
                    labelText: 'Adresse',
                    prefixIcon: Icon(
                      Icons.location_on,
                      color: Colors.blue.shade600,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Téléphone',
                    prefixIcon: Icon(Icons.phone, color: Colors.blue.shade600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: adminEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email administrateur',
                    prefixIcon: Icon(
                      Icons.alternate_email,
                      color: Colors.blue.shade600,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade500, Colors.green.shade700],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      final model = SettingModel(
                        id: settings?.id,
                        stationName: stationController.text,
                        stationAddress: addressController.text,
                        phone: phoneController.text,
                        backupPath: settings?.backupPath ?? '',
                        adminEmail: adminEmailController.text,
                      );
                      controller.updateSettings(model);
                      Get.snackbar(
                        'Paramètres',
                        'Informations enregistrées',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.green.shade100,
                        colorText: Colors.green.shade800,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Sauvegarder',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildExcelExportCard(controller, selectedExportPeriod),
                const SizedBox(height: 12),
                _buildCloudBackupCard(controller, authController),
                const SizedBox(height: 12),
                _buildAdminEmailCard(
                  controller,
                  authController,
                  selectedEmailPeriod,
                  selectedEmailDocument,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showResetDatabaseDialog(controller),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Réinitialiser toute la base de données'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildCloudBackupCard(
    SettingsController controller,
    AuthController authController,
  ) {
    return Obx(() {
      final isBusy =
          controller.isCloudBackupRunning || controller.isCloudRestoreRunning;
      final deviceId = controller.cloudBackupDeviceId.value;
      final hasDeviceId = deviceId != null && deviceId.isNotEmpty;
      final lastBackup = controller.lastCloudBackupAt.value;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.cyan.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.cloud_sync_outlined,
                    color: Colors.cyan.shade800,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sauvegarde Firebase Storage',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasDeviceId
                            ? 'Derniere sauvegarde: ${_formatCloudBackupDate(lastBackup)}'
                            : 'Identifiant appareil indisponible.',
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: controller.cloudBackupEnabled.value,
              title: const Text('Sauvegarde automatique'),
              subtitle: const Text(
                'Envoie la base locale vers Firebase Storage avec l ID appareil.',
              ),
              onChanged: hasDeviceId && !isBusy
                  ? controller.setCloudBackupEnabled
                  : null,
            ),
            if (hasDeviceId) ...[
              const SizedBox(height: 4),
              SelectableText(
                'ID appareil: $deviceId',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isBusy || !hasDeviceId
                        ? null
                        : () async {
                            try {
                              final savedAt = await controller
                                  .backupToFirebaseNow();
                              Get.snackbar(
                                'Sauvegarde cloud terminee',
                                'Donnees envoyees a ${_formatCloudBackupDate(savedAt)}.',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.green.shade100,
                                colorText: Colors.green.shade800,
                              );
                            } catch (e) {
                              Get.snackbar(
                                'Sauvegarde impossible',
                                'Une erreur est survenue: $e',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.red.shade100,
                                colorText: Colors.red.shade800,
                              );
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.cyan.shade800,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: controller.isCloudBackupRunning
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.cloud_upload_outlined),
                    label: const Text('Sauvegarder maintenant'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isBusy || !hasDeviceId || !authController.isAdmin
                        ? null
                        : () => _showRestoreCloudDialog(
                            controller,
                            authController,
                          ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.cyan.shade900,
                      side: BorderSide(color: Colors.cyan.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: controller.isCloudRestoreRunning
                        ? SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.cyan.shade900,
                            ),
                          )
                        : const Icon(Icons.cloud_download_outlined),
                    label: Text(
                      authController.isAdmin ? 'Restaurer' : 'Reserve admin',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildExcelExportCard(
    SettingsController controller,
    Rx<ExportPeriod> selectedPeriod,
  ) {
    return Obx(() {
      final isExporting = controller.isExporting;
      final period = selectedPeriod.value;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.table_chart_outlined,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Exporter l\'historique Excel',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Journal d\'activité, ventes, dépenses, stock et données utiles.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ExportPeriod>(
                showSelectedIcon: false,
                segments: ExportPeriod.values.map((item) {
                  return ButtonSegment<ExportPeriod>(
                    value: item,
                    label: Text(item.label),
                  );
                }).toList(),
                selected: {period},
                onSelectionChanged: isExporting
                    ? null
                    : (selection) => selectedPeriod.value = selection.first,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isExporting
                    ? null
                    : () async {
                        try {
                          final outputPath = await controller.exportDataToExcel(
                            period: selectedPeriod.value,
                          );
                          Get.snackbar(
                            'Export Excel terminé',
                            'Fichier ${selectedPeriod.value.label.toLowerCase()} enregistré dans: $outputPath',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.green.shade100,
                            colorText: Colors.green.shade800,
                            duration: const Duration(seconds: 6),
                          );
                        } catch (e) {
                          Get.snackbar(
                            'Export impossible',
                            'Une erreur est survenue: $e',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red.shade100,
                            colorText: Colors.red.shade800,
                          );
                        }
                      },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: isExporting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download_rounded),
                label: Text('Créer le fichier ${period.label.toLowerCase()}'),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAdminEmailCard(
    SettingsController controller,
    AuthController authController,
    Rx<ExportPeriod> selectedPeriod,
    Rx<EmailDocumentType> selectedDocument,
  ) {
    return Obx(() {
      final isSending = controller.isSendingEmail;
      final period = selectedPeriod.value;
      final document = selectedDocument.value;
      final isAdmin = authController.isAdmin;
      final hasEmail =
          controller.setting.value?.adminEmail.trim().isNotEmpty == true;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.outgoing_mail,
                    color: Colors.indigo.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Envoyer a l\'administrateur',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Prépare un email avec le rapport ou le fichier Excel généré.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<EmailDocumentType>(
                showSelectedIcon: false,
                segments: EmailDocumentType.values.map((item) {
                  return ButtonSegment<EmailDocumentType>(
                    value: item,
                    label: Text(item.label),
                  );
                }).toList(),
                selected: {document},
                onSelectionChanged: isSending
                    ? null
                    : (selection) => selectedDocument.value = selection.first,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ExportPeriod>(
                showSelectedIcon: false,
                segments: ExportPeriod.values.map((item) {
                  return ButtonSegment<ExportPeriod>(
                    value: item,
                    label: Text(item.label),
                  );
                }).toList(),
                selected: {period},
                onSelectionChanged: isSending
                    ? null
                    : (selection) => selectedPeriod.value = selection.first,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isSending || !hasEmail || !isAdmin
                    ? null
                    : () async {
                        if (!authController.requireAdmin(
                          message:
                              'Seul l\'administrateur peut envoyer les rapports par email.',
                        )) {
                          return;
                        }
                        try {
                          final outputPath = await controller.prepareAdminEmail(
                            documentType: selectedDocument.value,
                            period: selectedPeriod.value,
                          );
                          Get.snackbar(
                            'Email préparé',
                            'Fichier généré: $outputPath',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.green.shade100,
                            colorText: Colors.green.shade800,
                            duration: const Duration(seconds: 6),
                          );
                        } catch (e) {
                          Get.snackbar(
                            'Envoi impossible',
                            'Une erreur est survenue: $e',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red.shade100,
                            colorText: Colors.red.shade800,
                          );
                        }
                      },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.indigo.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: isSending
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.email_outlined),
                label: Text(
                  !isAdmin
                      ? 'Réservé à l\'administrateur'
                      : hasEmail
                      ? 'Préparer l\'email ${period.label.toLowerCase()}'
                      : 'Renseigner l\'email administrateur',
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLicenseCard(AuthController authController) {
    return Obx(() {
      final isValid = authController.licenceValide.value;
      final remainingDays = authController.joursRestants.value;
      final lastRefresh = authController.lastLicenseRefresh.value;
      final isCritical = !isValid || remainingDays <= 1;
      final isWarning = isValid && remainingDays < 5 && remainingDays > 1;
      final fg = isCritical
          ? const Color(0xFFB91C1C)
          : isWarning
          ? const Color(0xFFC2410C)
          : const Color(0xFF166534);
      final bg = isCritical
          ? const Color(0xFFFEF2F2)
          : isWarning
          ? const Color(0xFFFFF7ED)
          : const Color(0xFFF0FDF4);
      final statusText = isCritical
          ? 'Statut : licence critique'
          : isWarning
          ? 'Statut : licence à renouveler bientôt'
          : 'Statut : licence active';
      final statusIcon = isCritical
          ? Icons.error_outline
          : isWarning
          ? Icons.warning_amber_rounded
          : Icons.verified_outlined;
      final contactNumbers = ['+226 66 93 41 91'];

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bg, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: fg.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: fg.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: fg.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(statusIcon, color: fg),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informations de licence',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: fg,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Mise a jour chaque minute',
                        style: TextStyle(
                          fontSize: 12,
                          color: fg.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: fg.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    _licenseRefreshLabel(lastRefresh),
                    style: TextStyle(
                      color: fg,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _licenseInfoTile(
                  label: 'Statut',
                  value: statusText.replaceFirst('Statut : ', ''),
                  icon: statusIcon,
                  color: fg,
                ),
                _licenseInfoTile(
                  label: 'Expiration',
                  value: authController.expirationDateLabel,
                  icon: Icons.event_available_outlined,
                  color: fg,
                ),
                _licenseInfoTile(
                  label: 'Temps restant',
                  value: authController.remainingTimeLabel,
                  icon: Icons.timer_outlined,
                  color: fg,
                ),
                _licenseInfoTile(
                  label: 'Jours restants',
                  value: '${authController.joursRestants.value}',
                  icon: Icons.today_outlined,
                  color: fg,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: fg.withValues(alpha: 0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.support_agent_outlined, color: fg, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Contacts assistance',
                        style: TextStyle(
                          color: fg,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: contactNumbers
                        .map((number) => _licenseContactChip(number, fg))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  String _licenseRefreshLabel(DateTime? value) {
    if (value == null) return 'Actualisation...';
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Widget _licenseInfoTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.72),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _licenseContactChip(String number, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.phone_outlined, color: color, size: 16),
          const SizedBox(width: 8),
          SelectableText(
            number,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showResetDatabaseDialog(SettingsController controller) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmation requise'),
        content: const Text(
          'Cette action va supprimer toutes les données et restaurer les valeurs initiales. Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final passwordController = TextEditingController();
    final password = await Get.dialog<String>(
      AlertDialog(
        title: const Text('Mot de passe administrateur'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Mot de passe admin'),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Get.back(result: passwordController.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Valider'),
          ),
        ],
      ),
    );

    if (password == null || password.isEmpty) return;

    final success = await controller.resetAllData(password);
    if (success) {
      Get.snackbar(
        'Réinitialisation réussie',
        'Toutes les données ont été remises à zéro.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
      return;
    }

    Get.snackbar(
      'Accès refusé',
      'Mot de passe administrateur incorrect.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
    );
  }

  Future<void> _showRestoreCloudDialog(
    SettingsController controller,
    AuthController authController,
  ) async {
    if (!authController.requireAdmin(
      message:
          'Seul l administrateur peut restaurer les donnees depuis le cloud.',
    )) {
      return;
    }

    try {
      final info = await controller.fetchCloudBackupInfo();
      if (!info.exists) {
        Get.snackbar(
          'Sauvegarde introuvable',
          'Aucune sauvegarde Firebase Storage ne correspond a cet appareil.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade100,
          colorText: Colors.orange.shade900,
        );
        return;
      }

      final confirm = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Restaurer depuis Firebase ?'),
          content: Text(
            'Cette action va remplacer les donnees actuelles par la sauvegarde cloud du ${_formatCloudBackupDate(info.updatedAt)}. Une copie locale de securite sera creee avant restauration.',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Restaurer'),
            ),
          ],
        ),
      );
      if (confirm != true) return;

      final result = await controller.restoreFromFirebase();
      Get.snackbar(
        'Restauration terminee',
        result.safetyCopyPath == null
            ? 'Les donnees cloud ont ete restaurees.'
            : 'Les donnees cloud ont ete restaurees. Copie de securite: ${result.safetyCopyPath}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        duration: const Duration(seconds: 7),
      );
    } catch (e) {
      Get.snackbar(
        'Restauration impossible',
        'Une erreur est survenue: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  String _formatCloudBackupDate(DateTime? value) {
    if (value == null) return 'jamais';
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  Widget _buildUserSwitcher(AuthController authController) {
    return FutureBuilder<void>(
      future: authController.loadUsers(),
      builder: (context, snapshot) {
        return Obx(() {
          final currentUser = authController.user;
          final users = authController.users;

          if (snapshot.connectionState == ConnectionState.waiting &&
              users.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: authController.loadUsers,
            child: ListView(
              primary: false,
              padding: const EdgeInsets.all(12),
              children: [
                Card(
                  elevation: 0.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.indigo.shade100,
                                Colors.indigo.shade200,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.manage_accounts,
                                color: Colors.indigo.shade700,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Navigation entre utilisateurs',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo.shade700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Actualiser',
                                onPressed: authController.loadUsers,
                                icon: const Icon(Icons.refresh),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildCurrentUserCard(currentUser),
                        const SizedBox(height: 16),
                        _buildCreateAgentEntry(authController),
                        const SizedBox(height: 16),
                        if (users.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text('Aucun utilisateur trouvé.'),
                            ),
                          )
                        else
                          ...users.map(
                            (user) => _buildSwitchUserTile(
                              authController: authController,
                              user: user,
                              isCurrent: currentUser?.id == user.id,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _buildCreateAgentEntry(AuthController authController) {
    final canCreate = authController.isAdmin;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: canCreate ? Colors.indigo.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canCreate ? Colors.indigo.shade100 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person_add_alt_1,
            color: canCreate ? Colors.indigo.shade700 : Colors.grey.shade600,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ajouter un compte agent',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: canCreate
                        ? Colors.indigo.shade700
                        : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  canCreate
                      ? 'Créer un compte gérant ou caissier.'
                      : 'Réservé au mode administrateur.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: canCreate
                ? () => _showCreateAgentDialog(authController)
                : null,
            icon: const Icon(Icons.add),
            label: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateAgentDialog(AuthController authController) async {
    if (!authController.requireAdmin(
      message: 'Seul l\'administrateur peut créer un compte agent.',
    )) {
      return;
    }

    final nameController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final role = 'gerant'.obs;

    final created = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Nouveau compte agent'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Identifiant',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 12),
              Obx(
                () => DropdownButtonFormField<String>(
                  initialValue: role.value,
                  decoration: const InputDecoration(
                    labelText: 'Rôle',
                    prefixIcon: Icon(Icons.manage_accounts_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'gerant', child: Text('Gérant')),
                    DropdownMenuItem(
                      value: 'caissier',
                      child: Text('Caissier'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) role.value = value;
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          Obx(
            () => FilledButton(
              onPressed: authController.isLoading
                  ? null
                  : () async {
                      final success = await authController.createAgentUser(
                        name: nameController.text,
                        username: usernameController.text,
                        password: passwordController.text,
                        role: role.value,
                      );
                      if (success) {
                        Get.back(result: true);
                        return;
                      }
                      Get.snackbar(
                        'Compte non créé',
                        authController.error,
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.red.shade100,
                        colorText: Colors.red.shade800,
                      );
                    },
              child: authController.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Créer'),
            ),
          ),
        ],
      ),
    );

    nameController.dispose();
    usernameController.dispose();
    passwordController.dispose();

    if (created == true) {
      Get.snackbar(
        'Compte créé',
        'Le nouveau compte agent est disponible.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
    }
  }

  Widget _buildCurrentUserCard(User? currentUser) {
    final roleColor = _userRoleColor(currentUser?.role);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: roleColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: roleColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: roleColor.withValues(alpha: 0.14),
            foregroundColor: roleColor,
            child: Icon(_userRoleIcon(currentUser?.role)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentUser?.name ?? 'Aucun utilisateur actif',
                  style: TextStyle(
                    color: roleColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  currentUser == null
                      ? 'Session non connectée'
                      : '${_userRoleLabel(currentUser.role)} • ${currentUser.username}',
                  style: TextStyle(
                    color: roleColor.withValues(alpha: 0.76),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchUserTile({
    required AuthController authController,
    required User user,
    required bool isCurrent,
  }) {
    final roleColor = _userRoleColor(user.role);
    final actionLabel = user.role == 'admin'
        ? 'Passer en mode admin'
        : 'Changer vers ce gérant';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? roleColor.withValues(alpha: 0.5)
              : Colors.grey.shade300,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: roleColor.withValues(alpha: 0.12),
          foregroundColor: roleColor,
          child: Icon(_userRoleIcon(user.role)),
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${_userRoleLabel(user.role)} • ${user.username}',
          overflow: TextOverflow.ellipsis,
        ),
        trailing: isCurrent
            ? Chip(
                label: const Text('Actif'),
                visualDensity: VisualDensity.compact,
                backgroundColor: roleColor.withValues(alpha: 0.1),
                labelStyle: TextStyle(
                  color: roleColor,
                  fontWeight: FontWeight.w700,
                ),
              )
            : IconButton.filled(
                tooltip: actionLabel,
                onPressed: authController.isLoading
                    ? null
                    : () => _showSwitchUserDialog(authController, user),
                icon: const Icon(Icons.login),
              ),
      ),
    );
  }

  Future<void> _showSwitchUserDialog(
    AuthController authController,
    User user,
  ) async {
    final passwordController = TextEditingController();
    final password = await Get.dialog<String>(
      AlertDialog(
        title: Text(user.role == 'admin' ? 'Mode admin' : 'Changer de gérant'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Mot de passe de ${user.name}',
            prefixIcon: const Icon(Icons.lock_outline),
          ),
          onSubmitted: (value) => Get.back(result: value.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Get.back(result: passwordController.text.trim()),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    passwordController.dispose();

    if (password == null || password.isEmpty) return;

    final success = await authController.switchUser(
      userId: user.id,
      password: password,
    );

    if (success) {
      Get.snackbar(
        'Utilisateur changé',
        '${user.name} est maintenant actif.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
      );
      return;
    }

    Get.snackbar(
      'Accès refusé',
      'Mot de passe incorrect.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade800,
    );
  }

  String _userRoleLabel(String? role) {
    switch (role) {
      case 'admin':
        return 'Administrateur';
      case 'gerant':
        return 'Gérant';
      case 'caissier':
        return 'Caissier';
      default:
        return 'Utilisateur';
    }
  }

  IconData _userRoleIcon(String? role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'gerant':
        return Icons.manage_accounts;
      case 'caissier':
        return Icons.point_of_sale;
      default:
        return Icons.person;
    }
  }

  Color _userRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return Colors.indigo.shade700;
      case 'gerant':
        return Colors.teal.shade700;
      case 'caissier':
        return Colors.orange.shade700;
      default:
        return Colors.blueGrey.shade700;
    }
  }

  Widget _buildFuelSettings(FuelController controller) {
    final authController = Get.find<AuthController>();
    final nameController = TextEditingController();
    final supplierController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final thresholdController = TextEditingController();

    return Obx(() {
      return SingleChildScrollView(
        primary: false,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Card(
              elevation: .5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.shade100,
                            Colors.orange.shade200,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.add, color: Colors.orange.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Ajouter un carburant',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nom du carburant',
                        prefixIcon: Icon(
                          Icons.local_gas_station,
                          color: Colors.orange.shade600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: supplierController,
                      decoration: InputDecoration(
                        labelText: 'Fournisseur',
                        prefixIcon: Icon(
                          Icons.local_shipping,
                          color: Colors.orange.shade600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      decoration: InputDecoration(
                        labelText: 'Prix par litre',
                        prefixIcon: Icon(
                          Icons.euro,
                          color: Colors.orange.shade600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: stockController,
                      decoration: InputDecoration(
                        labelText: 'Stock initial (litres)',
                        prefixIcon: Icon(
                          Icons.inventory,
                          color: Colors.orange.shade600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: thresholdController,
                      decoration: InputDecoration(
                        labelText: 'Seuil d\'alerte (litres)',
                        prefixIcon: Icon(
                          Icons.warning,
                          color: Colors.orange.shade600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      height: 45,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.shade500,
                            Colors.orange.shade700,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ElevatedButton(
                        onPressed: authController.isAdmin
                            ? () {
                                if (nameController.text.isEmpty ||
                                    supplierController.text.isEmpty ||
                                    priceController.text.isEmpty ||
                                    stockController.text.isEmpty ||
                                    thresholdController.text.isEmpty) {
                                  Get.snackbar(
                                    'Erreur',
                                    'Veuillez remplir tous les champs',
                                  );
                                  return;
                                }

                                final fuel = FuelModel(
                                  name: nameController.text,
                                  supplier: supplierController.text.trim(),
                                  pricePerLiter: double.parse(
                                    priceController.text,
                                  ),
                                  stockLiters: double.parse(
                                    stockController.text,
                                  ),
                                  lowStockThreshold: double.parse(
                                    thresholdController.text,
                                  ),
                                  id: 0,
                                );

                                controller.addFuel(fuel);
                                nameController.clear();
                                supplierController.clear();
                                priceController.clear();
                                stockController.clear();
                                thresholdController.clear();

                                Get.snackbar(
                                  'Succès',
                                  'Carburant ajouté',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.green.shade100,
                                  colorText: Colors.green.shade800,
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Ajouter'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: .5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.shade100,
                            Colors.orange.shade200,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.list, color: Colors.orange.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Carburants existants',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (controller.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      ListView.builder(
                        primary: false,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.fuels.length,
                        itemBuilder: (context, index) {
                          final fuel = controller.fuels[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.orange.shade400,
                                      Colors.orange.shade600,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.local_gas_station,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(fuel.name),
                              subtitle: Text(
                                '${fuel.supplier} • ${fuel.pricePerLiter.toStringAsFixed(2)} €/L • Stock: ${fuel.stockLiters.toStringAsFixed(0)} L',
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color: Colors.red.shade400,
                                ),
                                onPressed: () {
                                  Get.dialog(
                                    AlertDialog(
                                      title: const Text('Supprimer'),
                                      content: Text('Supprimer ${fuel.name} ?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Get.back(),
                                          child: const Text('Annuler'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            controller.deleteFuel(fuel.id);
                                            Get.back();
                                            Get.snackbar(
                                              'Succès',
                                              'Carburant supprimé',
                                              backgroundColor:
                                                  Colors.green.shade100,
                                              colorText: Colors.green.shade800,
                                            );
                                          },
                                          child: const Text('Supprimer'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPumpSettings(
    PumpController pumpController,
    FuelController fuelController,
  ) {
    final authController = Get.find<AuthController>();
    final nameController = TextEditingController();
    final selectedFuelId = Rx<String?>(null);

    return Obx(() {
      return SingleChildScrollView(
        primary: false,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Card(
              elevation: .5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade100,
                            Colors.purple.shade200,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.add, color: Colors.purple.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Ajouter une pompe',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nom de la pompe',
                        prefixIcon: Icon(
                          Icons.ev_station,
                          color: Colors.purple.shade600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Obx(() {
                      if (fuelController.isLoading) {
                        return const CircularProgressIndicator();
                      }
                      return DropdownButtonFormField<String>(
                        initialValue: selectedFuelId.value,
                        decoration: InputDecoration(
                          labelText: 'Carburant',
                          prefixIcon: Icon(
                            Icons.local_gas_station,
                            color: Colors.purple.shade600,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: fuelController.fuels.map((fuel) {
                          return DropdownMenuItem(
                            value: fuel.id.toString(),
                            child: Text(fuel.name),
                          );
                        }).toList(),
                        onChanged: (value) => selectedFuelId.value = value,
                      );
                    }),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      height: 45,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade500,
                            Colors.purple.shade700,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ElevatedButton(
                        onPressed: authController.isAdmin
                            ? () {
                                if (nameController.text.isEmpty ||
                                    selectedFuelId.value == null) {
                                  Get.snackbar(
                                    'Erreur',
                                    'Veuillez remplir tous les champs',
                                  );
                                  return;
                                }

                                final pump = PumpModel(
                                  id: 0,
                                  name: nameController.text,
                                  fuelId: int.parse(selectedFuelId.value!),
                                  status: 'active',
                                  meterReading: 0,
                                  fuelName: '',
                                );

                                pumpController.addPump(pump);
                                nameController.clear();
                                selectedFuelId.value = null;

                                Get.snackbar(
                                  'Succès',
                                  'Pompe ajoutée',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.green.shade100,
                                  colorText: Colors.green.shade800,
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Ajouter'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: .5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade100,
                            Colors.purple.shade200,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.list, color: Colors.purple.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Pompes existantes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (pumpController.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      ListView.builder(
                        primary: false,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: pumpController.pumps.length,
                        itemBuilder: (context, index) {
                          final pump = pumpController.pumps[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: pump.status == 'active'
                                        ? [
                                            Colors.green.shade400,
                                            Colors.green.shade600,
                                          ]
                                        : [
                                            Colors.red.shade400,
                                            Colors.red.shade600,
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.ev_station,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(pump.name),
                              subtitle: Text(
                                '${pump.fuelName} • ${pump.status == 'active' ? 'Active' : 'Inactive'} • ${pump.meterReading.toStringAsFixed(1)} L',
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color: Colors.red.shade400,
                                ),
                                onPressed: () {
                                  Get.dialog(
                                    AlertDialog(
                                      title: const Text('Supprimer'),
                                      content: Text('Supprimer ${pump.name} ?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Get.back(),
                                          child: const Text('Annuler'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            pumpController.deletePump(pump.id);
                                            Get.back();
                                            Get.snackbar(
                                              'Succès',
                                              'Pompe supprimée',
                                              backgroundColor:
                                                  Colors.green.shade100,
                                              colorText: Colors.green.shade800,
                                            );
                                          },
                                          child: const Text('Supprimer'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPompisteSettings(PompisteController controller) {
    final authController = Get.find<AuthController>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    return Obx(() {
      return SingleChildScrollView(
        primary: false,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: .5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade100, Colors.teal.shade200],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.add, color: Colors.teal.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Ajouter un pompiste',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nom complet',
                        prefixIcon: Icon(
                          Icons.person,
                          color: Colors.teal.shade600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        labelText: 'Téléphone',
                        prefixIcon: Icon(
                          Icons.phone,
                          color: Colors.teal.shade600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      decoration: InputDecoration(
                        labelText: 'Adresse',
                        prefixIcon: Icon(
                          Icons.home,
                          color: Colors.teal.shade600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      height: 45,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade500, Colors.teal.shade700],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ElevatedButton(
                        onPressed: authController.isAdmin
                            ? () {
                                if (nameController.text.isEmpty) {
                                  Get.snackbar(
                                    'Erreur',
                                    'Le nom est obligatoire',
                                  );
                                  return;
                                }

                                final pompiste = PompisteModel(
                                  id: 0,
                                  name: nameController.text,
                                  phone: phoneController.text.isEmpty
                                      ? null
                                      : phoneController.text,
                                  address: addressController.text.isEmpty
                                      ? null
                                      : addressController.text,
                                  hireDate: DateTime.now().toIso8601String(),
                                  status: 'active',
                                );

                                controller.addPompiste(pompiste);
                                nameController.clear();
                                phoneController.clear();
                                addressController.clear();

                                Get.snackbar(
                                  'Succès',
                                  'Pompiste ajouté',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.green.shade100,
                                  colorText: Colors.green.shade800,
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Ajouter'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: .5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade100, Colors.teal.shade200],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.list, color: Colors.teal.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Pompistes existants',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (controller.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      ListView.builder(
                        primary: false,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.pompistes.length,
                        itemBuilder: (context, index) {
                          final pompiste = controller.pompistes[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: pompiste.status == 'active'
                                        ? [
                                            Colors.teal.shade400,
                                            Colors.teal.shade600,
                                          ]
                                        : [
                                            Colors.grey.shade400,
                                            Colors.grey.shade600,
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(pompiste.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (pompiste.phone != null)
                                    Text('📞 ${pompiste.phone}'),
                                  if (pompiste.address != null)
                                    Text('🏠 ${pompiste.address}'),
                                  Text(
                                    'Statut: ${pompiste.status == 'active' ? 'Actif' : 'Inactif'}',
                                    style: TextStyle(
                                      color: pompiste.status == 'active'
                                          ? Colors.green.shade600
                                          : Colors.red.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color: Colors.red.shade400,
                                ),
                                onPressed: () {
                                  Get.dialog(
                                    AlertDialog(
                                      title: const Text('Supprimer'),
                                      content: Text(
                                        'Supprimer ${pompiste.name} ?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Get.back(),
                                          child: const Text('Annuler'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            controller.deletePompiste(
                                              pompiste.id,
                                            );
                                            Get.back();
                                            Get.snackbar(
                                              'Succès',
                                              'Pompiste supprimé',
                                              backgroundColor:
                                                  Colors.green.shade100,
                                              colorText: Colors.green.shade800,
                                            );
                                          },
                                          child: const Text('Supprimer'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildProductSettings(SalesProductController controller) {
    final authController = Get.find<AuthController>();
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final unitPriceController = TextEditingController();
    final stockController = TextEditingController();
    final thresholdController = TextEditingController();

    return Obx(() {
      return SingleChildScrollView(
        primary: false,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: .5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.indigo.shade100,
                            Colors.indigo.shade200,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.add_box, color: Colors.indigo.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Ajouter un produit de vente',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo.shade700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nom du produit (ex: huile 1L)',
                        prefixIcon: Icon(
                          Icons.shopping_bag,
                          color: Colors.indigo.shade600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: categoryController,
                      decoration: InputDecoration(
                        labelText: 'Catégorie (ex: Huile, Gaz, Accessoires)',
                        prefixIcon: Icon(
                          Icons.category,
                          color: Colors.indigo.shade600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: unitPriceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Prix unitaire',
                        prefixIcon: Icon(
                          Icons.payments,
                          color: Colors.indigo.shade600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: stockController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Stock initial',
                        prefixIcon: Icon(
                          Icons.inventory_2,
                          color: Colors.indigo.shade600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: thresholdController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Seuil d\'alerte',
                        prefixIcon: Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.indigo.shade600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: authController.isAdmin
                            ? () async {
                                if (nameController.text.isEmpty ||
                                    categoryController.text.isEmpty ||
                                    unitPriceController.text.isEmpty ||
                                    stockController.text.isEmpty ||
                                    thresholdController.text.isEmpty) {
                                  Get.snackbar(
                                    'Erreur',
                                    'Veuillez remplir tous les champs',
                                  );
                                  return;
                                }
                                final unitPrice = double.tryParse(
                                  unitPriceController.text,
                                );
                                final stock = double.tryParse(
                                  stockController.text,
                                );
                                final threshold = double.tryParse(
                                  thresholdController.text,
                                );
                                if (unitPrice == null ||
                                    stock == null ||
                                    threshold == null ||
                                    unitPrice <= 0 ||
                                    stock < 0 ||
                                    threshold < 0) {
                                  Get.snackbar(
                                    'Erreur',
                                    'Prix/stock invalides',
                                  );
                                  return;
                                }
                                await controller.addProduct(
                                  SalesProductModel(
                                    id: 0,
                                    name: nameController.text.trim(),
                                    category: categoryController.text.trim(),
                                    unitPrice: unitPrice,
                                    stockQuantity: stock,
                                    lowStockThreshold: threshold,
                                  ),
                                );
                                nameController.clear();
                                categoryController.clear();
                                unitPriceController.clear();
                                stockController.clear();
                                thresholdController.clear();
                                Get.snackbar('Succès', 'Produit ajouté');
                              }
                            : null,
                        child: const Text('Ajouter le produit'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: .5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.indigo.shade100,
                            Colors.indigo.shade200,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.list_alt, color: Colors.indigo.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Produits existants',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo.shade700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (controller.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (controller.products.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Aucun produit enregistré.'),
                      )
                    else
                      ListView.builder(
                        primary: false,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.products.length,
                        itemBuilder: (context, index) {
                          final product = controller.products[index];
                          return ListTile(
                            title: Text(product.name),
                            subtitle: Text(
                              '${product.category} • ${product.unitPrice.toStringAsFixed(2)} €/u • '
                              'Stock: ${product.stockQuantity.toStringAsFixed(0)} • '
                              'Seuil: ${product.lowStockThreshold.toStringAsFixed(0)}',
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: Colors.red.shade400,
                              ),
                              onPressed: () =>
                                  controller.deleteProduct(product.id),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildChoiceSettings(SettingsController controller) {
    final paymentController = TextEditingController();
    return Obx(() {
      return ListView(
        primary: false,
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: .5,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Types de paiement',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: paymentController,
                    decoration: const InputDecoration(
                      labelText: 'Nouveau type de paiement',
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () async {
                      await controller.addChoiceOption(
                        type: 'payment_type',
                        value: paymentController.text,
                      );
                      paymentController.clear();
                    },
                    child: const Text('Ajouter'),
                  ),
                  const SizedBox(height: 8),
                  ...controller.paymentTypes.map((item) {
                    return ListTile(
                      dense: true,
                      title: Text('${item['value']}'),
                      trailing: IconButton(
                        onPressed: () =>
                            controller.deleteChoiceOption(item['id'] as int),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}
