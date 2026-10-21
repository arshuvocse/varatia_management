import 'package:intl/intl.dart';

class BanglaFormatter {
  BanglaFormatter._();

  static const Map<String, String> _digits = {
    '0': '০',
    '1': '১',
    '2': '২',
    '3': '৩',
    '4': '৪',
    '5': '৫',
    '6': '৬',
    '7': '৭',
    '8': '৮',
    '9': '৯',
  };

  static const List<String> _shortMonths = [
    'জানু',
    'ফেব',
    'মার্চ',
    'এপ্রিল',
    'মে',
    'জুন',
    'জুলাই',
    'আগ',
    'সেপ্টে',
    'অক্টো',
    'নভে',
    'ডিসে',
  ];

  static String digits(num value, {bool bangla = true}) {
    final formatted = NumberFormat.decimalPattern('en_US').format(value);
    return bangla ? _toBangla(formatted) : formatted;
  }

  static String taka(num value, {bool bangla = true}) {
    final formatted = NumberFormat.currency(
      locale: 'en_US',
      symbol: '৳',
      decimalDigits: 0,
    ).format(value);
    return bangla ? _toBangla(formatted) : formatted;
  }

  static String shortDate(DateTime value, {bool bangla = true}) {
    if (bangla) {
      return '${digits(value.day)} ${_shortMonths[value.month - 1]}';
    }
    return DateFormat('dd MMM', 'en_US').format(value);
  }

  static const List<String> _fullMonths = [
    'জানুয়ারি',
    'ফেব্রুয়ারি',
    'মার্চ',
    'এপ্রিল',
    'মে',
    'জুন',
    'জুলাই',
    'আগস্ট',
    'সেপ্টেম্বর',
    'অক্টোবর',
    'নভেম্বর',
    'ডিসেম্বর',
  ];

  static String fullDate(DateTime value, {bool bangla = true}) {
    if (bangla) {
      return '${digits(value.day)} ${_fullMonths[value.month - 1]}, ${digits(value.year)}';
    }
    return DateFormat('dd MMMM, yyyy', 'en_US').format(value);
  }

  static String _toBangla(String value) {
    return value.split('').map((char) => _digits[char] ?? char).join();
  }
}
