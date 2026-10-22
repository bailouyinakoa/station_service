class Pompiste {
  final int id;
  final String name;
  final String? phone;
  final String? address;
  final String hireDate;
  final String status;

  Pompiste({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    required this.hireDate,
    required this.status,
  });
}