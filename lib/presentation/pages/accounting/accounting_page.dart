import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:station_service_app/core/utils/formatters.dart';
import 'package:station_service_app/presentation/controllers/accounting_controller.dart';
import 'package:station_service_app/presentation/widgets/responsive_scaffold.dart';

class AccountingPage extends StatelessWidget {
  const AccountingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AccountingController>();
    return ResponsiveScaffold(
      title: 'Comptabilité',
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: controller.refreshAccounting,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 0.9,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Rapport de bénéfice', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Ventes carburant: ${Formatters.cfa(controller.totalFuelSales.value)}'),
                      Text('Ventes produits: ${Formatters.cfa(controller.totalProductSales.value)}'),
                      Text('Dépenses: ${Formatters.cfa(controller.totalExpenses.value)}'),
                      const Divider(),
                      Text(
                        'Bénéfice net: ${Formatters.cfa(controller.totalProfit.value)}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _trendCard('Évolution des ventes', controller.salesTrend, const Color(0xFF2563EB)),
              const SizedBox(height: 12),
              _trendCard('Évolution des dépenses', controller.expensesTrend, const Color(0xFFDC2626)),
              const SizedBox(height: 12),
              _trendCard('Évolution des bénéfices', controller.profitTrend, const Color(0xFF16A34A)),
              const SizedBox(height: 14),
              const Text('Dépenses récentes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 8),
              if (controller.expensesRows.isEmpty)
                const Text('Aucune dépense.')
              else
                ...controller.expensesRows.map((e) => Card(
                      elevation: 0.7,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text('${e['motif'] ?? '-'}'),
                        subtitle: Text(
                          '${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse('${e['date']}'))} • ${e['paymentType'] ?? '-'} • ${e['supplierName'] ?? 'Sans fournisseur'}',
                        ),
                        trailing: Text(Formatters.cfa((e['amount'] as num?)?.toDouble() ?? 0)),
                      ),
                    )),
            ],
          ),
        );
      }),
    );
  }

  Widget _trendCard(String title, List<Map<String, Object>> series, Color color) {
    return Card(
      elevation: 0.8,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            SizedBox(
              height: 190,
              child: CustomPaint(
                painter: _SimpleLinePainter(series: series, color: color),
                child: Container(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleLinePainter extends CustomPainter {
  _SimpleLinePainter({required this.series, required this.color});

  final List<Map<String, Object>> series;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const l = 38.0;
    const b = 30.0;
    const t = 10.0;
    const r = 8.0;
    final w = size.width - l - r;
    final h = size.height - t - b;
    if (series.isEmpty) return;
    final values = series.map((e) => (e['value'] as num).toDouble()).toList();
    final minV = values.reduce(min);
    final maxV = values.reduce(max);
    final yMin = min(minV, 0);
    final yMax = max(maxV, 0);
    final yRange = max(yMax - yMin, 1.0);

    final grid = Paint()..color = Colors.grey.shade300..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = t + h - (h / 4 * i);
      canvas.drawLine(Offset(l, y), Offset(size.width - r, y), grid);
      final val = (yMin + (yRange / 4 * i)).round();
      final tp = TextPainter(
        text: TextSpan(text: '$val', style: const TextStyle(fontSize: 10, color: Colors.black54)),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(l - tp.width - 4, y - tp.height / 2));
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke;
    final pointPaint = Paint()..color = color.withValues(alpha: 0.9);
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = l + (w / max(values.length - 1, 1)) * i;
      final y = t + h - ((values[i] - yMin) / yRange) * h;
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
        ..lineTo(points.last.dx, t + h)
        ..lineTo(points.first.dx, t + h)
        ..close();
      final areaPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, t),
          Offset(0, t + h),
          [color.withValues(alpha: 0.28), color.withValues(alpha: 0.04)],
        );
      canvas.drawPath(areaPath, areaPaint);
      canvas.drawPath(smoothPath, linePaint);

      for (final p in points) {
        canvas.drawCircle(p, 4, Paint()..color = Colors.white);
        canvas.drawCircle(p, 2.4, pointPaint);
      }
    }

    for (var i = 0; i < series.length; i++) {
      if (series.length > 7 && (i % ((series.length / 6).ceil()) != 0) && i != series.length - 1) {
        continue;
      }
      final x = l + (w / max(series.length - 1, 1)) * i;
      final day = (series[i]['day'] as String).substring(5);
      final tp = TextPainter(
        text: TextSpan(text: day, style: const TextStyle(fontSize: 10, color: Colors.black87)),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, t + h + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _SimpleLinePainter oldDelegate) {
    return oldDelegate.series != series || oldDelegate.color != color;
  }
}
