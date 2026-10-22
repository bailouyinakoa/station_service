import 'package:station_service_app/domain/entities/report_summary.dart';

class ReportSummaryModel extends ReportSummary {
  ReportSummaryModel({
    required super.totalSales,
    required super.fuelSales,
    required super.productSales,
    required super.revenue,
    required super.fuelRevenue,
    required super.productRevenue,
  });

  factory ReportSummaryModel.fromMap(Map<String, Object?> map) {
    final fuelSales = (map['fuelSales'] as num?)?.toInt() ?? 0;
    final productSales = (map['productSales'] as num?)?.toInt() ?? 0;
    final fuelRevenue = (map['fuelRevenue'] as num?)?.toDouble() ?? 0;
    final productRevenue = (map['productRevenue'] as num?)?.toDouble() ?? 0;
    return ReportSummaryModel(
      totalSales: fuelSales + productSales,
      fuelSales: fuelSales,
      productSales: productSales,
      revenue: fuelRevenue + productRevenue,
      fuelRevenue: fuelRevenue,
      productRevenue: productRevenue,
    );
  }
}
