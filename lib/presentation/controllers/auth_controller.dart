import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:station_service_app/core/routes/app_routes.dart';
import 'package:station_service_app/core/database/database_helper.dart';
import 'package:station_service_app/domain/entities/user.dart';
import 'package:station_service_app/services/alert_monitoring_service.dart';
import 'dart:async';

class AuthController extends GetxController {
  static const _userIdKey = 'userId';
  final _isLoading = false.obs;
  final _user = Rxn<User>();
  final users = <User>[].obs;
  final _error = ''.obs;
  final licenceValide = false.obs;
  final dateExpiration = Rxn<DateTime>();
  final joursRestants = 0.obs;
  final remainingDuration = Duration.zero.obs;
  final lastLicenseRefresh = Rxn<DateTime>();
  Timer? _licenseTimer;
  bool _hasHandledLicenseExpiration = false;
  final errorMessage = "".obs;
  final successMessage = "".obs;

  bool get isLoading => _isLoading.value;
  User? get user => _user.value;
  String get error => _error.value;
  bool get isAdmin => user?.role == 'admin';

  @override
  void onInit() {
    super.onInit();
    _startLicenseRefreshTimer();
    _restoreSession();
  }

  @override
  void onClose() {
    _licenseTimer?.cancel();
    super.onClose();
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_userIdKey);
    if (userId == null) return;
    await refreshLicenseStatus();
    if (!licenceValide.value) return;
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        final row = rows.first;
        _user.value = User(
          id: row['id'] as int,
          username: row['username'] as String,
          name: row['name'] as String,
          role: row['role'] as String,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          // Check if onboarding is complete
          final isFirstLaunch = await _checkIfFirstLaunch();
          final onboardingCompleted = await _hasCompletedOnboarding();

          if (isFirstLaunch && !onboardingCompleted) {
            if (Get.currentRoute != AppRoutes.onboardingStation) {
              Get.offAllNamed(AppRoutes.onboardingStation);
            }
          } else {
            if (Get.currentRoute != AppRoutes.dashboard) {
              Get.offAllNamed(AppRoutes.dashboard);
            }
          }
        });
      }
    } catch (_) {
      // Ignore restore failures and let the user sign in normally.
    }
  }

  Future<void> _saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
  }

  Future<void> _clearSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove("licence_key");
    await prefs.remove("licence_expiry");
  }

  Future<void> login(String username, String password) async {
    _isLoading.value = true;
    _error.value = '';
    try {
      final db = await DatabaseHelper.instance.database;
      // Ensure test users exist
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM users');
      final userCount = result.isNotEmpty ? result.first['count'] as int : 0;
      if (userCount == 0) {
        await db.insert('users', {
          'username': 'admin',
          'password': 'admin123',
          'role': 'admin',
          'name': 'Administrateur',
        });
        await db.insert('users', {
          'username': 'caissier',
          'password': 'caissier123',
          'role': 'caissier',
          'name': 'Caissier',
        });
      }
      final rows = await db.query(
        'users',
        where: 'username = ? AND password = ?',
        whereArgs: [username, password],
      );
      if (rows.isEmpty) {
        _error.value = 'Identifiants invalides';
      } else {
        final row = rows.first;
        _user.value = User(
          id: row['id'] as int,
          username: row['username'] as String,
          name: row['name'] as String,
          role: row['role'] as String,
        );
        await _saveUserId(_user.value!.id);

        // Check if this is first launch
        final isFirstLaunch = await _checkIfFirstLaunch();
        final onboardingCompleted = await _hasCompletedOnboarding();

        if (isFirstLaunch && !onboardingCompleted) {
          Get.offAllNamed(AppRoutes.onboardingStation);
        } else {
          Get.offAllNamed(AppRoutes.dashboard);
        }
      }
    } catch (e) {
      _error.value = 'Erreur de connexion';
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loadUsers() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'users',
      columns: ['id', 'username', 'name', 'role'],
      orderBy: "CASE role WHEN 'admin' THEN 0 ELSE 1 END, name ASC",
    );
    users.value = rows
        .map(
          (row) => User(
            id: row['id'] as int,
            username: row['username'] as String,
            name: row['name'] as String,
            role: row['role'] as String,
          ),
        )
        .toList();
  }

  bool requireAdmin({String message = 'Action réservée à l\'administrateur.'}) {
    if (isAdmin) return true;
    Get.snackbar('Accès refusé', message, snackPosition: SnackPosition.BOTTOM);
    return false;
  }

  Future<bool> createAgentUser({
    required String name,
    required String username,
    required String password,
    String role = 'gerant',
  }) async {
    if (!requireAdmin(
      message: 'Seul l\'administrateur peut créer un compte agent.',
    )) {
      return false;
    }

    final normalizedUsername = username.trim();
    if (normalizedUsername.isEmpty || name.trim().isEmpty || password.isEmpty) {
      _error.value = 'Veuillez remplir tous les champs';
      return false;
    }

    _isLoading.value = true;
    _error.value = '';
    try {
      final db = await DatabaseHelper.instance.database;
      final exists = await db.query(
        'users',
        where: 'lower(username) = ?',
        whereArgs: [normalizedUsername.toLowerCase()],
        limit: 1,
      );
      if (exists.isNotEmpty) {
        _error.value = 'Cet identifiant existe déjà';
        return false;
      }

      await db.insert('users', {
        'username': normalizedUsername,
        'password': password,
        'role': role,
        'name': name.trim(),
      });
      await loadUsers();
      return true;
    } catch (e) {
      _error.value = 'Impossible de créer le compte';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> switchUser({
    required int userId,
    required String password,
  }) async {
    _isLoading.value = true;
    _error.value = '';

    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        'users',
        where: 'id = ? AND password = ?',
        whereArgs: [userId, password],
        limit: 1,
      );

      if (rows.isEmpty) {
        _error.value = 'Mot de passe incorrect';
        return false;
      }

      final row = rows.first;
      _user.value = User(
        id: row['id'] as int,
        username: row['username'] as String,
        name: row['name'] as String,
        role: row['role'] as String,
      );
      await _saveUserId(_user.value!.id);
      await loadUsers();
      return true;
    } catch (e) {
      _error.value = 'Impossible de changer d\'utilisateur';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> completeInitialUsersSetup({
    required String adminName,
    required String adminUsername,
    required String adminPassword,
    required List<({String name, String username, String password})> managers,
  }) async {
    _isLoading.value = true;
    _error.value = '';

    try {
      final db = await DatabaseHelper.instance.database;
      await db.transaction((txn) async {
        await txn.delete('users');

        final adminId = await txn.insert('users', {
          'username': adminUsername.trim(),
          'password': adminPassword,
          'role': 'admin',
          'name': adminName.trim(),
        });

        for (final manager in managers) {
          await txn.insert('users', {
            'username': manager.username.trim(),
            'password': manager.password,
            'role': 'gerant',
            'name': manager.name.trim(),
          });
        }

        _user.value = User(
          id: adminId,
          username: adminUsername.trim(),
          name: adminName.trim(),
          role: 'admin',
        );
      });

      await _saveUserId(_user.value!.id);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('initial_users_configured', true);

      Get.offAllNamed(AppRoutes.onboardingStation);
    } catch (e) {
      _error.value = 'Impossible de créer les utilisateurs';
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> logout() async {
    _user.value = null;
    _resetLicenseState();
    await _clearSavedUser();
    Get.offAllNamed(AppRoutes.login);
  }

  bool canManageUsers() {
    return user?.role == 'admin';
  }

  Future<void> refreshLicenseStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cle = prefs.getString("licence_key");
      final expiry = prefs.getString("licence_expiry");

      if (cle == null || expiry == null) {
        _resetLicenseState();
        return;
      }

      final dateExp = DateTime.tryParse(expiry);
      if (dateExp == null) {
        await _handleLicenseExpired(prefs);
        return;
      }

      final now = DateTime.now();
      if (now.isBefore(dateExp)) {
        _hasHandledLicenseExpiration = false;
        licenceValide.value = true;
        dateExpiration.value = dateExp;
        final remaining = dateExp.difference(now);
        remainingDuration.value = remaining;
        joursRestants.value = remaining.inDays;
        await AlertMonitoringService.instance.runAlertChecks();
        return;
      }

      await _handleLicenseExpired(prefs);
    } finally {
      lastLicenseRefresh.value = DateTime.now();
    }
  }

  Future<void> _handleLicenseExpired(SharedPreferences prefs) async {
    await prefs.remove(_userIdKey);
    await prefs.remove("licence_key");
    await prefs.remove("licence_expiry");
    _user.value = null;
    _resetLicenseState();
    await AlertMonitoringService.instance.runAlertChecks();

    if (_hasHandledLicenseExpiration) return;
    _hasHandledLicenseExpiration = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.currentRoute != AppRoutes.login) {
        Get.offAllNamed(AppRoutes.login);
        Get.snackbar(
          'Licence expirée',
          'Votre licence a expiré. Veuillez obtenir une nouvelle licence.',
        );
      }
    });
  }

  String get remainingTimeLabel {
    if (!licenceValide.value || dateExpiration.value == null) {
      return 'Licence expirée';
    }
    final d = remainingDuration.value;
    if (d.inSeconds <= 0) return 'Licence expirée';
    final days = d.inDays;
    final hours = d.inHours.remainder(24);
    final minutes = d.inMinutes.remainder(60);
    return '${days}j ${hours}h ${minutes}m';
  }

  String get expirationDateLabel {
    final exp = dateExpiration.value;
    if (exp == null) return '-';
    final dd = exp.day.toString().padLeft(2, '0');
    final mm = exp.month.toString().padLeft(2, '0');
    final yyyy = exp.year.toString();
    final hh = exp.hour.toString().padLeft(2, '0');
    final min = exp.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
  }

  void _startLicenseRefreshTimer() {
    _licenseTimer?.cancel();
    refreshLicenseStatus();
    _licenseTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      refreshLicenseStatus();
    });
  }

  void _resetLicenseState() {
    licenceValide.value = false;
    dateExpiration.value = null;
    joursRestants.value = 0;
    remainingDuration.value = Duration.zero;
  }

  Future<bool> _checkIfFirstLaunch() async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Check if there are fuels, pumps, or products
      final fuelCount = await db.rawQuery(
        'SELECT COUNT(*) as count FROM fuels',
      );
      final pumpCount = await db.rawQuery(
        'SELECT COUNT(*) as count FROM pumps',
      );
      final productCount = await db.rawQuery(
        'SELECT COUNT(*) as count FROM sales_products',
      );

      final fuelsExist = ((fuelCount.first['count'] as int?) ?? 0) > 0;
      final pumpsExist = ((pumpCount.first['count'] as int?) ?? 0) > 0;
      final productsExist = ((productCount.first['count'] as int?) ?? 0) > 0;

      // First launch is when no data exists
      return !fuelsExist && !pumpsExist && !productsExist;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_complete') ?? false;
  }
}
