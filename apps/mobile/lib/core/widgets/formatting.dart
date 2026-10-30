import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

String formatDateTime(BuildContext context, DateTime value) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  try {
    return DateFormat('d MMM y, HH:mm', locale).format(value.toLocal());
  } catch (_) {
    return DateFormat('yyyy-MM-dd HH:mm').format(value.toLocal());
  }
}
