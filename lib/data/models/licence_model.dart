class LicenceModel {
  final bool valide;
  final bool expire;
  final String message;
  final DateTime? dateExpiration;
  final int joursRestants;

  LicenceModel({
    required this.valide,
    this.expire=false,
    required this.message,
     this.dateExpiration,
    this.joursRestants=0,
  });
}
