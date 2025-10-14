import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final NumberFormat currency = NumberFormat.currency(symbol: '₹ ', decimalDigits: 2, name: '');
  static final DateFormat dayLabel = DateFormat('EEE');
  static final DateFormat dateLabel = DateFormat('MMM d');
}


