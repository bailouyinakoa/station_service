import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat cfaCurrency = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  );

  static String cfa(double amount) => cfaCurrency.format(amount);
}
