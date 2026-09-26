import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Rupees for display, in the current locale with Indian digit grouping
/// (1,00,000). Paise are shown only when there are some.
///
/// Amounts travel as integer paise everywhere; this is the one place they
/// become a string.
String formatRupees(BuildContext context, int paise) {
  final languageCode = Localizations.localeOf(context).languageCode;
  final format = NumberFormat.simpleCurrency(
    locale: '${languageCode}_IN',
    name: 'INR',
    decimalDigits: paise % 100 == 0 ? 0 : 2,
  );
  return format.format(paise / 100);
}
