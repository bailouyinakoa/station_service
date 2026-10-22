import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:station_service_app/core/constants/app_strings.dart';
import 'package:station_service_app/core/database/database_helper.dart';
import 'package:station_service_app/core/utils/formatters.dart';
import 'package:station_service_app/data/models/report_summary_model.dart';
import 'package:station_service_app/presentation/controllers/report_controller.dart';
import 'package:station_service_app/presentation/widgets/responsive_scaffold.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReportController>();
    final isMobile = MediaQuery.of(context).size.width < 600;
    return ResponsiveScaffold(
      title: AppStrings.reportsTitle,
      titleStyle: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF283593),
                      Color(0xFF3949AB),
                      Color(0xFF5C6BC0),
                      Color(0xFF7986CB),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.0, 0.3, 0.7, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.12),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(255, 255, 255, 0.25),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color.fromRGBO(255, 255, 255, 0.3),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.analytics_outlined,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        SizedBox(width: isMobile ? 10 : 20),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tableau de bord',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Analyse complète des performances de vente',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(255, 255, 255, 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color.fromRGBO(255, 255, 255, 0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.trending_up,
                                color: const Color.fromRGBO(255, 255, 255, 0.9),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Résumé des ventes',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              SizedBox(
                                width: isMobile
                                    ? (MediaQuery.of(context).size.width - 40)
                                    : (MediaQuery.of(context).size.width - 120) / 3,
                                child: _summaryChip(
                                  'Journalier',
                                  controller.dailyReport.value?.totalSales ?? 0,
                                  controller.dailyReport.value?.revenue ?? 0,
                                  Icons.today,
                                  const Color(0xFF4CAF50),
                                ),
                              ),
                              SizedBox(
                                width: isMobile
                                    ? (MediaQuery.of(context).size.width - 40) 
                                    : (MediaQuery.of(context).size.width - 120) / 3,
                                child: _summaryChip(
                                  'Mensuel',
                                  controller.monthlyReport.value?.totalSales ?? 0,
                                  controller.monthlyReport.value?.revenue ?? 0,
                                  Icons.calendar_month,
                                  const Color(0xFF2196F3),
                                ),
                              ),
                              SizedBox(
                                width: isMobile
                                    ? (MediaQuery.of(context).size.width - 40)
                                    : (MediaQuery.of(context).size.width - 120) / 3,
                                child: _summaryChip(
                                  'Annuel',
                                  controller.annualReport.value?.totalSales ?? 0,
                                  controller.annualReport.value?.revenue ?? 0,
                                  Icons.calendar_today,
                                  const Color(0xFFFF9800),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _dailyGlobalPieChart(context, controller),
              const SizedBox(height: 14),
              _salesDistributionCard(
                context: context,
                title: 'Répartition journalière',
                summary: controller.dailyReport.value,
              ),
              const SizedBox(height: 12),
              _salesDistributionCard(
                context: context,
                title: 'Répartition mensuelle',
                summary: controller.monthlyReport.value,
              ),
              const SizedBox(height: 12),
              _salesDistributionCard(
                context: context,
                title: 'Répartition annuelle',
                summary: controller.annualReport.value,
              ),
              const SizedBox(height: 16),
              _todayActivitySection(context),
              const SizedBox(height: 16),
              Text(
                'Détails du rapport',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF283593),
                ),
              ),
              const SizedBox(height: 12),
              _reportCard(
                'Rapport journalier',
                controller.dailyReport.value,
                Icons.today,
              ),
              _reportCard(
                'Rapport mensuel',
                controller.monthlyReport.value,
                Icons.calendar_month,
              ),
              _reportCard(
                'Rapport annuel',
                controller.annualReport.value,
                Icons.calendar_today,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: isMobile
                        ? MediaQuery.of(context).size.width - 24
                        : (MediaQuery.of(context).size.width - 56) / 2,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.print),
                      label: const Text('Imprimer'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF283593),
                      ),
                      onPressed: () async {
                        final selected = await _selectReportOptions(controller);
                        if (selected == null) return;
                        final bytes = await _buildReportPdf(
                          selected.periodLabel,
                          selected.summary,
                          selected.contentMode,
                        );
                        await Printing.layoutPdf(onLayout: (_) => bytes);
                      },
                    ),
                  ),
                  SizedBox(
                    width: isMobile
                        ? MediaQuery.of(context).size.width - 24
                        : (MediaQuery.of(context).size.width - 56) / 2,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Exporter PDF'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFF283593)),
                      ),
                      onPressed: () async {
                        final selected = await _selectReportOptions(controller);
                        if (selected == null) return;
                        final bytes = await _buildReportPdf(
                          selected.periodLabel,
                          selected.summary,
                          selected.contentMode,
                        );
                        await Printing.sharePdf(
                          bytes: bytes,
                          filename: 'rapport-${selected.fileNamePart}.pdf',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Future<_ReportSelection?> _selectReportOptions(ReportController controller) async {
    final period = await Get.dialog<_ReportSelection>(
      AlertDialog(
        title: const Text('Type de rapport'),
        content: const Text('Choisissez la période du rapport à générer :'),
        actions: [
          TextButton(
            onPressed: () => Get.back(
              result: _ReportSelection(
                periodLabel: 'Journalier',
                fileNamePart: 'journalier',
                summary: controller.dailyReport.value,
                contentMode: ReportContentMode.fallbackOnly,
              ),
            ),
            child: const Text('Journalier'),
          ),
          TextButton(
            onPressed: () => Get.back(
              result: _ReportSelection(
                periodLabel: 'Mensuel',
                fileNamePart: 'mensuel',
                summary: controller.monthlyReport.value,
                contentMode: ReportContentMode.fallbackOnly,
              ),
            ),
            child: const Text('Mensuel'),
          ),
          TextButton(
            onPressed: () => Get.back(
              result: _ReportSelection(
                periodLabel: 'Annuel',
                fileNamePart: 'annuel',
                summary: controller.annualReport.value,
                contentMode: ReportContentMode.fallbackOnly,
              ),
            ),
            child: const Text('Annuel'),
          ),
        ],
      ),
    );
    if (period == null) return null;

    return _ReportSelection(
      periodLabel: period.periodLabel,
      fileNamePart: period.fileNamePart,
      summary: period.summary,
      contentMode: ReportContentMode.fallbackOnly,
    );
  }

  Future<Uint8List> _buildReportPdf(
    String periodLabel,
    ReportSummaryModel? summary,
    ReportContentMode contentMode,
  ) async {
    final baseFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    final pdf = pw.Document();
    final now = DateTime.now();
    final detailedActivities = await _loadDetailedActivities(periodLabel, contentMode);
    
    // Récupérer les informations de la station et le logo
    String? stationName = 'Station Service';
    String? logoPath;
    
    try {
      final db = await DatabaseHelper.instance.database;
      final settingsRows = await db.query('settings');
      if (settingsRows.isNotEmpty) {
        stationName = settingsRows.first['stationName'] as String? ?? 'Station Service';
        logoPath = settingsRows.first['logoPath'] as String?;
      }
    } catch (e) {
      // Utiliser les valeurs par défaut
    }
    
    pw.ImageProvider? logoImage;
    if (logoPath != null && logoPath.isNotEmpty) {
      final logoFile = File(logoPath);
      if (await logoFile.exists()) {
        logoImage = pw.MemoryImage(await logoFile.readAsBytes());
      }
    }
    
    final categoryCounts = <String, int>{};
    for (final activity in detailedActivities) {
      final category = activity['category'] as String? ?? 'Autre';
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }
    final tableData = [
      ['Période', 'Transactions', 'Carburant', 'Produits', 'Chiffre total'],
      [
        periodLabel,
        '${summary?.totalSales ?? 0}',
        Formatters.cfa(summary?.fuelRevenue ?? 0),
        Formatters.cfa(summary?.productRevenue ?? 0),
        Formatters.cfa(summary?.revenue ?? 0),
      ],
    ];
    final activityRows = detailedActivities.asMap().entries.map((entry) {
      final i = entry.key + 1;
      final item = entry.value;
      final date = item['eventDate'] as String? ?? '-';
      final category = item['category'] as String? ?? '-';
      final title = item['title'] as String? ?? '-';
      final details = item['details'] as String? ?? '-';
      final quantity = item['quantity'] as num?;
      final amount = item['amount'] as num?;
      return [
        '$i',
        date,
        category,
        title,
        details,
        quantity == null ? '-' : quantity.toStringAsFixed(2),
        amount == null ? '-' : Formatters.cfa(amount.toDouble()),
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
        build: (context) => [
          // En-tête avec logo et nom de la station
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              if (logoImage != null)
                pw.Image(
                  logoImage,
                  width: 90,
                  height: 90,
                )
              else
                pw.SizedBox(width: 90, height: 90),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      stationName ?? 'Station Service',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                      maxLines: 2,
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Rapport de ventes',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Divider(
            height: 2,
            color: PdfColors.blue900,
          ),
          pw.SizedBox(height: 12),
          
          // Informations du rapport
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Rapport: $periodLabel',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Date de génération: ${DateFormat('dd/MM/yyyy HH:mm').format(now)}',
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue900,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Résumé des ventes',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Transactions',
                          style: pw.TextStyle(
                            color: PdfColor.fromInt(0xFFFFFFB3),
                            fontSize: 11,
                          ),
                        ),
                        pw.Text(
                          '${summary?.totalSales ?? 0}',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Carburants',
                          style: pw.TextStyle(
                            color: PdfColor.fromInt(0xFFFFFFB3),
                            fontSize: 11,
                          ),
                        ),
                        pw.Text(
                          Formatters.cfa(summary?.fuelRevenue ?? 0),
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Produits',
                          style: pw.TextStyle(
                            color: PdfColor.fromInt(0xFFFFFFB3),
                            fontSize: 11,
                          ),
                        ),
                        pw.Text(
                          Formatters.cfa(summary?.productRevenue ?? 0),
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Résumé rapide',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      '$periodLabel: ${summary?.totalSales ?? 0} transactions',
                      style: pw.TextStyle(fontSize: 12),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Mode: ${_contentModeLabel(contentMode)}',
                      style: pw.TextStyle(fontSize: 11),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Carburant: ${summary?.fuelSales ?? 0} • Produits: ${summary?.productSales ?? 0}',
                      style: pw.TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Revenus',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      Formatters.cfa(summary?.revenue ?? 0),
                      style: pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Tableau de synthèse',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headers: tableData.first,
            data: tableData.sublist(1),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 11),
            cellPadding: const pw.EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 6,
            ),
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Volume d\'activité',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            '${detailedActivities.length} activité(s) détaillée(s) incluse(s) dans ce rapport.',
            style: const pw.TextStyle(fontSize: 11),
          ),
          pw.SizedBox(height: 6),
          ...categoryCounts.entries.map(
            (entry) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text(
                '${entry.key}: ${entry.value} élément(s)',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Historique complet des opérations',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (activityRows.isEmpty)
            pw.Text(
              'Aucune activité enregistrée pour cette période.',
              style: const pw.TextStyle(fontSize: 11),
            )
          else
            pw.TableHelper.fromTextArray(
              headers: const [
                '#',
                'Date/Heure',
                'Catégorie',
                'Opération',
                'Détails',
                'Qté/Litres',
                'Montant',
              ],
              data: activityRows,
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.symmetric(
                vertical: 5,
                horizontal: 4,
              ),
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
              columnWidths: {
                0: const pw.FlexColumnWidth(0.5),
                1: const pw.FlexColumnWidth(1.3),
                2: const pw.FlexColumnWidth(1.0),
                3: const pw.FlexColumnWidth(1.2),
                4: const pw.FlexColumnWidth(1.7),
                5: const pw.FlexColumnWidth(0.9),
                6: const pw.FlexColumnWidth(1.2),
              },
            ),
          pw.SizedBox(height: 24),
          pw.Divider(color: PdfColors.grey600),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Station de service',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
              pw.Text(
                'Généré automatiquement',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  Future<List<Map<String, Object?>>> _loadDetailedActivities(
    String periodLabel,
    ReportContentMode contentMode,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final salesWhere = _buildSqlWhereClause(periodLabel, 's.date');
    final productSalesWhere = _buildSqlWhereClause(periodLabel, 'ps.date');
    final stockWhere = _buildSqlWhereClause(periodLabel, 'sm.date');
    final expenseWhere = _buildSqlWhereClause(periodLabel, 'e.date');
    final openedSessionWhere = _buildSqlWhereClause(periodLabel, 'ss.openedAt');
    final closedSessionWhere = _buildSqlWhereClause(periodLabel, 'ss.closedAt');

    final fallbackRows = await db.rawQuery('''
      SELECT * FROM (
        SELECT
          s.date as eventDate,
          'Vente carburant' as category,
          COALESCE(f.name, 'Carburant') as title,
          'Pompe: ' || COALESCE(p.name, '-') || ' | Client: ' || COALESCE(c.name, 'Comptoir') as details,
          s.liters as quantity,
          s.amount as amount
        FROM sales s
        LEFT JOIN fuels f ON f.id = s.fuelId
        LEFT JOIN pumps p ON p.id = s.pumpId
        LEFT JOIN clients c ON c.id = s.clientId
        WHERE $salesWhere

        UNION ALL

        SELECT
          ps.date as eventDate,
          'Vente produit' as category,
          COALESCE(sp.name, 'Produit') as title,
          'Catégorie: ' || COALESCE(sp.category, '-') as details,
          ps.quantity as quantity,
          ps.amount as amount
        FROM product_sales ps
        LEFT JOIN sales_products sp ON sp.id = ps.productId
        WHERE $productSalesWhere

        UNION ALL

        SELECT
          sm.date as eventDate,
          'Mouvement stock' as category,
          COALESCE(f.name, 'Carburant') as title,
          'Type: ' || COALESCE(sm.type, '-') || ' | Note: ' || COALESCE(sm.note, '-') as details,
          sm.liters as quantity,
          NULL as amount
        FROM stock_movements sm
        LEFT JOIN fuels f ON f.id = sm.fuelId
        WHERE $stockWhere

        UNION ALL

        SELECT
          e.date as eventDate,
          'Dépense' as category,
          COALESCE(e.motif, '-') as title,
          'Paiement: ' || COALESCE(e.paymentType, '-') || ' | Fournisseur: ' || COALESCE(sup.name, '-') as details,
          NULL as quantity,
          e.amount as amount
        FROM expenses e
        LEFT JOIN suppliers sup ON sup.id = e.supplierId
        WHERE $expenseWhere

        UNION ALL

        SELECT
          ss.openedAt as eventDate,
          'Session' as category,
          'Ouverture session' as title,
          'Code: ' || COALESCE(ss.code, '-') as details,
          NULL as quantity,
          NULL as amount
        FROM sales_sessions ss
        WHERE $openedSessionWhere

        UNION ALL

        SELECT
          ss.closedAt as eventDate,
          'Session' as category,
          'Fermeture session' as title,
          'Code: ' || COALESCE(ss.code, '-') as details,
          NULL as quantity,
          NULL as amount
        FROM sales_sessions ss
        WHERE ss.closedAt IS NOT NULL AND $closedSessionWhere
      )
      ORDER BY datetime(eventDate) ASC, category ASC, title ASC
    ''');
    return fallbackRows;
  }

  String _buildSqlWhereClause(String periodLabel, String dateColumn) {
    final normalized = periodLabel.toLowerCase();
    if (normalized.contains('journal')) {
      return "$dateColumn LIKE date('now') || '%'";
    }
    if (normalized.contains('mens')) {
      return "strftime('%Y-%m', $dateColumn) = strftime('%Y-%m', 'now')";
    }
    return "strftime('%Y', $dateColumn) = strftime('%Y', 'now')";
  }

  String _contentModeLabel(ReportContentMode mode) {
    switch (mode) {
      case ReportContentMode.fallbackOnly:
        return 'Données métier';
    }
  }

  Widget _summaryChip(
    String title,
    int sales,
    double revenue,
    IconData icon,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color.fromRGBO(255, 255, 255, 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor.withValues(alpha: 0.8), size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$sales',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'ventes',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              Formatters.cfa(revenue),
              style: TextStyle(
                color: accentColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportCard(String title, ReportSummaryModel? summary, IconData icon) {
    final isMobile = Get.context != null
        ? MediaQuery.of(Get.context!).size.width < 600
        : false;
    Color cardColor;
    Color iconBgColor;
    Color textColor;

    switch (icon) {
      case Icons.today:
        cardColor = const Color(0xFF4CAF50);
        iconBgColor = const Color.fromRGBO(76, 175, 80, 0.2);
        textColor = const Color(0xFF2E7D32);
        break;
      case Icons.calendar_month:
        cardColor = const Color(0xFF2196F3);
        iconBgColor = const Color.fromRGBO(33, 150, 243, 0.2);
        textColor = const Color(0xFF1565C0);
        break;
      case Icons.calendar_today:
        cardColor = const Color(0xFFFF9800);
        iconBgColor = const Color.fromRGBO(255, 152, 0, 0.2);
        textColor = const Color(0xFFEF6C00);
        break;
      default:
        cardColor = const Color(0xFF283593);
        iconBgColor = const Color.fromRGBO(40, 53, 147, 0.1);
        textColor = const Color(0xFF283593);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (value * 0.05),
          child: Opacity(
            opacity: value,
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 1 + value,
              shadowColor: cardColor.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [Colors.white, cardColor.withValues(alpha: 0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: iconBgColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: cardColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(icon, color: cardColor, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              children: [
                                SizedBox(
                                  width: isMobile ? double.infinity : 170,
                                  child: _metricCard(
                                    value: '${summary?.totalSales ?? 0}',
                                    label: 'Transactions',
                                    bgColor: cardColor.withValues(alpha: 0.1),
                                    textColor: textColor,
                                  ),
                                ),
                                SizedBox(
                                  width: isMobile ? double.infinity : 210,
                                  child: _metricCard(
                                    value: Formatters.cfa(summary?.revenue ?? 0),
                                    label: 'Chiffre d\'affaires total',
                                    bgColor: const Color.fromRGBO(76, 175, 80, 0.1),
                                    textColor: const Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Carburant: ${summary?.fuelSales ?? 0} (${Formatters.cfa(summary?.fuelRevenue ?? 0)}) • '
                              'Produits: ${summary?.productSales ?? 0} (${Formatters.cfa(summary?.productRevenue ?? 0)})',
                              style: TextStyle(
                                fontSize: 12,
                                color: textColor.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _metricCard({
    required String value,
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: textColor.withValues(alpha: 0.75),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _todayActivitySection(BuildContext context) {
    return FutureBuilder<List<Map<String, Object?>>>(
      future: _loadDetailedActivities('Journalier', ReportContentMode.fallbackOnly),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final activities = (snapshot.data ?? const <Map<String, Object?>>[])
            .reversed
            .toList();

        return Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Activités du jour',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Toutes les opérations enregistrées aujourd\'hui dans l\'application.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 12),
                if (snapshot.hasError)
                  const Text('Impossible de charger les activités du jour.')
                else if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (activities.isEmpty)
                  const Text('Aucune activité enregistrée aujourd\'hui.')
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        const Color(0xFFEFF6FF),
                      ),
                      dataRowMinHeight: 56,
                      dataRowMaxHeight: 72,
                      columns: const [
                        DataColumn(label: Text('Heure')),
                        DataColumn(label: Text('Catégorie')),
                        DataColumn(label: Text('Opération')),
                        DataColumn(label: Text('Détails')),
                        DataColumn(label: Text('Qté')),
                        DataColumn(label: Text('Montant')),
                      ],
                      rows: activities.map((activity) {
                        final details = '${activity['details'] ?? '-'}';
                        final amount = activity['amount'] as num?;
                        final quantity = activity['quantity'] as num?;
                        return DataRow(
                          cells: [
                            DataCell(Text(_formatActivityDate(activity['eventDate']))),
                            DataCell(
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 120),
                                child: Text(
                                  '${activity['category'] ?? '-'}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 170),
                                child: Text(
                                  '${activity['title'] ?? '-'}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 260),
                                child: Text(
                                  details,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                quantity == null
                                    ? '-'
                                    : quantity.toStringAsFixed(2),
                              ),
                            ),
                            DataCell(
                              Text(
                                amount == null
                                    ? '-'
                                    : Formatters.cfa(amount.toDouble()),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _salesDistributionCard({
    required BuildContext context,
    required String title,
    required ReportSummaryModel? summary,
  }) {
    final fuel = summary?.fuelRevenue ?? 0;
    final products = summary?.productRevenue ?? 0;
    final total = (fuel + products) <= 0 ? 1.0 : fuel + products;
    final fuelPct = fuel / total;
    final productsPct = products / total;
    return Card(
      elevation: 0.9,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            SizedBox(
              width: 86,
              height: 86,
              child: CustomPaint(
                painter: _RevenuePiePainter(
                  fuelPortion: fuelPct,
                  productPortion: productsPct,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('Carburant: ${Formatters.cfa(fuel)}'),
                  Text('Produits: ${Formatters.cfa(products)}'),
                  Text(
                    'Part carburant ${(fuelPct * 100).toStringAsFixed(1)}% • Produits ${(productsPct * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dailyGlobalPieChart(BuildContext context, ReportController controller) {
    final data = controller.dailyItemBreakdown;
    final total = data.fold<double>(
      0,
      (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0),
    );
    final colors = <Color>[
      const Color(0xFF1D4ED8),
      const Color(0xFF16A34A),
      const Color(0xFFF59E0B),
      const Color(0xFFDC2626),
      const Color(0xFF7C3AED),
      const Color(0xFF0EA5E9),
      const Color(0xFFEA580C),
      const Color(0xFF4B5563),
    ];

    return Card(
      elevation: 1.0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Grand Pie Chart - Ventes journalières par élément',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 10),
            if (data.isEmpty || total <= 0)
              const Text('Aucune vente journalière à afficher.')
            else
              LayoutBuilder(
                builder: (context, c) {
                  final isNarrow = c.maxWidth < 680;
                  final legend = Column(
                    children: List.generate(data.length, (index) {
                      final label = '${data[index]['label'] ?? '-'}';
                      final amount =
                          ((data[index]['amount'] as num?)?.toDouble() ?? 0);
                      final pct = total <= 0 ? 0 : (amount / total * 100);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: colors[index % colors.length],
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$label (${pct.toStringAsFixed(1)}%)',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  );
                  final chart = SizedBox(
                    width: 220,
                    height: 220,
                    child: CustomPaint(
                      painter: _MultiPiePainter(
                        values: data
                            .map((e) => ((e['amount'] as num?)?.toDouble() ?? 0))
                            .toList(),
                        colors: List.generate(
                          data.length,
                          (i) => colors[i % colors.length],
                        ),
                      ),
                    ),
                  );
                  if (isNarrow) {
                    return Column(
                      children: [Center(child: chart), const SizedBox(height: 12), legend],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [chart, const SizedBox(width: 12), Expanded(child: legend)],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatActivityDate(Object? rawDate) {
    if (rawDate == null) return '-';
    final parsed = DateTime.tryParse('$rawDate');
    if (parsed == null) return '$rawDate';
    return DateFormat('HH:mm - dd/MM').format(parsed);
  }
}

class _ReportSelection {
  const _ReportSelection({
    required this.periodLabel,
    required this.fileNamePart,
    required this.summary,
    required this.contentMode,
  });

  final String periodLabel;
  final String fileNamePart;
  final ReportSummaryModel? summary;
  final ReportContentMode contentMode;
}

enum ReportContentMode { fallbackOnly }

class _RevenuePiePainter extends CustomPainter {
  _RevenuePiePainter({required this.fuelPortion, required this.productPortion});

  final double fuelPortion;
  final double productPortion;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final fuelPaint = Paint()..color = const Color(0xFF2563EB);
    final productPaint = Paint()..color = const Color(0xFF16A34A);
    final holePaint = Paint()..color = Colors.white;
    final ringBgPaint = Paint()..color = const Color(0xFFE5E7EB);
    final separatorPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final start = -math.pi / 2;
    final fuelSweep = 2 * math.pi * fuelPortion.clamp(0, 1);
    final productSweep = 2 * math.pi * productPortion.clamp(0, 1);

    canvas.drawCircle(center, radius, ringBgPaint);
    canvas.drawArc(rect, start, fuelSweep, true, fuelPaint);
    canvas.drawArc(rect, start + fuelSweep, productSweep, true, productPaint);
    canvas.drawArc(rect, start, fuelSweep, false, separatorPaint);
    canvas.drawArc(rect, start + fuelSweep, productSweep, false, separatorPaint);
    canvas.drawCircle(center, radius * 0.45, holePaint);
  }

  @override
  bool shouldRepaint(covariant _RevenuePiePainter oldDelegate) {
    return fuelPortion != oldDelegate.fuelPortion ||
        productPortion != oldDelegate.productPortion;
  }
}

class _MultiPiePainter extends CustomPainter {
  _MultiPiePainter({required this.values, required this.colors});

  final List<double> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (sum, v) => sum + v);
    if (total <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final ringBgPaint = Paint()..color = const Color(0xFFE5E7EB);
    final separatorPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    var start = -math.pi / 2;
    canvas.drawCircle(center, radius, ringBgPaint);
    for (var i = 0; i < values.length; i++) {
      final sweep = 2 * math.pi * (values[i] / total);
      canvas.drawArc(
        rect,
        start,
        sweep,
        true,
        Paint()..color = colors[i % colors.length],
      );
      canvas.drawArc(rect, start, sweep, false, separatorPaint);
      start += sweep;
    }
    canvas.drawCircle(center, radius * 0.38, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _MultiPiePainter oldDelegate) {
    return values != oldDelegate.values || colors != oldDelegate.colors;
  }
}
