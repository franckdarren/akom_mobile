import 'package:intl/intl.dart';

final _formatter = NumberFormat('#,###', 'fr_FR');

String formatFCFA(int amount) => '${_formatter.format(amount)} FCFA';

String formatFCFACompact(int amount) {
  if (amount >= 1000000) {
    final millions = amount / 1000000;
    return '${_formatter.format(millions.round())} M FCFA';
  }
  if (amount >= 1000) {
    final thousands = amount / 1000;
    final rounded = (thousands * 10).round() / 10;
    final display = rounded == rounded.roundToDouble()
        ? rounded.toInt().toString()
        : rounded.toString();
    return '$display k FCFA';
  }
  return formatFCFA(amount);
}

// Calcule la monnaie rendue. Retourne null si montant insuffisant.
int? calculateChange(int totalAmount, int amountReceived) {
  if (amountReceived < totalAmount) return null;
  return amountReceived - totalAmount;
}
