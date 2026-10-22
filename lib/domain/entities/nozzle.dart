class Nozzle {
  final int id;
  final int pumpId;
  final String name;
  String status;

  Nozzle({
    required this.id,
    required this.pumpId,
    required this.name,
    required this.status,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'pumpId': pumpId,
      'name': name,
      'status': status,
    };
  }
}
