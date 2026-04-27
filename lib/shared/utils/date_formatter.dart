import 'package:intl/intl.dart';

final _dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');
final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
final _timeFormat = DateFormat('HH:mm', 'fr_FR');

String formatDate(DateTime date) => _dateFormat.format(date);

String formatDateTime(DateTime date) => _dateTimeFormat.format(date);

String formatTime(DateTime date) => _timeFormat.format(date);

String formatRelative(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);

  if (diff.inSeconds < 60) return 'à l\'instant';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return 'il y a $m min';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return 'il y a $h h';
  }
  if (diff.inDays == 1) return 'hier';
  if (diff.inDays < 7) {
    final d = diff.inDays;
    return 'il y a $d jours';
  }
  return formatDate(date);
}

String formatDateLong(DateTime date) {
  return DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(date);
}
