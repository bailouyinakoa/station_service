import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:station_service_app/core/constants/app_strings.dart';
import 'package:station_service_app/core/utils/formatters.dart';
import 'package:station_service_app/data/models/pompiste_model.dart';
import 'package:station_service_app/data/models/product_sale_model.dart';
import 'package:station_service_app/data/models/pump_model.dart';
import 'package:station_service_app/data/models/nozzle_model.dart';
import 'package:station_service_app/data/models/sale_model.dart';
import 'package:station_service_app/data/models/sales_product_model.dart';
import 'package:station_service_app/presentation/controllers/pompiste_controller.dart';
import 'package:station_service_app/presentation/controllers/sale_controller.dart';
import 'package:station_service_app/presentation/widgets/adaptive_modal.dart';
import 'package:station_service_app/presentation/widgets/horizontal_history_chart.dart';
import 'package:station_service_app/presentation/widgets/responsive_scaffold.dart';

class SalePage extends StatelessWidget {
  const SalePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SaleController>();
    final isMobile = MediaQuery.of(context).size.width < 600;
    return ResponsiveScaffold(
      title: AppStrings.salesTitle,
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final sales = controller.sales;
        final productSales = controller.productSales;
        final session = controller.activeSession.value;
        final closedSessions = controller.closedSessions;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSessionCard(controller, session),
            const SizedBox(height: 16),
            _buildClosedSessionsSection(controller, closedSessions, isMobile),
            const SizedBox(height: 16),
            _buildSalesRevenueChart(sales),
            const SizedBox(height: 16),
            _buildProductSalesSection(productSales, isMobile),
            const SizedBox(height: 16),
            _buildFuelSalesSection(sales, isMobile),
            const SizedBox(height: 100),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSaleTypeSheet(context, controller),
        icon: const Icon(Icons.add_shopping_cart_outlined),
        label: const Text('Nouvelle vente'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  void _showAddSaleTypeSheet(BuildContext context, SaleController controller) {
    if (!controller.hasOpenSession) {
      Get.snackbar(
        'Session requise',
        'Ouvrez une session avant d enregistrer une vente.',
      );
      return;
    }
    final parentContext = context;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              ListTile(
                leading: const Icon(Icons.local_gas_station_outlined),
                title: const Text('Vente carburant'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showAddSale(parentContext, controller);
                },
              ),
              ListTile(
                leading: const Icon(Icons.shopping_bag_outlined),
                title: const Text('Vente produit'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showAddProductSale(parentContext, controller);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBeautifulBottomSheet({
    required BuildContext context,
    required String title,
    required Widget content,
    required List<Widget> Function(BuildContext sheetContext) actionsBuilder,
    RxBool? isLoading,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 12),
              Flexible(child: SingleChildScrollView(child: content)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actionsBuilder(sheetContext),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSessionCard(
    SaleController controller,
    Map<String, Object?>? session,
  ) {
    final pompisteController = Get.find<PompisteController>();
    final isOpen = session != null;
    return Card(
      elevation: 0.9,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOpen ? Icons.lock_open : Icons.lock_outline,
                  color: isOpen ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isOpen ? 'Session ouverte' : 'Aucune session ouverte',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isOpen) ...[
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _miniTag('Code: ${session['code']}'),
                  _miniTag(
                    'Ouverte: ${DateFormat('dd/MM HH:mm').format(DateTime.parse(session['openedAt'] as String))}',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Pompistes: ${((session['pompistes'] as String?)?.isNotEmpty ?? false) ? session['pompistes'] : 'Non renseignés'}',
              ),
            ] else
              const Text(
                'Les ventes ne peuvent etre enregistrees que dans une session ouverte.',
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: isOpen
                      ? null
                      : () async {
                          try {
                            final selectedPompistes =
                                await _showPompisteSelectionDialog(
                                  pompisteController.pompistes,
                                );
                            if (selectedPompistes == null ||
                                selectedPompistes.isEmpty) {
                              return;
                            }
                            await controller.openSession(selectedPompistes);
                            Get.snackbar(
                              'Session',
                              'Session ouverte avec succes',
                            );
                          } catch (e) {
                            Get.snackbar('Erreur', e.toString());
                          }
                        },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Ouvrir session'),
                ),
                OutlinedButton.icon(
                  onPressed: !isOpen
                      ? null
                      : () async {
                          try {
                            await controller.closeActiveSession();
                            Get.snackbar('Session', 'Session fermee');
                          } catch (e) {
                            Get.snackbar('Erreur', e.toString());
                          }
                        },
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('Fermer session'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductSale(BuildContext context, SaleController controller) {
    final qtyController = TextEditingController();
    final selectedProductId = Rx<String?>(null);
    final unitPrice = 0.0.obs;
    final totalAmount = 0.0.obs;
    final isSaving = false.obs;
    final isLoadingData = true.obs;
    final products = <SalesProductModel>[].obs;

    void updateComputedAmount() {
      final qty = double.tryParse(qtyController.text) ?? 0;
      totalAmount.value = qty * unitPrice.value;
    }

    void updateSelectedProduct(String? value) {
      selectedProductId.value = value;
      if (value == null) {
        unitPrice.value = 0;
      } else {
        final selected = products.where((item) => item.id.toString() == value);
        unitPrice.value = selected.isEmpty ? 0 : selected.first.unitPrice;
      }
      updateComputedAmount();
    }

    qtyController.addListener(updateComputedAmount);

    Future<void> loadData() async {
      isLoadingData.value = true;
      try {
        products.value = await _fetchSalesProducts();
        if (products.isNotEmpty) {
          updateSelectedProduct(products.first.id.toString());
        }
      } finally {
        isLoadingData.value = false;
      }
    }

    loadData();
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      _showBeautifulBottomSheet(
        context: context,
        title: 'Nouvelle vente produit',
        isLoading: isLoadingData,
        content: Obx(() {
          if (isLoadingData.value) {
            return const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (products.isEmpty) {
            return const Text(
              'Aucun produit disponible. Ajoutez des produits depuis Paramètres > Produits.',
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedProductId.value,
                decoration: const InputDecoration(labelText: 'Produit'),
                items: products.map((product) {
                  return DropdownMenuItem(
                    value: product.id.toString(),
                    child: Text(
                      '${product.name} (${product.stockQuantity.toStringAsFixed(0)} en stock)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: updateSelectedProduct,
              ),
              TextField(
                controller: qtyController,
                decoration: const InputDecoration(labelText: 'Quantité'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Prix unitaire: ${Formatters.cfa(unitPrice.value)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => InputDecorator(
                  decoration: const InputDecoration(labelText: 'Montant total'),
                  child: Text(
                    Formatters.cfa(totalAmount.value),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          );
        }),
        actionsBuilder: (sheetContext) => [
          TextButton(
            onPressed: () => Navigator.pop(sheetContext),
            child: const Text('Annuler'),
          ),
          Obx(
            () => FilledButton(
              onPressed: (isSaving.value || isLoadingData.value)
                  ? null
                  : () async {
                      final qty = double.tryParse(qtyController.text) ?? 0;
                      if (selectedProductId.value == null || qty <= 0) {
                        Get.snackbar('Erreur', 'Produit/quantité invalides');
                        return;
                      }
                      isSaving.value = true;
                      try {
                        await controller.addProductSale(
                          productId: int.parse(selectedProductId.value!),
                          quantity: qty,
                          amount: totalAmount.value,
                        );
                        qtyController.clear();
                        selectedProductId.value = null;
                        unitPrice.value = 0;
                        totalAmount.value = 0;
                        if (sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
                      } catch (e) {
                        Get.snackbar('Erreur', e.toString());
                      } finally {
                        isSaving.value = false;
                      }
                    },
              child: isSaving.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enregistrer'),
            ),
          ),
        ],
      );
    } else {
      showAdaptiveModal(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Nouvelle vente produit'),
          content: SingleChildScrollView(
            child: Obx(() {
              if (isLoadingData.value) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (products.isEmpty) {
                return const Text(
                  'Aucun produit disponible. Ajoutez des produits depuis Paramètres > Produits.',
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedProductId.value,
                    decoration: const InputDecoration(labelText: 'Produit'),
                    items: products.map((product) {
                      return DropdownMenuItem(
                        value: product.id.toString(),
                        child: Text(
                          '${product.name} (${product.stockQuantity.toStringAsFixed(0)} en stock)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: updateSelectedProduct,
                  ),
                  TextField(
                    controller: qtyController,
                    decoration: const InputDecoration(labelText: 'Quantité'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(
                    () => Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Prix unitaire: ${Formatters.cfa(unitPrice.value)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(
                    () => InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Montant total',
                      ),
                      child: Text(
                        Formatters.cfa(totalAmount.value),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            Obx(
              () => FilledButton(
                onPressed: (isSaving.value || isLoadingData.value)
                    ? null
                    : () async {
                        final qty = double.tryParse(qtyController.text) ?? 0;
                        if (selectedProductId.value == null || qty <= 0) {
                          Get.snackbar('Erreur', 'Produit/quantité invalides');
                          return;
                        }
                        isSaving.value = true;
                        try {
                          await controller.addProductSale(
                            productId: int.parse(selectedProductId.value!),
                            quantity: qty,
                            amount: totalAmount.value,
                          );
                          qtyController.clear();
                          selectedProductId.value = null;
                          unitPrice.value = 0;
                          totalAmount.value = 0;
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          Get.snackbar('Erreur', e.toString());
                        } finally {
                          isSaving.value = false;
                        }
                      },
                child: isSaving.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Enregistrer'),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildClosedSessionsSection(
    SaleController controller,
    List<Map<String, Object?>> sessions,
    bool isMobile,
  ) {
    return Card(
      elevation: 0.8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sessions fermees (lecture seule)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            if (sessions.isEmpty)
              const Text('Aucune session fermee pour le moment.')
            else if (isMobile)
              ExpansionPanelList.radio(
                elevation: 0,
                expandedHeaderPadding: EdgeInsets.zero,
                children: sessions.map((session) {
                  final openedAt = session['openedAt'] as String?;
                  final closedAt = session['closedAt'] as String?;
                  final totalSales =
                      (session['totalSales'] as num?)?.toInt() ?? 0;
                  final totalAmount =
                      (session['totalAmount'] as num?)?.toDouble() ?? 0;
                  final totalProductSales =
                      (session['totalProductSales'] as num?)?.toInt() ?? 0;
                  final totalProductAmount =
                      (session['totalProductAmount'] as num?)?.toDouble() ?? 0;
                  return ExpansionPanelRadio(
                    value: session['id'] ?? session['code'] ?? UniqueKey(),
                    headerBuilder: (context, isExpanded) {
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        leading: const Icon(
                          Icons.lock,
                          color: Colors.redAccent,
                        ),
                        title: Text('${session['code'] ?? '-'}'),
                        subtitle: Text(
                          'Total: ${Formatters.cfa(totalAmount + totalProductAmount)}',
                        ),
                      );
                    },
                    body: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ouverte: ${openedAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(openedAt)) : '-'}',
                          ),
                          Text(
                            'Fermee: ${closedAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(closedAt)) : '-'}',
                          ),
                          Text(
                            'Pompistes: ${((session['pompistes'] as String?)?.isNotEmpty ?? false) ? session['pompistes'] : 'Non renseignés'}',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Carburant: $totalSales (${Formatters.cfa(totalAmount)})',
                          ),
                          Text(
                            'Produits: $totalProductSales (${Formatters.cfa(totalProductAmount)})',
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Wrap(
                              spacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _handleSessionMenuAction(
                                    'print',
                                    controller,
                                    session,
                                  ),
                                  icon: const Icon(
                                    Icons.print_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Imprimer'),
                                ),
                                FilledButton.icon(
                                  onPressed: () => _handleSessionMenuAction(
                                    'share',
                                    controller,
                                    session,
                                  ),
                                  icon: const Icon(
                                    Icons.share_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('PDF'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              )
            else
              ...sessions.map((session) {
                final openedAt = session['openedAt'] as String?;
                final closedAt = session['closedAt'] as String?;
                final totalSales =
                    (session['totalSales'] as num?)?.toInt() ?? 0;
                final totalAmount =
                    (session['totalAmount'] as num?)?.toDouble() ?? 0;
                final totalProductSales =
                    (session['totalProductSales'] as num?)?.toInt() ?? 0;
                final totalProductAmount =
                    (session['totalProductAmount'] as num?)?.toDouble() ?? 0;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 0.6,
                  child: ListTile(
                    leading: const Icon(Icons.lock, color: Colors.redAccent),
                    title: Text('${session['code'] ?? '-'}'),
                    subtitle: Text(
                      'Ouverte: ${openedAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(openedAt)) : '-'}\n'
                      'Fermee: ${closedAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(closedAt)) : '-'}\n'
                      'Pompistes: ${((session['pompistes'] as String?)?.isNotEmpty ?? false) ? session['pompistes'] : 'Non renseignés'}\n'
                      'Carburant: $totalSales (${Formatters.cfa(totalAmount)}) • Produits: $totalProductSales (${Formatters.cfa(totalProductAmount)})',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (action) =>
                          _handleSessionMenuAction(action, controller, session),
                      itemBuilder: (context) => const [
                        /* PopupMenuItem<String>(
                          value: 'preview',
                          child: Row(
                            children: [
                              Icon(Icons.visibility_outlined, size: 20),
                              SizedBox(width: 8),
                              Text('Aperçu'),
                            ],
                          ),
                        ), */
                        PopupMenuItem<String>(
                          value: 'print',
                          child: Row(
                            children: [
                              Icon(Icons.print_outlined, size: 20),
                              SizedBox(width: 8),
                              Text('Imprimer'),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share_outlined, size: 20),
                              SizedBox(width: 8),
                              Text('Partager PDF'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Future<List<int>?> _showPompisteSelectionDialog(
    List<PompisteModel> allPompistes,
  ) async {
    final activePompistes = allPompistes
        .where((item) => item.status.toLowerCase() == 'active')
        .toList();
    if (activePompistes.isEmpty) {
      Get.snackbar('Session', 'Aucun pompiste actif disponible.');
      return null;
    }

    final selectedIds = <int>{};
    return Get.dialog<List<int>>(
      AlertDialog(
        title: const Text('Choisir les pompistes de la session'),
        content: StatefulBuilder(
          builder: (context, setState) => SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: activePompistes.map((pompiste) {
                  final checked = selectedIds.contains(pompiste.id);
                  return CheckboxListTile(
                    value: checked,
                    title: Text(pompiste.name, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      pompiste.phone ?? 'Sans téléphone',
                      overflow: TextOverflow.ellipsis,
                    ),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          selectedIds.add(pompiste.id);
                        } else {
                          selectedIds.remove(pompiste.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: null),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: selectedIds.toList()),
            child: const Text('Ouvrir la session'),
          ),
        ],
      ),
    );
  }

  Future<Uint8List> _buildSessionReportPdf(
    SaleController controller,
    Map<String, Object?> session,
  ) async {
    final baseFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    final sessionId = session['id'] as int;
    final db = await controller.database;

    // Récupérer les informations de la station et le logo
    final settingsRows = await db.query('settings');
    String? stationName = 'Station Service';
    String? logoPath;

    if (settingsRows.isNotEmpty) {
      stationName =
          settingsRows.first['stationName'] as String? ?? 'Station Service';
      logoPath = settingsRows.first['logoPath'] as String?;
    }

    pw.ImageProvider? logoImage;
    if (logoPath != null && logoPath.isNotEmpty) {
      final logoFile = File(logoPath);
      if (await logoFile.exists()) {
        logoImage = pw.MemoryImage(await logoFile.readAsBytes());
      }
    }

    final rows = await db.rawQuery(
      '''
      SELECT s.date, s.liters, s.amount, p.name as pumpName, f.name as fuelName, pn.name as nozzleName
      FROM sales s
      JOIN pumps p ON p.id = s.pumpId
      JOIN fuels f ON f.id = s.fuelId
      LEFT JOIN pump_nozzles pn ON pn.id = s.nozzleId
      WHERE s.sessionId = ?
      ORDER BY s.date ASC
    ''',
      [sessionId],
    );
    final productRows = await db.rawQuery(
      '''
      SELECT ps.date, ps.quantity, ps.amount, sp.name as productName, sp.category
      FROM product_sales ps
      JOIN sales_products sp ON sp.id = ps.productId
      WHERE ps.sessionId = ?
      ORDER BY ps.date ASC
    ''',
      [sessionId],
    );

    final pdf = pw.Document();
    final openedAt = session['openedAt'] as String?;
    final closedAt = session['closedAt'] as String?;
    final totalSales = (session['totalSales'] as num?)?.toInt() ?? 0;
    final totalAmount = (session['totalAmount'] as num?)?.toDouble() ?? 0;

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
                pw.Image(logoImage, width: 80, height: 80)
              else
                pw.SizedBox(width: 80, height: 80),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      stationName ?? 'Station Service',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Bilan de session',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 16),

          // Informations de session
          pw.Text(
            'Session ${session['code'] ?? ''}',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Ouverture: ${openedAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(openedAt)) : '-'}',
          ),
          pw.Text(
            'Fermeture: ${closedAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(closedAt)) : '-'}',
          ),
          pw.Text('Nombre de ventes: $totalSales'),
          pw.Text('Montant total: ${Formatters.cfa(totalAmount)}'),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Date',
              'Pompe',
              'Carburant',
              'Pistolet',
              'Litres',
              'Montant',
            ],
            data: rows.map((row) {
              final date = row['date'] as String;
              return [
                DateFormat('dd/MM HH:mm').format(DateTime.parse(date)),
                '${row['pumpName'] ?? '-'}',
                '${row['fuelName'] ?? '-'}',
                '${row['nozzleName'] ?? '-'}',
                '${(row['liters'] as num).toStringAsFixed(2)} L',
                Formatters.cfa((row['amount'] as num).toDouble()),
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            cellStyle: const pw.TextStyle(fontSize: 10),
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Ventes produits',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          if (productRows.isEmpty)
            pw.Text(
              'Aucune vente produit sur cette session.',
              style: const pw.TextStyle(fontSize: 10),
            )
          else
            pw.TableHelper.fromTextArray(
              headers: const [
                'Date',
                'Produit',
                'Catégorie',
                'Quantité',
                'Montant',
              ],
              data: productRows.map((row) {
                final date = row['date'] as String;
                return [
                  DateFormat('dd/MM HH:mm').format(DateTime.parse(date)),
                  '${row['productName'] ?? '-'}',
                  '${row['category'] ?? '-'}',
                  '${(row['quantity'] as num).toStringAsFixed(2)}',
                  Formatters.cfa((row['amount'] as num).toDouble()),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey800,
              ),
              cellStyle: const pw.TextStyle(fontSize: 10),
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            ),
        ],
      ),
    );

    return pdf.save();
  }

  Future<void> _handleSessionMenuAction(
    String action,
    SaleController controller,
    Map<String, Object?> session,
  ) async {
    final sessionId = session['id'] as int?;
    if (sessionId == null) {
      Get.snackbar('Erreur', 'Session invalide');
      return;
    }

    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      final bytes = await _buildSessionReportPdf(controller, session);
      final code = (session['code'] ?? 'session').toString().toLowerCase();

      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      if (action == 'preview' || action == 'print') {
        await Printing.layoutPdf(onLayout: (_) => bytes);
        return;
      }

      if (action == 'share') {
        await Printing.sharePdf(bytes: bytes, filename: 'bilan-$code.pdf');
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      Get.snackbar('Erreur', 'Impossible de generer le PDF: $e');
    }
  }

  void _showAddSale(BuildContext context, SaleController controller) {
    final litersController = TextEditingController();
    final fuelName = Rx<String>('');
    final selectedPumpId = Rx<String?>(null);
    final selectedFuelId = Rx<String?>(null);
    final selectedNozzleId = Rx<String?>(null);
    final selectedNozzleName = Rx<String?>('');
    final unitPrice = 0.0.obs;
    final totalAmount = 0.0.obs;
    final isSaving = false.obs;
    final isLoadingData = true.obs;
    final pumps = <PumpModel>[].obs;
    final nozzles = <NozzleModel>[].obs;

    void updateComputedAmount() {
      final liters = double.tryParse(litersController.text) ?? 0;
      totalAmount.value = liters * unitPrice.value;
    }

    void updateSelectedNozzle(String? value) {
      selectedNozzleId.value = value;
      if (value == null) {
        selectedNozzleName.value = '';
      } else {
        final selected = nozzles.where((item) => item.id.toString() == value);
        if (selected.isNotEmpty) {
          selectedNozzleName.value = selected.first.name;
        }
      }
    }

    void updateSelectedPump(String? value) {
      selectedPumpId.value = value;
      selectedNozzleId.value = null;
      selectedNozzleName.value = '';
      nozzles.clear();

      if (value == null) {
        selectedFuelId.value = null;
        fuelName.value = '';
        unitPrice.value = 0;
      } else {
        final selected = pumps.where((item) => item.id.toString() == value);
        if (selected.isNotEmpty) {
          final pump = selected.first;
          selectedFuelId.value = pump.fuelId.toString();
          fuelName.value = pump.fuelName;
          unitPrice.value = 0;
          // Fetch the fuel price from controller or database
          _fetchFuelPrice(pump.fuelId).then((price) {
            unitPrice.value = price;
            updateComputedAmount();
          });
          // Charger les pistolets de cette pompe
          _fetchNozzles(pump.id).then((fetchedNozzles) {
            nozzles.value = fetchedNozzles;
            if (nozzles.isNotEmpty) {
              updateSelectedNozzle(nozzles.first.id.toString());
            }
          });
        }
      }
      updateComputedAmount();
    }

    litersController.addListener(updateComputedAmount);

    // Charger les données au démarrage du dialogue
    Future<void> loadData() async {
      isLoadingData.value = true;
      try {
        pumps.value = await _fetchPumps();
        // Définir les valeurs par défaut
        if (pumps.isNotEmpty) {
          updateSelectedPump(pumps.first.id.toString());
        }
      } catch (e) {
        Get.snackbar(
          'Erreur',
          'Impossible de charger les données: ${e.toString()}',
        );
      } finally {
        isLoadingData.value = false;
      }
    }

    loadData();

    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      _showBeautifulBottomSheet(
        context: context,
        title: 'Nouvelle vente carburant',
        isLoading: isLoadingData,
        content: Obx(() {
          if (isLoadingData.value) {
            return const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedPumpId.value,
                decoration: const InputDecoration(labelText: 'Pompe'),
                items: pumps.map((pump) {
                  return DropdownMenuItem(
                    value: pump.id.toString(),
                    child: Text(pump.name, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: updateSelectedPump,
              ),
              const SizedBox(height: 12),
              Obx(
                () => InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Type de carburant',
                    hintText: 'Sélectionnez une pompe',
                  ),
                  child: Text(
                    fuelName.value.isEmpty
                        ? 'Sélectionnez une pompe'
                        : fuelName.value,
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Obx(
                () => DropdownButtonFormField<String>(
                  value: selectedNozzleId.value,
                  decoration: const InputDecoration(labelText: 'Pistolet'),
                  hint: const Text('Sélectionnez un pistolet'),
                  items: nozzles.map((nozzle) {
                    return DropdownMenuItem(
                      value: nozzle.id.toString(),
                      child: Text(nozzle.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: updateSelectedNozzle,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: litersController,
                decoration: const InputDecoration(
                  labelText: 'Litres',
                  hintText: 'Entrez la quantité',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 12),
              Obx(
                () => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Prix/L appliqué: ${Formatters.cfa(unitPrice.value)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => InputDecorator(
                  decoration: const InputDecoration(labelText: 'Montant total'),
                  child: Text(
                    Formatters.cfa(totalAmount.value),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          );
        }),
        actionsBuilder: (sheetContext) => [
          TextButton(
            onPressed: () => Navigator.pop(sheetContext),
            child: const Text('Annuler'),
          ),
          Obx(
            () => FilledButton(
              onPressed: (isSaving.value || isLoadingData.value)
                  ? null
                  : () async {
                      final liters =
                          double.tryParse(litersController.text) ?? 0;
                      final amount = totalAmount.value;

                      if (selectedPumpId.value == null ||
                          selectedFuelId.value == null) {
                        Get.snackbar(
                          'Erreur',
                          'Veuillez sélectionner une pompe',
                        );
                        return;
                      }

                      if (selectedNozzleId.value == null) {
                        Get.snackbar(
                          'Erreur',
                          'Veuillez sélectionner un pistolet',
                        );
                        return;
                      }

                      if (liters <= 0) {
                        Get.snackbar(
                          'Erreur',
                          'Veuillez entrer un nombre de litres valide (> 0)',
                        );
                        return;
                      }

                      if (amount <= 0) {
                        Get.snackbar(
                          'Erreur',
                          'Montant calculé invalide (> 0). Vérifiez les litres et le prix configuré.',
                        );
                        return;
                      }

                      isSaving.value = true;
                      try {
                        final sale = SaleModel(
                          id: 0,
                          pumpId: int.parse(selectedPumpId.value!),
                          fuelId: int.parse(selectedFuelId.value!),
                          nozzleId: int.parse(selectedNozzleId.value!),
                          liters: liters,
                          amount: amount,
                          date: DateTime.now().toIso8601String(),
                        );
                        await controller.addSale(sale);
                        litersController.clear();
                        selectedPumpId.value = null;
                        selectedFuelId.value = null;
                        selectedNozzleId.value = null;
                        selectedNozzleName.value = '';
                        fuelName.value = '';
                        nozzles.clear();
                        unitPrice.value = 0;
                        totalAmount.value = 0;
                        if (sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
                      } catch (e) {
                        Get.snackbar(
                          'Erreur',
                          'Impossible d\'enregistrer la vente: ${e.toString()}',
                        );
                      } finally {
                        isSaving.value = false;
                      }
                    },
              child: isSaving.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Enregistrer'),
            ),
          ),
        ],
      );
    } else {
      showAdaptiveModal(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Nouvelle vente carburant'),
          content: SingleChildScrollView(
            child: Obx(() {
              if (isLoadingData.value) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedPumpId.value,
                    decoration: const InputDecoration(labelText: 'Pompe'),
                    items: pumps.map((pump) {
                      return DropdownMenuItem(
                        value: pump.id.toString(),
                        child: Text(pump.name, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: updateSelectedPump,
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Type de carburant',
                        hintText: 'Sélectionnez une pompe',
                      ),
                      child: Text(
                        fuelName.value.isEmpty
                            ? 'Sélectionnez une pompe'
                            : fuelName.value,
                        style: const TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => DropdownButtonFormField<String>(
                      value: selectedNozzleId.value,
                      decoration: const InputDecoration(labelText: 'Pistolet'),
                      hint: const Text('Sélectionnez un pistolet'),
                      items: nozzles.map((nozzle) {
                        return DropdownMenuItem(
                          value: nozzle.id.toString(),
                          child: Text(
                            nozzle.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: updateSelectedNozzle,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: litersController,
                    decoration: const InputDecoration(
                      labelText: 'Litres',
                      hintText: 'Entrez la quantité',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Prix/L appliqué: ${Formatters.cfa(unitPrice.value)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(
                    () => InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Montant total',
                      ),
                      child: Text(
                        Formatters.cfa(totalAmount.value),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            Obx(
              () => FilledButton(
                onPressed: (isSaving.value || isLoadingData.value)
                    ? null
                    : () async {
                        final liters =
                            double.tryParse(litersController.text) ?? 0;
                        final amount = totalAmount.value;

                        if (selectedPumpId.value == null ||
                            selectedFuelId.value == null) {
                          Get.snackbar(
                            'Erreur',
                            'Veuillez sélectionner une pompe',
                          );
                          return;
                        }

                        if (selectedNozzleId.value == null) {
                          Get.snackbar(
                            'Erreur',
                            'Veuillez sélectionner un pistolet',
                          );
                          return;
                        }

                        if (liters <= 0) {
                          Get.snackbar(
                            'Erreur',
                            'Veuillez entrer un nombre de litres valide (> 0)',
                          );
                          return;
                        }

                        if (amount <= 0) {
                          Get.snackbar(
                            'Erreur',
                            'Montant calculé invalide (> 0). Vérifiez les litres et le prix configuré.',
                          );
                          return;
                        }

                        isSaving.value = true;
                        try {
                          final sale = SaleModel(
                            id: 0,
                            pumpId: int.parse(selectedPumpId.value!),
                            fuelId: int.parse(selectedFuelId.value!),
                            nozzleId: int.parse(selectedNozzleId.value!),
                            liters: liters,
                            amount: amount,
                            date: DateTime.now().toIso8601String(),
                          );
                          await controller.addSale(sale);
                          litersController.clear();
                          selectedPumpId.value = null;
                          selectedFuelId.value = null;
                          selectedNozzleId.value = null;
                          selectedNozzleName.value = '';
                          fuelName.value = '';
                          nozzles.clear();
                          unitPrice.value = 0;
                          totalAmount.value = 0;
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          Get.snackbar(
                            'Erreur',
                            'Impossible d\'enregistrer la vente: ${e.toString()}',
                          );
                        } finally {
                          isSaving.value = false;
                        }
                      },
                child: isSaving.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text('Enregistrer'),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<double> _fetchFuelPrice(int fuelId) async {
    try {
      final db = await Get.find<SaleController>().database;
      final rows = await db.query(
        'fuels',
        where: 'id = ?',
        whereArgs: [fuelId],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        return (rows.first['pricePerLiter'] as num).toDouble();
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération du prix: $e');
    }
    return 0.0;
  }

  Future<List<NozzleModel>> _fetchNozzles(int pumpId) async {
    try {
      final db = await Get.find<SaleController>().database;
      final rows = await db.query(
        'pump_nozzles',
        where: 'pumpId = ?',
        whereArgs: [pumpId],
        orderBy: 'name ASC',
      );
      return rows.map((row) => NozzleModel.fromMap(row)).toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des pistolets: $e');
      return [];
    }
  }

  Future<List<PumpModel>> _fetchPumps() async {
    final db = await Get.find<SaleController>().database;
    final rows = await db.rawQuery('''
      SELECT p.*, f.name as fuelName
      FROM pumps p
      JOIN fuels f ON f.id = p.fuelId
      WHERE p.status = 'active'
    ''');
    return rows.map((row) => PumpModel.fromMap(row)).toList();
  }

  Future<List<SalesProductModel>> _fetchSalesProducts() async {
    final db = await Get.find<SaleController>().database;
    final rows = await db.query('sales_products', orderBy: 'name ASC');
    return rows.map((row) => SalesProductModel.fromMap(row)).toList();
  }

  Widget _buildProductSalesSection(
    List<ProductSaleModel> productSales,
    bool isMobile,
  ) {
    return Card(
      elevation: 0.8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ventes produits (huile, gaz, etc.)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            if (productSales.isEmpty)
              const Text('Aucune vente produit enregistrée.')
            else if (isMobile)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'Afficher les ventes produits (${productSales.length})',
                ),
                children: productSales.take(12).map((sale) {
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.shopping_bag_outlined),
                    title: Text(
                      sale.productName,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    subtitle: Text(
                      '${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(sale.date))} • Qté: ${sale.quantity.toStringAsFixed(2)}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    trailing: Text(Formatters.cfa(sale.amount)),
                  );
                }).toList(),
              )
            else
              ...productSales.take(8).map((sale) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.shopping_bag_outlined),
                  title: Text(
                    sale.productName,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  subtitle: Text(
                    '${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(sale.date))} • Qté: ${sale.quantity.toStringAsFixed(2)}',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  trailing: Text(Formatters.cfa(sale.amount)),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesRevenueChart(List<SaleModel> sales) {
    if (sales.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        elevation: 0.8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Evolution du chiffre d\'affaires',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('Aucune vente disponible pour générer le graphique.'),
            ],
          ),
        ),
      );
    }

    final sortedSales = [
      ...sales,
    ]..sort((a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));
    final byDay = <DateTime, double>{};
    for (final sale in sortedSales) {
      final dt = DateTime.parse(sale.date);
      final day = DateTime(dt.year, dt.month, dt.day);
      byDay[day] = (byDay[day] ?? 0) + sale.amount;
    }
    final sortedDays = byDay.keys.toList()..sort((a, b) => a.compareTo(b));
    final values = sortedDays.map((day) => byDay[day] ?? 0).toList();

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0.8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Evolution du chiffre d\'affaires',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final baseWidth = constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : MediaQuery.of(context).size.width;
                final chartWidth = max(baseWidth, sortedDays.length * 56.0);
                return HorizontalHistoryChart(
                  height: 220,
                  contentWidth: chartWidth,
                  child: CustomPaint(
                    painter: _SalesRevenueLinePainter(sortedDays, values),
                    child: Container(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SalesRevenueLinePainter extends CustomPainter {
  _SalesRevenueLinePainter(this.days, this.values);

  final List<DateTime> days;
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    const margin = 12.0;
    const leftMargin = 40.0;
    const bottomMargin = 36.0;
    final chartWidth = size.width - leftMargin - margin;
    final chartHeight = size.height - bottomMargin - margin;

    final minValue = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.isEmpty
        ? 10.0
        : values.reduce((a, b) => a > b ? a : b);
    final baseRange = maxValue - minValue;
    final padding = baseRange == 0
        ? max(maxValue.abs() * 0.03, 0.1)
        : max(baseRange * 0.04, 0.1);
    final yMin = max(0.0, minValue - padding);
    final yMax = max(maxValue + padding, yMin + 0.5);
    final valueRange = yMax - yMin;

    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = const Color(0xFF388E3C)
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke;
    final pointPaint = Paint()..color = const Color(0xFF2E7D32);

    for (var i = 0; i <= 4; i++) {
      final y = margin + chartHeight - (chartHeight / 4 * i);
      canvas.drawLine(
        Offset(leftMargin, y),
        Offset(size.width - margin, y),
        gridPaint,
      );
      final valueLabel = (yMin + (valueRange / 4 * i)).round();
      final tp = TextPainter(
        text: TextSpan(
          text: valueLabel.toString(),
          style: const TextStyle(color: Colors.black54, fontSize: 10),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftMargin - tp.width - 6, y - tp.height / 2));
    }

    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = leftMargin + (chartWidth / max(values.length - 1, 1)) * i;
      final y =
          margin +
          chartHeight -
          ((values[i] - yMin) / valueRange) * chartHeight;
      points.add(Offset(x, y));
    }
    if (points.isNotEmpty) {
      final smoothPath = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        final previous = points[i - 1];
        final current = points[i];
        final controlX = (previous.dx + current.dx) / 2;
        smoothPath.cubicTo(
          controlX,
          previous.dy,
          controlX,
          current.dy,
          current.dx,
          current.dy,
        );
      }
      final areaPath = Path.from(smoothPath)
        ..lineTo(points.last.dx, margin + chartHeight)
        ..lineTo(points.first.dx, margin + chartHeight)
        ..close();
      final areaPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, margin),
          Offset(0, margin + chartHeight),
          [
            const Color(0xFF43A047).withValues(alpha: 0.28),
            const Color(0xFF43A047).withValues(alpha: 0.04),
          ],
        );
      canvas.drawPath(areaPath, areaPaint);
      canvas.drawPath(smoothPath, linePaint);

      for (final p in points) {
        canvas.drawCircle(p, 4, Paint()..color = Colors.white);
        canvas.drawCircle(p, 2.4, pointPaint);
      }
    }

    for (var i = 0; i < days.length; i++) {
      if (days.length > 8 &&
          (i % ((days.length / 6).ceil()) != 0) &&
          i != days.length - 1) {
        continue;
      }
      final x = leftMargin + (chartWidth / max(days.length - 1, 1)) * i;
      final label = DateFormat('dd/MM').format(days[i]);
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: Colors.black87, fontSize: 10),
        ),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: 50);
      tp.paint(canvas, Offset(x - tp.width / 2, margin + chartHeight + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _SalesRevenueLinePainter oldDelegate) {
    return !listEquals(days, oldDelegate.days) ||
        !listEquals(values, oldDelegate.values);
  }
}

Widget _buildFuelSalesSection(List<SaleModel> sales, bool isMobile) {
  if (sales.isEmpty) {
    return const Center(child: Text('Aucune vente encore enregistrée.'));
  }
  if (isMobile) {
    return Card(
      elevation: 0.8,
      child: ExpansionTile(
        title: Text('Ventes carburant (${sales.length})'),
        children: sales.take(15).map((sale) {
          return ListTile(
            dense: true,
            title: Text(
              '${sale.pumpName ?? 'Pompe'} • ${sale.fuelName ?? 'Carburant'} • Pistolet: ${sale.nozzleName ?? '-'}',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            subtitle: Text(
              '${DateFormat('dd/MM HH:mm').format(DateTime.parse(sale.date))} • ${sale.sessionCode ?? 'Sans session'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(Formatters.cfa(sale.amount)),
          );
        }).toList(),
      ),
    );
  }
  return Column(
    children: sales.map((sale) {
      return Card(
        elevation: 0.8,
        margin:EdgeInsets.only(bottom: 5),
        child: ListTile(
          title: Text(
            '${sale.pumpName ?? 'Pompe'} • ${sale.fuelName ?? 'Carburant'} • Pistolet: ${sale.nozzleName ?? '-'}',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          subtitle: Text(
            '${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(sale.date))} • ${sale.clientName ?? 'Sans client'} • ${sale.sessionCode ?? 'Sans session'}',
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          trailing: Text(Formatters.cfa(sale.amount)),
        ),
      );
    }).toList(),
  );
}

Widget _miniTag(String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(text, style: const TextStyle(fontSize: 12)),
  );
}
