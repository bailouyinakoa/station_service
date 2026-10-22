import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:station_service_app/core/database/database_helper.dart';

class AlertMonitoringService {
  AlertMonitoringService._();
  static final AlertMonitoringService instance = AlertMonitoringService._();
  static const String notificationsEnabledKey = 'notifications_enabled';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  Timer? _monitorTimer;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/notification',
    );
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Ouvrir',
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      linux: linuxSettings,
    );
    await _notifications.initialize(
      settings: initSettings,
    );

    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();

    _initialized = true;
    _startMonitoring();
    await runAlertChecks(force: true);
  }

  void _startMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(const Duration(hours: 1), (_) {
      runAlertChecks();
    });
  }

  Future<void> runAlertChecks({bool force = false}) async {
    if (!_initialized) return;
    if (!await areNotificationsEnabled()) return;
    await _checkFuelLowStockAlerts(force: force);
    await _checkProductLowStockAlerts(force: force);
    await _checkLicenseAlerts(force: force);
  }

  Future<void> _checkFuelLowStockAlerts({bool force = false}) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT id, name, stockLiters, lowStockThreshold
      FROM fuels
      WHERE stockLiters <= lowStockThreshold
    ''');
    for (final row in rows) {
      final id = row['id'] as int;
      final name = '${row['name']}';
      final stock = (row['stockLiters'] as num).toDouble();
      final threshold = (row['lowStockThreshold'] as num).toDouble();
      final key = 'fuel_low_$id';
      final allowed = await _shouldNotify(
        key: key,
        minInterval: const Duration(hours: 1),
        force: force,
      );
      if (!allowed) continue;

      await _showNotification(
        id: 1000 + id,
        title: 'Stock carburant faible',
        body:
            '$name est presque fini (${stock.toStringAsFixed(1)}L, seuil ${threshold.toStringAsFixed(1)}L).',
      );
    }
  }

  Future<void> _checkProductLowStockAlerts({bool force = false}) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT id, name, stockQuantity, lowStockThreshold
      FROM sales_products
      WHERE stockQuantity <= lowStockThreshold
    ''');
    for (final row in rows) {
      final id = row['id'] as int;
      final name = '${row['name']}';
      final stock = (row['stockQuantity'] as num).toDouble();
      final threshold = (row['lowStockThreshold'] as num).toDouble();
      final key = 'product_low_$id';
      final allowed = await _shouldNotify(
        key: key,
        minInterval: const Duration(hours: 1),
        force: force,
      );
      if (!allowed) continue;

      await _showNotification(
        id: 2000 + id,
        title: 'Stock produit faible',
        body:
            '$name est presque fini (${stock.toStringAsFixed(1)}, seuil ${threshold.toStringAsFixed(1)}).',
      );
    }
  }

  Future<void> _checkLicenseAlerts({bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final expiryRaw = prefs.getString('licence_expiry');
    if (expiryRaw == null) return;
    final expiry = DateTime.tryParse(expiryRaw);
    if (expiry == null) return;

    final remaining = expiry.difference(DateTime.now());
    if (remaining.inSeconds <= 0) {
      final allowed = await _shouldNotify(
        key: 'license_expired',
        minInterval: const Duration(hours: 1),
        force: force,
      );
      if (allowed) {
        await _showNotification(
          id: 3001,
          title: 'Licence expirée',
          body: 'Votre licence a expiré. Veuillez la renouveler.',
        );
      }
      return;
    }

    if (remaining.inDays <= 1) {
      final allowed = await _shouldNotify(
        key: 'license_critical',
        minInterval: const Duration(hours: 1),
        force: force,
      );
      if (allowed) {
        await _showNotification(
          id: 3002,
          title: 'Licence critique',
          body:
              'Il reste ${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m avant expiration.',
        );
      }
    } else if (remaining.inDays < 5) {
      final allowed = await _shouldNotify(
        key: 'license_warning',
        minInterval: const Duration(hours: 6),
        force: force,
      );
      if (allowed) {
        await _showNotification(
          id: 3003,
          title: 'Licence bientôt expirée',
          body: 'Il reste ${remaining.inDays} jour(s) de licence.',
        );
      }
    }
  }

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'stock_license_alerts',
      'Alertes stock et licence',
      channelDescription: 'Notifications pour stock faible et licence',
      importance: Importance.high,
      priority: Priority.high,
    );
    const linuxDetails = LinuxNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      linux: linuxDetails,
    );
    await _notifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  Future<bool> _shouldNotify({
    required String key,
    required Duration minInterval,
    bool force = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (force) {
      await prefs.setInt('notif_$key', DateTime.now().millisecondsSinceEpoch);
      return true;
    }
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final lastMs = prefs.getInt('notif_$key');
    if (lastMs != null) {
      final elapsed = Duration(milliseconds: nowMs - lastMs);
      if (elapsed < minInterval) {
        return false;
      }
    }
    await prefs.setInt('notif_$key', nowMs);
    return true;
  }

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(notificationsEnabledKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(notificationsEnabledKey, enabled);
  }
}
