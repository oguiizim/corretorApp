import 'package:intl/intl.dart';

final NumberFormat _currencyFormatter = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
  decimalDigits: 2,
);

double? parsePrice(String raw) {
  final cleaned = raw.replaceAll('R\$', '').replaceAll(' ', '').trim();
  if (cleaned.isEmpty) {
    return null;
  }

  final normalized = cleaned.contains(',')
      ? cleaned.replaceAll('.', '').replaceAll(',', '.')
      : cleaned;
  if (normalized.isEmpty) {
    return null;
  }
  return double.tryParse(normalized);
}

String formatPrice(double value) {
  return _currencyFormatter.format(value);
}

String formatPriceInput(double value) {
  final currency = formatPrice(value);
  return currency.replaceAll('R\$', '').trim();
}
