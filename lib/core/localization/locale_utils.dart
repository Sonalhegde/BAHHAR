// BAHHAR Locale Utilities
// Arabic-Indic numeral conversion, date formatting, unit conversion.

import 'package:intl/intl.dart';

class LocaleUtils {
  // ─── Arabic-Indic Digit Conversion ────────────────────────────────────────
  static const _arabicIndicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

  /// Convert Western numerals in a string to Arabic-Indic when [isArabic] is true.
  static String formatNumber(String input, bool isArabic) {
    if (!isArabic) return input;
    return input.replaceAllMapped(
      RegExp(r'[0-9]'),
      (m) => _arabicIndicDigits[int.parse(m.group(0)!)],
    );
  }

  /// Format an integer, converting digits if Arabic.
  static String formatInt(int value, bool isArabic) {
    return formatNumber(value.toString(), isArabic);
  }

  /// Format a double to [decimals] places, converting digits if Arabic.
  static String formatDouble(double value, bool isArabic, {int decimals = 1}) {
    final formatted = value.toStringAsFixed(decimals);
    return formatNumber(formatted, isArabic);
  }

  // ─── Date Formatting ──────────────────────────────────────────────────────

  /// Format a DateTime as a short date (e.g. "15 Mar 2025" / "١٥ مارس ٢٠٢٥").
  static String formatDate(DateTime date, bool isArabic) {
    if (isArabic) {
      final day = formatInt(date.day, true);
      final year = formatInt(date.year, true);
      final months = ['يناير','فبراير','مارس','أبريل','مايو','يونيو',
                      'يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
      return '$day ${months[date.month - 1]} $year';
    }
    return DateFormat('d MMM yyyy', 'en').format(date);
  }

  /// Format as month/year only (e.g. "Mar 2025" / "مارس ٢٠٢٥").
  static String formatMonthYear(DateTime date, bool isArabic) {
    if (isArabic) {
      final year = formatInt(date.year, true);
      final months = ['يناير','فبراير','مارس','أبريل','مايو','يونيو',
                      'يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
      return '${months[date.month - 1]} $year';
    }
    return DateFormat('MMM yyyy', 'en').format(date);
  }

  /// Days until [date] from today. Negative means already expired.
  static int daysUntil(DateTime date) {
    final now = DateTime.now();
    return date.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  // ─── Unit Conversion ──────────────────────────────────────────────────────

  static String formatWaveHeight(double meters, bool isMetric, bool isArabic) {
    if (isMetric) {
      return '${formatDouble(meters, isArabic)} ${isArabic ? 'م' : 'm'}';
    } else {
      final feet = meters * 3.28084;
      return '${formatDouble(feet, isArabic)} ${isArabic ? 'قدم' : 'ft'}';
    }
  }

  static String formatWindSpeed(double knots, bool isMetric, bool isArabic) {
    if (isMetric) {
      final kmh = knots * 1.852;
      return '${formatDouble(kmh, isArabic)} ${isArabic ? 'كم/س' : 'km/h'}';
    } else {
      return '${formatDouble(knots, isArabic)} ${isArabic ? 'عقدة' : 'kts'}';
    }
  }

  static String formatTemperature(double celsius, bool isMetric, bool isArabic) {
    if (isMetric) {
      return '${formatDouble(celsius, isArabic)}${isArabic ? '°م' : '°C'}';
    } else {
      final fahrenheit = celsius * 9 / 5 + 32;
      return '${formatDouble(fahrenheit, isArabic)}${isArabic ? '°ف' : '°F'}';
    }
  }

  static String formatWeight(double kg, bool isMetric, bool isArabic) {
    if (isMetric) {
      return '${formatDouble(kg, isArabic)} ${isArabic ? 'كغ' : 'kg'}';
    } else {
      final lbs = kg * 2.20462;
      return '${formatDouble(lbs, isArabic)} ${isArabic ? 'رطل' : 'lb'}';
    }
  }

  static String formatLength(double meters, bool isMetric, bool isArabic) {
    if (isMetric) {
      return '${formatDouble(meters, isArabic)} ${isArabic ? 'م' : 'm'}';
    } else {
      final feet = meters * 3.28084;
      return '${formatDouble(feet, isArabic)} ${isArabic ? 'قدم' : 'ft'}';
    }
  }

  // ─── Phone masking ────────────────────────────────────────────────────────
  
  /// Returns a masked version of [id] showing only last 4 digits.
  static String maskId(String id) {
    if (id.length <= 4) return id;
    return '••••••${id.substring(id.length - 4)}';
  }

  /// Returns a masked phone showing only last 4 digits.
  static String maskPhone(String phone) {
    if (phone.length <= 4) return phone;
    return '•••• •••• ${phone.substring(phone.length - 4)}';
  }
}
