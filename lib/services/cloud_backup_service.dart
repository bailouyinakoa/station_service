import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:station_service_app/core/database/database_helper.dart';
import 'package:station_service_app/licence/deviceId.dart';

class CloudBackupInfo {
  const CloudBackupInfo({required this.exists, this.updatedAt, this.size});

  final bool exists;
  final DateTime? updatedAt;
  final int? size;
}

class CloudRestoreResult {
  const CloudRestoreResult({required this.safetyCopyPath});

  final String? safetyCopyPath;
}

enum _StorageOperation { upload, read }

class CloudBackupService {
  CloudBackupService._();

  static final CloudBackupService instance = CloudBackupService._();

  static const Duration backupInterval = Duration(hours: 6);
  static const String _lastBackupKey = 'cloud_backup_last_at';
  static const String _autoBackupKey = 'cloud_backup_auto_enabled';

  Timer? _timer;
  bool _backupRunning = false;
  bool _restoreRunning = false;

  bool get isFirebaseReady => Firebase.apps.isNotEmpty;
  bool get isBackupRunning => _backupRunning;
  bool get isRestoreRunning => _restoreRunning;

  Future<void> initialize() async {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(hours: 1), (_) => backupIfDue());
    unawaited(backupIfDue());
  }

  Future<bool> isAutoBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoBackupKey) ?? true;
  }

  Future<void> setAutoBackupEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupKey, enabled);
  }

  Future<String> getBackupDeviceId() async {
    final id = (await DeviceId.getDeviceId()).trim();
    if (id.isEmpty || id == 'unknown') {
      throw Exception('Impossible de lire l identifiant de cet appareil.');
    }
    return id;
  }

  Future<DateTime?> getLastBackupAt() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_lastBackupKey);
    return value == null ? null : DateTime.tryParse(value);
  }

  Future<void> backupIfDue() async {
    final autoEnabled = await isAutoBackupEnabled();
    if (!isFirebaseReady || !autoEnabled) return;

    final lastBackup = await getLastBackupAt();
    final now = DateTime.now();
    if (lastBackup != null && now.difference(lastBackup) < backupInterval) {
      return;
    }

    await backupNow();
  }

  Future<DateTime> backupNow() async {
    if (!isFirebaseReady) {
      throw Exception('Firebase n est pas initialise pour cette plateforme.');
    }
    if (_backupRunning) {
      throw Exception('Une sauvegarde cloud est deja en cours.');
    }

    final deviceId = await getBackupDeviceId();

    _backupRunning = true;
    try {
      final db = await DatabaseHelper.instance.database;
      await db.rawQuery('PRAGMA wal_checkpoint(FULL)');

      final dbPath = await DatabaseHelper.instance.databasePath;
      final dbFile = File(dbPath);
      if (!await dbFile.exists()) {
        throw Exception('Base de donnees introuvable.');
      }

      final now = DateTime.now();
      final ref = _backupRef(deviceId);
      await _uploadDatabaseFile(ref: ref, file: dbFile, deviceId: deviceId);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastBackupKey, now.toIso8601String());
      return now;
    } on FirebaseException catch (e) {
      throw Exception(
        _firebaseErrorMessage(e, operation: _StorageOperation.upload),
      );
    } finally {
      _backupRunning = false;
    }
  }

  Future<CloudBackupInfo> fetchBackupInfo() async {
    if (!isFirebaseReady) {
      throw Exception('Firebase n est pas initialise pour cette plateforme.');
    }
    final deviceId = await getBackupDeviceId();

    try {
      final metadata = await _backupRef(deviceId).getMetadata();
      return CloudBackupInfo(
        exists: true,
        updatedAt: metadata.updated,
        size: metadata.size,
      );
    } on FirebaseException catch (e) {
      if (_isObjectNotFound(e)) {
        return const CloudBackupInfo(exists: false);
      }
      throw Exception(_firebaseErrorMessage(e));
    }
  }

  Future<CloudRestoreResult> restoreFromCloud() async {
    if (!isFirebaseReady) {
      throw Exception('Firebase n est pas initialise pour cette plateforme.');
    }
    if (_restoreRunning) {
      throw Exception('Une restauration cloud est deja en cours.');
    }
    final deviceId = await getBackupDeviceId();

    _restoreRunning = true;
    try {
      final tempDir = await getTemporaryDirectory();
      final stamp = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
      final tempPath = p.join(
        tempDir.path,
        'station_service_restore_$stamp.db',
      );
      final tempFile = File(tempPath);

      await _backupRef(deviceId).writeToFile(tempFile);
      final downloaded = await tempFile.exists();
      final downloadedSize = downloaded ? await tempFile.length() : 0;
      if (!downloaded || downloadedSize == 0) {
        throw Exception('Le fichier de sauvegarde telecharge est vide.');
      }

      final safetyCopyPath = await DatabaseHelper.instance
          .replaceDatabaseFromFile(tempFile.path);
      return CloudRestoreResult(safetyCopyPath: safetyCopyPath);
    } on FirebaseException catch (e) {
      if (_isObjectNotFound(e)) {
        throw Exception('Aucune sauvegarde cloud trouvee pour cet appareil.');
      }
      throw Exception(_firebaseErrorMessage(e));
    } finally {
      _restoreRunning = false;
    }
  }

  Future<void> _uploadDatabaseFile({
    required Reference ref,
    required File file,
    required String deviceId,
  }) async {
    final metadata = SettableMetadata(
      contentType: 'application/x-sqlite3',
      customMetadata: {
        'app': 'station_service_app',
        'databaseName': DatabaseHelper.databaseName,
        'databaseVersion': DatabaseHelper.databaseVersion.toString(),
        'deviceId': deviceId,
        'savedAt': DateTime.now().toIso8601String(),
      },
    );

    final bytes = await file.readAsBytes();
    await ref.putData(bytes, metadata);
  }

  Reference _backupRef(String deviceId) {
    return _storage.ref().child(
      'station_backups/${_safeDeviceId(deviceId)}/${DatabaseHelper.databaseName}',
    );
  }

  FirebaseStorage get _storage {
    final app = Firebase.app();
    final bucket = app.options.storageBucket;
    if (bucket == null || bucket.trim().isEmpty) {
      return FirebaseStorage.instance;
    }
    final bucketUrl = bucket.startsWith('gs://') ? bucket : 'gs://$bucket';
    return FirebaseStorage.instanceFor(app: app, bucket: bucketUrl);
  }

  String _safeDeviceId(String deviceId) {
    final normalized = deviceId
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
    if (normalized.isEmpty) {
      throw Exception('Identifiant appareil invalide.');
    }
    return normalized;
  }

  bool _isObjectNotFound(FirebaseException e) {
    final code = e.code.toLowerCase();
    final message = (e.message ?? '').toLowerCase();
    return code == 'object-not-found' ||
        code == 'storage/object-not-found' ||
        message.contains('no object exists at the desired reference');
  }

  String _firebaseErrorMessage(
    FirebaseException e, {
    _StorageOperation operation = _StorageOperation.read,
  }) {
    if (_isObjectNotFound(e)) {
      if (operation == _StorageOperation.upload) {
        return 'Firebase Storage n a pas pu creer la premiere sauvegarde. Verifiez que Storage est active et que les regles autorisent l ecriture. Detail: ${_firebaseDetail(e)}';
      }
      return 'Aucune sauvegarde cloud trouvee pour cet appareil. Faites d abord une sauvegarde. Detail: ${_firebaseDetail(e)}';
    }
    if (e.code == 'unauthorized') {
      return 'Firebase Storage refuse l acces. Verifiez les regles de lecture/ecriture. Detail: ${_firebaseDetail(e)}';
    }
    if (e.code == 'canceled') {
      return 'Operation Firebase annulee.';
    }
    if (e.code == 'retry-limit-exceeded') {
      return 'Connexion Firebase instable. Reessayez avec une meilleure connexion.';
    }
    return 'Erreur Firebase Storage: ${_firebaseDetail(e)}';
  }

  String _firebaseDetail(FirebaseException e) {
    final message = e.message;
    if (message == null || message.trim().isEmpty) {
      return e.code;
    }
    return '${e.code} - $message';
  }
}
