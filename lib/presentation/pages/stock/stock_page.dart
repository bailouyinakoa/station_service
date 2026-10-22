import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:station_service_app/core/constants/app_strings.dart';
import 'package:station_service_app/data/models/fuel_model.dart';
import 'package:station_service_app/data/models/stock_movement_model.dart';
import 'package:station_service_app/presentation/controllers/stock_controller.dart';
import 'package:station_service_app/presentation/widgets/adaptive_modal.dart';
import 'package:station_service_app/presentation/widgets/horizontal_history_chart.dart';
import 'package:station_service_app/presentation/widgets/responsive_scaffold.dart';

final _defaultTextDirection = ui.TextDirection.ltr;

class StockPage extends StatelessWidget {
  const StockPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StockController>();

    return ResponsiveScaffold(
      title: AppStrings.stockTitle,
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return FutureBuilder<List<FuelModel>>(
          future: _fetchFuelsStock(),
          builder: (context, snapshot) {
            final chartSection = snapshot.hasData
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStockBarChart(snapshot.data!),
                      const SizedBox(height: 12),
                      _buildMovementLineChart(controller.movements),
                      const SizedBox(height: 16),
                    ],
                  )
                : const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );

            final movements = controller.movements;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                chartSection,
                if (movements.isEmpty)
                  const Center(
                    child: Text('Aucun mouvement encore enregistré.'),
                  )
                else
                  ...movements.map((movement) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(
                          '${movement.fuelName} • ${movement.type == 'entry' ? 'Entrée' : 'Sortie'}',
                        ),
                        subtitle: Text(
                          '${movement.note ?? ''} • ${DateFormat('dd/MM/yyyy').format(DateTime.parse(movement.date))}',
                        ),
                        trailing: Text(
                          '${movement.liters.toStringAsFixed(1)} L',
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 100),
              ],
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMovementDialog(context, controller),
        icon: const Icon(Icons.inventory_2),
        label: const Text('Ajouter mouvement'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  void _showMovementDialog(BuildContext context, StockController controller) {
    final typeController = TextEditingController(text: 'entry');
    final litersController = TextEditingController();
    final noteController = TextEditingController();
    String? selectedFuelId;
    final isSaving = false.obs;
    final isLoadingData = true.obs;

    // Charger les données au démarrage du dialogue
    Future<void> loadData() async {
      isLoadingData.value = true;
      await _fetchFuels();
      isLoadingData.value = false;
    }

    loadData();

    showAdaptiveModal(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mouvement de stock'),
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
                FutureBuilder<List<FuelModel>>(
                  future: _fetchFuels(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return DropdownButtonFormField<String>(
                        initialValue: selectedFuelId,
                        decoration: const InputDecoration(
                          labelText: 'Carburant',
                        ),
                        items: snapshot.data!.map((fuel) {
                          return DropdownMenuItem(
                            value: fuel.id.toString(),
                            child: Text(fuel.name),
                          );
                        }).toList(),
                        onChanged: (value) => selectedFuelId = value,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                DropdownButtonFormField<String>(
                  initialValue: typeController.text,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'entry', child: Text('Entrée')),
                    DropdownMenuItem(value: 'exit', child: Text('Sortie')),
                  ],
                  onChanged: (value) => typeController.text = value ?? 'entry',
                ),
                TextField(
                  controller: litersController,
                  decoration: const InputDecoration(labelText: 'Litres'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(labelText: 'Note'),
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
                      if (selectedFuelId != null) {
                        isSaving.value = true;
                        try {
                          final movement = StockMovementModel(
                            id: 0,
                            fuelId: int.parse(selectedFuelId!),
                            type: typeController.text,
                            liters: double.tryParse(litersController.text) ?? 0,
                            date: DateTime.now().toIso8601String(),
                            note: noteController.text,
                            fuelName: 'Carburant',
                          );
                          await controller.addMovement(movement);
                          typeController.clear();
                          litersController.clear();
                          noteController.clear();
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          Get.snackbar(
                            'Erreur',
                            'Impossible d\'ajouter le mouvement',
                          );
                        } finally {
                          isSaving.value = false;
                        }
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
                  : const Text('Ajouter'),
            ),
          ),
        ],
      ),
    );
  }

  Future<List<FuelModel>> _fetchFuels() async {
    final db = await Get.find<StockController>().database;
    final rows = await db.query('fuels');
    return rows.map((row) => FuelModel.fromMap(row)).toList();
  }

  Future<List<FuelModel>> _fetchFuelsStock() async {
    final db = await Get.find<StockController>().database;
    final rows = await db.query('fuels');
    return rows.map((row) => FuelModel.fromMap(row)).toList();
  }

  Widget _buildStockBarChart(List<FuelModel> fuels) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stock actuel par carburant',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: CustomPaint(
                painter: _FuelStockBarPainter(fuels),
                child: Container(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovementLineChart(List<StockMovementModel> movements) {
    if (movements.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          'Aucun mouvement de stock enregistré pour afficher la courbe.',
        ),
      );
    }

    final movementByDay = <DateTime, double>{};
    for (final movement in movements) {
      final date = DateTime.parse(movement.date);
      final dayDate = DateTime(date.year, date.month, date.day);
      movementByDay[dayDate] =
          (movementByDay[dayDate] ?? 0) +
          (movement.type == 'entry' ? movement.liters : -movement.liters);
    }

    final sortedDays = movementByDay.keys.toList()..sort();
    var running = 0.0;
    final values = sortedDays.map((day) {
      running += movementByDay[day] ?? 0;
      return running;
    }).toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Evolution cumulée des mouvements de stock',
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
                    painter: _StockMovementLinePainter(sortedDays, values),
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

class _FuelStockBarPainter extends CustomPainter {
  _FuelStockBarPainter(this.fuels);

  final List<FuelModel> fuels;

  @override
  void paint(Canvas canvas, Size size) {
    const margin = 12.0;
    const leftMargin = 40.0;
    const bottomMargin = 32.0;
    final chartWidth = size.width - leftMargin - margin;
    final chartHeight = size.height - bottomMargin - margin;
    final maxStock = fuels
        .map((fuel) => fuel.stockLiters)
        .fold<double>(0, (prev, value) => max(prev, value));
    final yMax = max(maxStock, 10.0);
    final yInterval = yMax / 4;
    final backgroundPaint = Paint()
      ..color = Colors.blue.shade50
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(leftMargin, margin, chartWidth, chartHeight),
        const Radius.circular(16),
      ),
      backgroundPaint,
    );

    final axisPaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1;
    final zeroLinePaint = Paint()
      ..color = const Color(0xFF9CA3AF)
      ..strokeWidth = 1.2;

    for (var i = 0; i <= 4; i++) {
      final y = margin + chartHeight - (chartHeight / 4 * i);
      canvas.drawLine(
        Offset(leftMargin, y),
        Offset(size.width - margin, y),
        axisPaint,
      );
      final label = (yInterval * i).round().toString();
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: Colors.black54, fontSize: 10),
        ),
        textDirection: _defaultTextDirection,
      )..layout();
      tp.paint(canvas, Offset(leftMargin - tp.width - 6, y - tp.height / 2));
    }
    canvas.drawLine(
      Offset(leftMargin, margin + chartHeight),
      Offset(size.width - margin, margin + chartHeight),
      zeroLinePaint,
    );

    final barWidth = chartWidth / max(fuels.length * 2, 1);
    for (var i = 0; i < fuels.length; i++) {
      final fuel = fuels[i];
      final x = leftMargin + margin / 2 + i * 2 * barWidth;
      final normalized = fuel.stockLiters / yMax;
      final barHeight = normalized * chartHeight;
      final barTop = margin + chartHeight - barHeight;
      final barPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(x, barTop),
          Offset(x, barTop + barHeight),
          const [Color(0xFF1D4ED8), Color(0xFF60A5FA)],
        );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, barTop, barWidth, barHeight),
          const Radius.circular(10),
        ),
        barPaint,
      );

      final valueLabel = '${fuel.stockLiters.toStringAsFixed(0)} L';
      final valueTp = TextPainter(
        text: TextSpan(
          text: valueLabel,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: _defaultTextDirection,
      )..layout(maxWidth: barWidth * 1.8);
      valueTp.paint(
        canvas,
        Offset(x + (barWidth - valueTp.width) / 2, barTop - valueTp.height - 6),
      );

      final label = fuel.name.length > 6
          ? '${fuel.name.substring(0, 6)}..'
          : fuel.name;
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: Colors.black87, fontSize: 10),
        ),
        textDirection: _defaultTextDirection,
        textAlign: TextAlign.center,
      )..layout(maxWidth: barWidth * 1.8);
      tp.paint(
        canvas,
        Offset(x - (tp.width - barWidth) / 2, margin + chartHeight + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FuelStockBarPainter oldDelegate) {
    return !listEquals(fuels, oldDelegate.fuels);
  }
}

class _StockMovementLinePainter extends CustomPainter {
  _StockMovementLinePainter(this.days, this.values);

  final List<DateTime> days;
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    const margin = 12.0;
    const leftMargin = 40.0;
    const bottomMargin = 36.0;
    final chartWidth = size.width - leftMargin - margin;
    final chartHeight = size.height - bottomMargin - margin;
    final minValue = values.reduce(min);
    final maxValue = values.reduce(max);
    final baseRange = maxValue - minValue;
    final padding = baseRange == 0
        ? max(maxValue.abs() * 0.1, 1.0)
        : max(baseRange * 0.08, 1.0);
    var yMin = minValue - padding;
    var yMax = maxValue + padding;
    if (yMin > 0) {
      yMin = 0;
    }
    if (yMax < 0) {
      yMax = 0;
    }
    final valueRange = max(yMax - yMin, 1.0);

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
      final labelValue = (yMin + valueRange / 4 * i).round();
      final tp = TextPainter(
        text: TextSpan(
          text: labelValue.toString(),
          style: const TextStyle(color: Colors.black54, fontSize: 10),
        ),
        textDirection: _defaultTextDirection,
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
      final x = leftMargin + (chartWidth / max(days.length - 1, 1)) * i;
      final label = DateFormat('dd/MM').format(days[i]);
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: Colors.black87, fontSize: 10),
        ),
        textDirection: _defaultTextDirection,
        textAlign: TextAlign.center,
      )..layout(maxWidth: 50);
      tp.paint(canvas, Offset(x - tp.width / 2, margin + chartHeight + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _StockMovementLinePainter oldDelegate) {
    return !listEquals(days, oldDelegate.days) ||
        !listEquals(values, oldDelegate.values);
  }
}
