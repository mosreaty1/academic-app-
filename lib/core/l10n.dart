import 'package:flutter/widgets.dart';

/// Lightweight bilingual (Arabic / English) helpers.
extension Tr on BuildContext {
  bool get isAr => Directionality.of(this) == TextDirection.rtl;
  String tr(String ar, String en) => isAr ? ar : en;
}

/// A bilingual string.
class Bi {
  final String ar;
  final String en;
  const Bi(this.ar, this.en);
  String of(BuildContext c) => c.isAr ? ar : en;
  String get initial => en.isNotEmpty ? en.substring(0, 1) : '';
  String initialOf(BuildContext c) {
    final s = of(c);
    return s.isNotEmpty ? s.substring(0, 1) : '';
  }
}

const _monthsAr = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
];
const _monthsEn = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];
// DateTime.weekday: Mon = 1 ... Sun = 7
const _daysAr = [
  'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'
];
const _daysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _daysEnLong = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
];

String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String fmtDate(BuildContext c, DateTime d) =>
    '${d.day} ${c.isAr ? _monthsAr[d.month - 1] : _monthsEn[d.month - 1]}';

String fmtDateYear(BuildContext c, DateTime d) => '${fmtDate(c, d)} ${d.year}';

String weekdayName(BuildContext c, int weekday, {bool long = true}) => c.isAr
    ? _daysAr[weekday - 1]
    : (long ? _daysEnLong : _daysEn)[weekday - 1];

String fmtDateFull(BuildContext c, DateTime d) =>
    '${weekdayName(c, d.weekday)}, ${fmtDate(c, d)}';

String fmtTime(BuildContext c, DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  final suffix = d.hour >= 12 ? c.tr('م', 'PM') : c.tr('ص', 'AM');
  return '$h:$m $suffix';
}

/// Formats a 24h "HH:mm" string according to the current language.
String fmtClock(BuildContext c, String hhmm) {
  final p = hhmm.split(':');
  final dt = DateTime(2000, 1, 1, int.parse(p[0]), int.parse(p[1]));
  return fmtTime(c, dt);
}

String timeAgo(BuildContext c, DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return c.tr('الآن', 'Just now');
  if (diff.inMinutes < 60) {
    return c.tr('منذ ${diff.inMinutes} د', '${diff.inMinutes}m ago');
  }
  if (diff.inHours < 24) {
    return c.tr('منذ ${diff.inHours} س', '${diff.inHours}h ago');
  }
  if (diff.inDays < 7) {
    return c.tr('منذ ${diff.inDays} يوم', '${diff.inDays}d ago');
  }
  return fmtDate(c, d);
}

/// "in 3 days" / "tomorrow" / "today" / "2 days ago".
String relativeDay(BuildContext c, DateTime d) {
  final diff = dayOnly(d).difference(dayOnly(DateTime.now())).inDays;
  if (diff == 0) return c.tr('اليوم', 'Today');
  if (diff == 1) return c.tr('غداً', 'Tomorrow');
  if (diff == -1) return c.tr('أمس', 'Yesterday');
  if (diff > 1) return c.tr('بعد $diff أيام', 'In $diff days');
  return c.tr('منذ ${-diff} أيام', '${-diff} days ago');
}

String money(BuildContext c, num v) {
  final s = v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
  return c.isAr ? '$s ج.م' : 'EGP $s';
}

String gradeName(BuildContext c, int g) {
  switch (g) {
    case 1:
      return c.tr('الصف الأول الثانوي', '1st Secondary');
    case 2:
      return c.tr('الصف الثاني الثانوي', '2nd Secondary');
    case 3:
      return c.tr('الصف الثالث الثانوي', '3rd Secondary');
    default:
      return c.tr('جميع الصفوف', 'All grades');
  }
}

String gradeShort(BuildContext c, int g) =>
    g == 0 ? c.tr('الكل', 'All') : c.tr('الصف $g', 'Grade $g');

String gradeTiny(BuildContext c, int g) {
  const ar = ['', 'أولى ثانوي', 'ثانية ثانوي', 'ثالثة ثانوي'];
  const en = ['', 'Secondary 1', 'Secondary 2', 'Secondary 3'];
  return (c.isAr ? ar : en)[g];
}
