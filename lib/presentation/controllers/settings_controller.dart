import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:sqflite/sqflite.dart';
import 'package:station_service_app/core/database/database_helper.dart';
import 'package:station_service_app/core/utils/formatters.dart';
import 'package:station_service_app/data/models/report_summary_model.dart';
import 'package:station_service_app/data/models/setting_model.dart';
import 'package:station_service_app/presentation/controllers/accounting_controller.dart';
import 'package:station_service_app/presentation/controllers/client_controller.dart';
import 'package:station_service_app/presentation/controllers/dashboard_controller.dart';
import 'package:station_service_app/presentation/controllers/expense_controller.dart';
import 'package:station_service_app/presentation/controllers/fuel_controller.dart';
import 'package:station_service_app/presentation/controllers/pompiste_controller.dart';
import 'package:station_service_app/presentation/controllers/pump_controller.dart';
import 'package:station_service_app/presentation/controllers/report_controller.dart';
import 'package:station_service_app/presentation/controllers/sale_controller.dart';
import 'package:station_service_app/presentation/controllers/sales_product_controller.dart';
import 'package:station_service_app/presentation/controllers/stock_controller.dart';
import 'package:station_service_app/presentation/controllers/supplier_controller.dart';
import 'package:station_service_app/services/alert_monitoring_service.dart';
import 'package:station_service_app/services/cloud_backup_service.dart';

enum ExportPeriod {
  daily,
  monthly,
  yearly;

  String get label {
    switch (this) {
      case ExportPeriod.daily:
        return 'Journalier';
      case ExportPeriod.monthly:
        return 'Mensuel';
      case ExportPeriod.yearly:
        return 'Annuel';
    }
  }

  String get fileLabel {
    switch (this) {
      case ExportPeriod.daily:
        return 'journalier';
      case ExportPeriod.monthly:
        return 'mensuel';
      case ExportPeriod.yearly:
        return 'annuel';
    }
  }
}

enum EmailDocumentType {
  reportPdf,
  excelFile;

  String get label {
    switch (this) {
      case EmailDocumentType.reportPdf:
        return 'Rapport PDF';
      case EmailDocumentType.excelFile:
        return 'Fichier Excel';
    }
  }
}

class _ExportWindow {
  const _ExportWindow({
    required this.start,
    required this.end,
    required this.title,
  });

  final DateTime start;
  final DateTime end;
  final String title;

  List<String> get args => [_formatDate(start), _formatDate(end)];

  static String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
  }
}

class SettingsController extends GetxController {
  final setting = Rxn<SettingModel>();
  final paymentTypes = <Map<String, Object?>>[].obs;
  final _isLoading = false.obs;
  final _isExporting = false.obs;
  final _isSendingEmail = false.obs;
  final _isCloudBackupRunning = false.obs;
  final _isCloudRestoreRunning = false.obs;
  final stockNotificationsEnabled = true.obs;
  final cloudBackupEnabled = true.obs;
  final lastCloudBackupAt = Rxn<DateTime>();
  final cloudBackupDeviceId = Rxn<String>();

  bool get isLoading => _isLoading.value;
  bool get isExporting => _isExporting.value;
  bool get isSendingEmail => _isSendingEmail.value;
  bool get isCloudBackupRunning => _isCloudBackupRunning.value;
  bool get isCloudRestoreRunning => _isCloudRestoreRunning.value;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  Future<void> loadSettings() async {
    _isLoading.value = true;
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('settings', limit: 1);
    if (rows.isNotEmpty) {
      setting.value = SettingModel.fromMap(rows.first);
    }
    stockNotificationsEnabled.value = await AlertMonitoringService.instance
        .areNotificationsEnabled();
    cloudBackupEnabled.value = await CloudBackupService.instance
        .isAutoBackupEnabled();
    try {
      cloudBackupDeviceId.value = await CloudBackupService.instance
          .getBackupDeviceId();
    } catch (_) {
      cloudBackupDeviceId.value = null;
    }
    lastCloudBackupAt.value = await CloudBackupService.instance
        .getLastBackupAt();
    paymentTypes.value = await db.query(
      'choice_options',
      where: 'type = ?',
      whereArgs: ['payment_type'],
      orderBy: 'value ASC',
    );
    _isLoading.value = false;
  }

  Future<void> setStockNotificationsEnabled(bool enabled) async {
    stockNotificationsEnabled.value = enabled;
    await AlertMonitoringService.instance.setNotificationsEnabled(enabled);
    if (enabled) {
      await AlertMonitoringService.instance.runAlertChecks(force: true);
    }
  }

  Future<void> setCloudBackupEnabled(bool enabled) async {
    cloudBackupEnabled.value = enabled;
    await CloudBackupService.instance.setAutoBackupEnabled(enabled);
    if (enabled) {
      await CloudBackupService.instance.backupIfDue();
      lastCloudBackupAt.value = await CloudBackupService.instance
          .getLastBackupAt();
    }
  }

  Future<void> addChoiceOption({
    required String type,
    required String value,
  }) async {
    final normalized = value.trim();
    if (normalized.isEmpty) return;
    final db = await DatabaseHelper.instance.database;
    final exists = await db.query(
      'choice_options',
      where: 'type = ? AND lower(value) = ?',
      whereArgs: [type, normalized.toLowerCase()],
      limit: 1,
    );
    if (exists.isEmpty) {
      await db.insert('choice_options', {'type': type, 'value': normalized});
    }
    await loadSettings();
  }

  Future<void> deleteChoiceOption(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('choice_options', where: 'id = ?', whereArgs: [id]);
    await loadSettings();
  }

  Future<void> updateSettings(SettingModel newSettings) async {
    final db = await DatabaseHelper.instance.database;
    if (setting.value?.id != null) {
      await db.update(
        'settings',
        newSettings.toMap(),
        where: 'id = ?',
        whereArgs: [newSettings.id],
      );
    } else {
      await db.insert('settings', newSettings.toMap());
    }
    setting.value = newSettings;
  }

  Future<DateTime> backupToFirebaseNow() async {
    _isCloudBackupRunning.value = true;
    try {
      final savedAt = await CloudBackupService.instance.backupNow();
      lastCloudBackupAt.value = savedAt;
      return savedAt;
    } finally {
      _isCloudBackupRunning.value = false;
    }
  }

  Future<CloudBackupInfo> fetchCloudBackupInfo() async {
    return CloudBackupService.instance.fetchBackupInfo();
  }

  Future<CloudRestoreResult> restoreFromFirebase() async {
    _isCloudRestoreRunning.value = true;
    try {
      final result = await CloudBackupService.instance.restoreFromCloud();
      await loadSettings();
      await _refreshRegisteredControllers();
      return result;
    } finally {
      _isCloudRestoreRunning.value = false;
    }
  }

  Future<bool> verifyAdminPassword(String password) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'users',
      columns: ['id'],
      where: 'role = ? AND password = ?',
      whereArgs: ['admin', password],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<bool> resetAllData(String adminPassword) async {
    final validPassword = await verifyAdminPassword(adminPassword);
    if (!validPassword) return false;

    _isLoading.value = true;
    try {
      await DatabaseHelper.instance.resetDatabase();
      await loadSettings();
      await _refreshRegisteredControllers();
      return true;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<String> exportDataToExcel({
    ExportPeriod period = ExportPeriod.daily,
  }) async {
    _isExporting.value = true;
    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now();
      final window = _buildExportWindow(period, now);
      final exportName =
          'historique-station-${period.fileLabel}-${DateFormat('yyyyMMdd-HHmmss').format(now)}.xlsx';

      final workbook = Excel.createExcel();
      final defaultSheet = workbook.getDefaultSheet();
      if (defaultSheet != null) {
        workbook.delete(defaultSheet);
      }

      _writeSheet(workbook, 'Resume', [
        {
          'periode': period.label,
          'debut': DateFormat('dd/MM/yyyy HH:mm').format(window.start),
          'fin': DateFormat('dd/MM/yyyy HH:mm').format(window.end),
          'description': window.title,
          'exporteLe': DateFormat('dd/MM/yyyy HH:mm').format(now),
        },
      ]);

      final salesRows = await db.rawQuery('''
        SELECT s.id, s.date, s.liters, s.amount, s.pumpId, p.name AS pumpName, s.fuelId, f.name AS fuelName,
               s.nozzleId, n.name AS nozzleName, s.clientId, c.name AS clientName, s.sessionId, ss.code AS sessionCode
        FROM sales s
        LEFT JOIN pumps p ON p.id = s.pumpId
        LEFT JOIN fuels f ON f.id = s.fuelId
        LEFT JOIN pump_nozzles n ON n.id = s.nozzleId
        LEFT JOIN clients c ON c.id = s.clientId
        LEFT JOIN sales_sessions ss ON ss.id = s.sessionId
        WHERE ${_dateFilter('s.date')}
        ORDER BY datetime(s.date) ASC
      ''', window.args);
      _writeSheet(workbook, 'VentesCarburant', salesRows);

      final productSalesRows = await db.rawQuery('''
        SELECT ps.id, ps.date, ps.quantity, ps.amount, ps.productId, sp.name AS productName, ps.sessionId, ss.code AS sessionCode
        FROM product_sales ps
        LEFT JOIN sales_products sp ON sp.id = ps.productId
        LEFT JOIN sales_sessions ss ON ss.id = ps.sessionId
        WHERE ${_dateFilter('ps.date')}
        ORDER BY datetime(ps.date) ASC
      ''', window.args);
      _writeSheet(workbook, 'VentesProduits', productSalesRows);

      final sessionsRows = await db.rawQuery(
        '''
        SELECT id, code, openedAt, closedAt, status
        FROM sales_sessions
        WHERE ${_dateFilter('openedAt')}
           OR (closedAt IS NOT NULL AND ${_dateFilter('closedAt')})
        ORDER BY datetime(openedAt) ASC
      ''',
        [...window.args, ...window.args],
      );
      _writeSheet(workbook, 'Sessions', sessionsRows);

      final sessionPompisteRows = await db.rawQuery('''
        SELECT sp.sessionId, ss.code AS sessionCode, sp.pompisteId, p.name AS pompisteName
        FROM session_pompistes sp
        LEFT JOIN sales_sessions ss ON ss.id = sp.sessionId
        LEFT JOIN pompistes p ON p.id = sp.pompisteId
        WHERE ${_dateFilter('ss.openedAt')}
        ORDER BY sp.sessionId ASC, sp.pompisteId ASC
      ''', window.args);
      _writeSheet(workbook, 'SessionPompistes', sessionPompisteRows);

      final stockRows = await db.rawQuery('''
        SELECT sm.id, sm.date, sm.type, sm.liters, sm.note, sm.fuelId, f.name AS fuelName
        FROM stock_movements sm
        LEFT JOIN fuels f ON f.id = sm.fuelId
        WHERE ${_dateFilter('sm.date')}
        ORDER BY datetime(sm.date) ASC
      ''', window.args);
      _writeSheet(workbook, 'MouvementsStock', stockRows);

      final expenseRows = await db.rawQuery('''
        SELECT e.id, e.date, e.motif, e.amount, e.paymentType, e.supplierId, s.name AS supplierName
        FROM expenses e
        LEFT JOIN suppliers s ON s.id = e.supplierId
        WHERE ${_dateFilter('e.date')}
        ORDER BY datetime(e.date) ASC
      ''', window.args);
      _writeSheet(workbook, 'Depenses', expenseRows);

      final historyRows = await _fetchHistoryRows(db, window);
      _writeSheet(workbook, 'HistoriqueGlobal', historyRows);

      final allHistoryRows = await _fetchHistoryRows(
        db,
        window,
        includeAll: true,
      );
      _writeSheet(workbook, 'DonneesCompletes', allHistoryRows);

      final suppliersRows = await db.query('suppliers', orderBy: 'id ASC');
      _writeSheet(workbook, 'Fournisseurs', suppliersRows);

      final clientsRows = await db.query('clients', orderBy: 'id ASC');
      _writeSheet(workbook, 'Clients', clientsRows);

      final fuelsRows = await db.query('fuels', orderBy: 'id ASC');
      _writeSheet(workbook, 'Carburants', fuelsRows);

      final pumpsRows = await db.query('pumps', orderBy: 'id ASC');
      _writeSheet(workbook, 'Pompes', pumpsRows);

      final nozzlesRows = await db.query('pump_nozzles', orderBy: 'id ASC');
      _writeSheet(workbook, 'Pistolets', nozzlesRows);

      final productsRows = await db.query('sales_products', orderBy: 'id ASC');
      _writeSheet(workbook, 'Produits', productsRows);

      final settingsRows = await db.query('settings', orderBy: 'id ASC');
      _writeSheet(workbook, 'Parametres', settingsRows);

      final choiceRows = await db.query(
        'choice_options',
        orderBy: 'type ASC, value ASC',
      );
      _writeSheet(workbook, 'Options', choiceRows);

      final bytes = workbook.encode();
      if (bytes == null) {
        throw Exception('Echec de generation du fichier Excel.');
      }

      final exportDir = await _resolveStationServiceDirectory();
      final outputPath = p.join(exportDir.path, exportName);
      final file = File(outputPath);
      await file.writeAsBytes(bytes, flush: true);
      return outputPath;
    } finally {
      _isExporting.value = false;
    }
  }

  Future<String> prepareAdminEmail({
    required EmailDocumentType documentType,
    required ExportPeriod period,
  }) async {
    final email = setting.value?.adminEmail.trim() ?? '';
    if (email.isEmpty) {
      throw Exception('Renseignez d abord l email de l administrateur.');
    }

    _isSendingEmail.value = true;
    try {
      final filePath = documentType == EmailDocumentType.excelFile
          ? await exportDataToExcel(period: period)
          : await _exportReportPdf(period);
      await _sendEmailWithAttachment(
        email: email,
        filePath: filePath,
        period: period,
        documentType: documentType,
      );
      return filePath;
    } finally {
      _isSendingEmail.value = false;
    }
  }

  Future<String> _exportReportPdf(ExportPeriod period) async {
    final now = DateTime.now();
    final bytes = await _buildReportPdf(period, now);
    final exportDir = await _resolveStationServiceDirectory();
    final outputName =
        'rapport-${period.fileLabel}-${DateFormat('yyyyMMdd-HHmmss').format(now)}.pdf';
    final outputPath = p.join(exportDir.path, outputName);
    final file = File(outputPath);
    await file.writeAsBytes(bytes, flush: true);
    return outputPath;
  }

  Future<Uint8List> _buildReportPdf(ExportPeriod period, DateTime now) async {
    if (Get.isRegistered<ReportController>()) {
      await Get.find<ReportController>().refreshReports();
    }
    final reportController = Get.find<ReportController>();
    final summary = _summaryForPeriod(reportController, period);
    final db = await DatabaseHelper.instance.database;
    final window = _buildExportWindow(period, now);
    final historyRows = await _fetchHistoryRows(db, window);
    final currentSettings = setting.value;

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Text(
            currentSettings?.stationName.isNotEmpty == true
                ? currentSettings!.stationName
                : 'Station Service',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Rapport ${period.label.toLowerCase()}'),
          pw.Text('Genere le ${DateFormat('dd/MM/yyyy HH:mm').format(now)}'),
          pw.SizedBox(height: 18),
          _pdfSummaryTable(summary),
          pw.SizedBox(height: 18),
          pw.Text(
            'Activites de la periode',
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          _pdfHistoryTable(historyRows),
        ],
      ),
    );

    return pdf.save();
  }

  ReportSummaryModel? _summaryForPeriod(
    ReportController controller,
    ExportPeriod period,
  ) {
    switch (period) {
      case ExportPeriod.daily:
        return controller.dailyReport.value;
      case ExportPeriod.monthly:
        return controller.monthlyReport.value;
      case ExportPeriod.yearly:
        return controller.annualReport.value;
    }
  }

  pw.Widget _pdfSummaryTable(ReportSummaryModel? summary) {
    final rows = [
      ['Total ventes', '${summary?.totalSales ?? 0}'],
      ['Ventes carburant', '${summary?.fuelSales ?? 0}'],
      ['Ventes produits', '${summary?.productSales ?? 0}'],
      [
        'Chiffre d affaires',
        Formatters.cfa((summary?.revenue ?? 0).toDouble()),
      ],
      ['CA carburant', Formatters.cfa((summary?.fuelRevenue ?? 0).toDouble())],
      [
        'CA produits',
        Formatters.cfa((summary?.productRevenue ?? 0).toDouble()),
      ],
    ];

    return pw.TableHelper.fromTextArray(
      headers: const ['Indicateur', 'Valeur'],
      data: rows,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColor(0.9, 0.93, 1)),
      cellAlignment: pw.Alignment.centerLeft,
    );
  }

  pw.Widget _pdfHistoryTable(List<Map<String, Object?>> rows) {
    if (rows.isEmpty) {
      return pw.Text('Aucune activite trouvee pour cette periode.');
    }

    final data = rows.take(80).map((row) {
      return [
        _formatPdfDate(row['date']),
        row['categorie']?.toString() ?? '',
        row['titre']?.toString() ?? '',
        row['montant'] == null
            ? ''
            : Formatters.cfa((row['montant'] as num?)?.toDouble() ?? 0),
      ];
    }).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.TableHelper.fromTextArray(
          headers: const ['Date', 'Categorie', 'Titre', 'Montant'],
          data: data,
          headerDecoration: const pw.BoxDecoration(
            color: PdfColor(0.92, 0.96, 0.94),
          ),
          cellAlignment: pw.Alignment.centerLeft,
          cellStyle: const pw.TextStyle(fontSize: 8),
          headerStyle: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        if (rows.length > 80)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 8),
            child: pw.Text(
              '${rows.length - 80} ligne(s) supplementaire(s) disponibles dans l export Excel.',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
      ],
    );
  }

  String _formatPdfDate(Object? value) {
    final text = value?.toString() ?? '';
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return text;
    return DateFormat('dd/MM/yyyy HH:mm').format(parsed);
  }

  Future<void> _sendEmailWithAttachment({
    required String email,
    required String filePath,
    required ExportPeriod period,
    required EmailDocumentType documentType,
  }) async {
    final stationName = setting.value?.stationName.trim();
    final subject =
        '${documentType.label} ${period.label.toLowerCase()} - ${stationName?.isNotEmpty == true ? stationName : 'Station Service'}';
    final body = [
      'Bonjour,',
      '',
      'Veuillez trouver le ${documentType.label.toLowerCase()} ${period.label.toLowerCase()} genere par l application.',
      '',
      'Fichier genere : $filePath',
      '',
      'Le fichier est joint a cet email.',
    ].join('\n');

    final message = Email(
      body: body,
      subject: subject,
      recipients: [email],
      attachmentPaths: [filePath],
      isHTML: false,
    );

    await FlutterEmailSender.send(message);
  }

  void _writeSheet(
    Excel workbook,
    String sheetName,
    List<Map<String, Object?>> rows,
  ) {
    final safeName = _sanitizeSheetName(sheetName);
    final sheet = workbook[safeName];
    if (rows.isEmpty) {
      _appendRow(sheet, const ['Aucune donnée']);
      return;
    }
    final headers = rows.first.keys.toList(growable: false);
    _appendRow(sheet, headers);
    for (final row in rows) {
      _appendRow(sheet, headers.map((h) => row[h]).toList(growable: false));
    }
  }

  _ExportWindow _buildExportWindow(ExportPeriod period, DateTime now) {
    switch (period) {
      case ExportPeriod.daily:
        final start = DateTime(now.year, now.month, now.day);
        return _ExportWindow(
          start: start,
          end: start.add(const Duration(days: 1)),
          title: 'Toutes les operations du jour courant',
        );
      case ExportPeriod.monthly:
        final start = DateTime(now.year, now.month);
        return _ExportWindow(
          start: start,
          end: DateTime(now.year, now.month + 1),
          title: 'Toutes les operations du mois courant',
        );
      case ExportPeriod.yearly:
        final start = DateTime(now.year);
        return _ExportWindow(
          start: start,
          end: DateTime(now.year + 1),
          title: 'Toutes les operations de l annee courante',
        );
    }
  }

  String _dateFilter(String column) {
    final normalized = _normalizedDate(column);
    return '$normalized >= datetime(?) AND $normalized < datetime(?)';
  }

  String _normalizedDate(String column) {
    return "datetime(replace(substr($column, 1, 19), 'T', ' '))";
  }

  Future<List<Map<String, Object?>>> _fetchHistoryRows(
    Database db,
    _ExportWindow window, {
    bool includeAll = false,
  }) {
    final salesFilter = includeAll ? '1 = 1' : _dateFilter('s.date');
    final productSalesFilter = includeAll ? '1 = 1' : _dateFilter('ps.date');
    final stockFilter = includeAll ? '1 = 1' : _dateFilter('sm.date');
    final expensesFilter = includeAll ? '1 = 1' : _dateFilter('e.date');
    final openedSessionFilter = includeAll
        ? '1 = 1'
        : _dateFilter('ss.openedAt');
    final closedSessionFilter = includeAll
        ? '1 = 1'
        : _dateFilter('ss.closedAt');
    final args = includeAll
        ? <Object?>[]
        : <Object?>[
            ...window.args,
            ...window.args,
            ...window.args,
            ...window.args,
            ...window.args,
            ...window.args,
          ];

    return db.rawQuery('''
      SELECT
        s.date AS date,
        'Vente carburant' AS categorie,
        COALESCE(f.name, 'Carburant') AS titre,
        'Pompe: ' || COALESCE(p.name, '-') || ', Pistolet: ' || COALESCE(n.name, '-') AS details,
        s.liters AS quantite,
        s.amount AS montant
      FROM sales s
      LEFT JOIN pumps p ON p.id = s.pumpId
      LEFT JOIN fuels f ON f.id = s.fuelId
      LEFT JOIN pump_nozzles n ON n.id = s.nozzleId
      WHERE $salesFilter

      UNION ALL

      SELECT
        ps.date AS date,
        'Vente produit' AS categorie,
        COALESCE(sp.name, 'Produit') AS titre,
        'Quantite vendue' AS details,
        ps.quantity AS quantite,
        ps.amount AS montant
      FROM product_sales ps
      LEFT JOIN sales_products sp ON sp.id = ps.productId
      WHERE $productSalesFilter

      UNION ALL

      SELECT
        sm.date AS date,
        'Stock' AS categorie,
        CASE sm.type WHEN 'entry' THEN 'Entree stock' ELSE 'Sortie stock' END AS titre,
        COALESCE(f.name, '-') || ' - ' || COALESCE(sm.note, '') AS details,
        sm.liters AS quantite,
        NULL AS montant
      FROM stock_movements sm
      LEFT JOIN fuels f ON f.id = sm.fuelId
      WHERE $stockFilter

      UNION ALL

      SELECT
        e.date AS date,
        'Depense' AS categorie,
        e.motif AS titre,
        'Paiement: ' || e.paymentType || ', Fournisseur: ' || COALESCE(s.name, '-') AS details,
        NULL AS quantite,
        e.amount AS montant
      FROM expenses e
      LEFT JOIN suppliers s ON s.id = e.supplierId
      WHERE $expensesFilter

      UNION ALL

      SELECT
        ss.openedAt AS date,
        'Session' AS categorie,
        'Ouverture session' AS titre,
        ss.code AS details,
        NULL AS quantite,
        NULL AS montant
      FROM sales_sessions ss
      WHERE $openedSessionFilter

      UNION ALL

      SELECT
        ss.closedAt AS date,
        'Session' AS categorie,
        'Fermeture session' AS titre,
        ss.code AS details,
        NULL AS quantite,
        NULL AS montant
      FROM sales_sessions ss
      WHERE ss.closedAt IS NOT NULL AND $closedSessionFilter

      ORDER BY 1 ASC
    ''', args);
  }

  Future<Directory> _resolveStationServiceDirectory() async {
    final candidates = <Directory>[];

    if (Platform.isAndroid) {
      candidates.add(Directory('/storage/emulated/0/Download/station_service'));
      candidates.add(
        Directory('/storage/emulated/0/Downloads/station_service'),
      );
    }

    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        candidates.add(Directory(p.join(downloadsDir.path, 'station_service')));
      }
    } catch (_) {
      // Some platforms do not expose a public downloads directory.
    }

    if (!Platform.isAndroid) {
      final docsDir = await getApplicationDocumentsDirectory();
      candidates.add(Directory(p.join(docsDir.path, 'station_service')));
    }

    final testedPaths = <String>{};
    for (final dir in candidates) {
      if (!testedPaths.add(dir.path)) continue;
      try {
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }

        final probe = File(p.join(dir.path, '.write_test'));
        await probe.writeAsString('ok', flush: true);
        if (await probe.exists()) {
          await probe.delete();
        }
        return dir;
      } catch (_) {
        continue;
      }
    }

    throw Exception(
      'Impossible de creer le dossier station_service dans Telechargements. Verifiez l autorisation de stockage du telephone.',
    );
  }

  void _appendRow(Sheet sheet, List<Object?> values) {
    final rowIndex = sheet.maxRows;
    for (var col = 0; col < values.length; col++) {
      final value = values[col];
      final text = value == null ? '' : value.toString();
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex),
        TextCellValue(text),
      );
    }
  }

  String _sanitizeSheetName(String input) {
    final cleaned = input.replaceAll(RegExp(r'[:\\/?*\[\]]'), '_').trim();
    if (cleaned.isEmpty) {
      return 'Sheet';
    }
    if (cleaned.length <= 31) {
      return cleaned;
    }
    return cleaned.substring(0, 31);
  }

  Future<void> _refreshRegisteredControllers() async {
    if (Get.isRegistered<DashboardController>()) {
      await Get.find<DashboardController>().loadDashboard();
    }
    if (Get.isRegistered<FuelController>()) {
      await Get.find<FuelController>().fetchFuels();
    }
    if (Get.isRegistered<PumpController>()) {
      await Get.find<PumpController>().fetchPumps();
    }
    if (Get.isRegistered<SaleController>()) {
      await Get.find<SaleController>().fetchSales();
    }
    if (Get.isRegistered<ClientController>()) {
      await Get.find<ClientController>().fetchClients();
    }
    if (Get.isRegistered<StockController>()) {
      await Get.find<StockController>().fetchMovements();
    }
    if (Get.isRegistered<ReportController>()) {
      await Get.find<ReportController>().refreshReports();
    }
    if (Get.isRegistered<SalesProductController>()) {
      await Get.find<SalesProductController>().fetchProducts();
    }
    if (Get.isRegistered<PompisteController>()) {
      await Get.find<PompisteController>().fetchPompistes();
    }
    if (Get.isRegistered<SupplierController>()) {
      await Get.find<SupplierController>().fetchSuppliers();
    }
    if (Get.isRegistered<ExpenseController>()) {
      await Get.find<ExpenseController>().fetchData();
    }
    if (Get.isRegistered<AccountingController>()) {
      await Get.find<AccountingController>().refreshAccounting();
    }
  }
}
