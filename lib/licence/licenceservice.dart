import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:station_service_app/data/models/licence_model.dart';

class Licenceservice {
  static const String _secret = "KANIA_DAKAN_2026";

  static LicenceModel verifierCle(String cleEntree, String deviceId) {
    final parties = cleEntree.trim().toUpperCase().split("-");

    if (parties.length != 3) {
      return LicenceModel(
        valide: false,
        message: "Clé invalide -format incorrect",
      );
    }
    final idDansCle = parties[0];
    final dateExp = parties[1];
    final signature = parties[2];
    final monIdCourt = deviceId.substring(0, 8).toUpperCase();
    final monIdCle = monIdCourt.substring(0, 4);

    if (idDansCle != monIdCle) {
      return LicenceModel(
        valide: false,
        message: "Clé non valide pour ce appareil",
      );
    }
    DateTime? dateExpiration;
    try {
      final jour = int.parse(dateExp.substring(0, 2));
      final mois = int.parse(dateExp.substring(2, 4));
      final annee = int.parse(dateExp.substring(4, 8));
      dateExpiration = DateTime(annee, mois, jour, 23, 59, 59);
    } catch (e) {
      return LicenceModel(
        valide: false,
        message: "Format de date invalide dans la clé",
      );
    }
    final maintenant = DateTime.now();
    final estExpire = maintenant.isAfter(dateExpiration);
    final joursRestant = dateExpiration.difference(maintenant).inDays;

    String formatDate(DateTime d) =>
        "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
    if (estExpire) {
      return LicenceModel(
        valide: false,
        message: "Licence  expirée depuis le ${formatDate(dateExpiration)}",
        dateExpiration: dateExpiration,
      );
    }
    String genererSignature(String message) {
      final key = utf8.encode(_secret);
      final msg = utf8.encode(message);
      final hmacSha = Hmac(sha256, key);
      final diget = hmacSha.convert(msg);
      String signature = diget.toString().substring(0, 12).toUpperCase();
      return signature;
    }

    final message = "$monIdCourt-$dateExp";
    final signatureAttendue = genererSignature(message);


    if (signature != signatureAttendue) {
      return LicenceModel(
        valide: false,
        message: "Signature invalide -clé falsifiée",
      );
    }
    return LicenceModel(
      valide: true,
      message: "Licence valide",
      dateExpiration: dateExpiration,
      joursRestants: joursRestant,
    );
  }
}
