class Pump {
  final int id;
  final String name;
  final int fuelId;
  String status;
  double meterReading;
  final String fuelName;

  Pump({
    required this.id,
    required this.name,
    required this.fuelId,
    required this.status,
    required this.meterReading,
    required this.fuelName,
  });
}
