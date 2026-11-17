import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(num? amount) {
    if (amount == null) return 'Rp 0';
    try {
      final formatter = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );
      return formatter.format(amount);
    } catch (_) {
      final formattedNumber = amount.toInt().toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]}.',
          );
      return 'Rp $formattedNumber';
    }
  }
}

class DateFormatter {
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  static String formatDate(DateTime? date) {
    if (date == null) return '-';
    try {
      final day = date.day.toString().padLeft(2, '0');
      final month = _months[date.month - 1];
      final year = date.year;
      return '$day $month $year';
    } catch (_) {
      return '${date.day}-${date.month}-${date.year}';
    }
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return '-';
    try {
      final datePart = formatDate(date);
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$datePart, $hour:$minute';
    } catch (_) {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
