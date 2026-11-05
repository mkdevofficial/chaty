import 'package:intl/intl.dart';

class DateFormatter {
  static String formatConversationTime(String? isoString, {bool isArabic = true}) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();

      final today = DateTime(now.year, now.month, now.day);
      final msgDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

      if (today == msgDay) {
        return DateFormat.jm(isArabic ? 'ar' : 'en').format(dateTime);
      } else if (today.subtract(const Duration(days: 1)) == msgDay) {
        return isArabic ? 'أمس' : 'Yesterday';
      } else if (now.difference(dateTime).inDays < 7) {
        return DateFormat.E(isArabic ? 'ar' : 'en').format(dateTime);
      } else {
        return DateFormat.yMMMd(isArabic ? 'ar' : 'en').format(dateTime);
      }
    } catch (_) {
      return '';
    }
  }

  static String formatMessageTime(String? isoString, {bool isArabic = true}) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      return DateFormat.jm(isArabic ? 'ar' : 'en').format(dateTime);
    } catch (_) {
      return '';
    }
  }

  static String formatDaySeparator(String? isoString, {bool isArabic = true}) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();

      final today = DateTime(now.year, now.month, now.day);
      final msgDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

      if (today == msgDay) {
        return isArabic ? 'اليوم' : 'Today';
      } else if (today.subtract(const Duration(days: 1)) == msgDay) {
        return isArabic ? 'أمس' : 'Yesterday';
      } else {
        return DateFormat.yMMMMEEEEd(isArabic ? 'ar' : 'en').format(dateTime);
      }
    } catch (_) {
      return '';
    }
  }

  static String formatLastSeen(String? isoString, {bool isArabic = true}) {
    if (isoString == null || isoString.isEmpty) {
      return isArabic ? 'غير متصل' : 'Offline';
    }
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      final diff = DateTime.now().difference(dateTime);

      if (diff.inMinutes < 1) {
        return isArabic ? 'آخر ظهور منذ قليل' : 'Last seen just now';
      } else if (diff.inHours < 1) {
        final m = diff.inMinutes;
        return isArabic ? 'آخر ظهور منذ $m دقيقة' : 'Last seen $m min ago';
      } else if (diff.inDays < 1) {
        final timeStr = DateFormat.jm(isArabic ? 'ar' : 'en').format(dateTime);
        return isArabic ? 'آخر ظهور اليوم $timeStr' : 'Last seen today at $timeStr';
      } else {
        final dateStr = DateFormat.MMMd(isArabic ? 'ar' : 'en').format(dateTime);
        return isArabic ? 'آخر ظهور $dateStr' : 'Last seen $dateStr';
      }
    } catch (_) {
      return isArabic ? 'غير متصل' : 'Offline';
    }
  }
}
