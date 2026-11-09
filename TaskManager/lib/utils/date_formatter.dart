import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime.toLocal());
  }

  static String formatDate(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('dd/MM/yyyy').format(dateTime.toLocal());
  }

  static String formatIsoString(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoString);
      return formatDateTime(dt);
    } catch (_) {
      return isoString;
    }
  }
}
