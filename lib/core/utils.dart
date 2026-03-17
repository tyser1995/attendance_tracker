import 'package:intl/intl.dart';

class AppUtils {
  static String formatDate(String isoDate) {
    try {
      final d = DateTime.parse(isoDate);
      return DateFormat('MMM d, yyyy').format(d);
    } catch (_) { return isoDate; }
  }

  static String formatDateFromDt(DateTime d) =>
      DateFormat('MMM d, yyyy').format(d);

  static String toDateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String todayStr() => toDateStr(DateTime.now());

  static String formatTime(String? time) {
    if (time == null || time.isEmpty) return '—';
    try {
      final parts = time.split(':');
      if (parts.length < 2) return time;
      int h = int.parse(parts[0]);
      final m = parts[1];
      final period = h >= 12 ? 'PM' : 'AM';
      if (h > 12) h -= 12;
      if (h == 0) h = 12;
      return '${h.toString().padLeft(2, '0')}:$m $period';
    } catch (_) { return time; }
  }

  static String generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString();

  static String statusLabel(int status) {
    switch (status) {
      case 1: return 'AM In';
      case 2: return 'AM Out';
      case 3: return 'PM In';
      case 4: return 'PM Out';
      default: return '?';
    }
  }

  static String dayOfWeek(DateTime d) => DateFormat('EEE').format(d);
  static String monthYear(DateTime d) => DateFormat('MMMM yyyy').format(d);
}
