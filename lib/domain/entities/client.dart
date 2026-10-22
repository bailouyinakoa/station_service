class Client {
  final int id;
  final String name;
  final String? cardNumber;
  final double balance;
  final double credit;

  Client({
    required this.id,
    required this.name,
    this.cardNumber,
    required this.balance,
    required this.credit,
  });
}
