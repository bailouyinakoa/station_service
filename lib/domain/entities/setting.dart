class Setting {
  final int? id;
  final String stationName;
  final String stationAddress;
  final String phone;
  final String backupPath;
  final String adminEmail;

  Setting({
    this.id,
    required this.stationName,
    required this.stationAddress,
    required this.phone,
    required this.backupPath,
    this.adminEmail = '',
  });
}
