import 'package:station_service_app/domain/entities/report_summary.dart';

abstract class ReportRepository {
  Future<ReportSummary> getDailyReport();
  Future<ReportSummary> getMonthlyReport();
  Future<ReportSummary> getAnnualReport();
}
