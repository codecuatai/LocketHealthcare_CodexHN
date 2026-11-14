/// Định dạng số kiểu Việt Nam: 1.850 và 5,2.
String formatInt(num value) {
  final digits = value.round().abs().toString();
  final out = StringBuffer(value.round() < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write('.');
    out.write(digits[i]);
  }
  return out.toString();
}

/// Số có tối đa một chữ số thập phân, bỏ ",0".
String formatDecimal(double value) {
  final rounded = (value * 10).round() / 10;
  if (rounded == rounded.roundToDouble()) return formatInt(rounded);
  final whole = rounded.truncate();
  final tenth = ((rounded - whole).abs() * 10).round();
  return '${formatInt(whole)},$tenth';
}

/// "vừa xong", "20 phút", "3 giờ", "Hôm qua", "12/11".
String relativeTime(DateTime at, DateTime now) {
  final diff = now.difference(at);
  if (diff.inMinutes < 1) return 'vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút';
  final today = DateTime(now.year, now.month, now.day);
  if (!at.isBefore(today)) return '${diff.inHours} giờ';
  if (!at.isBefore(today.subtract(const Duration(days: 1)))) return 'Hôm qua';
  return '${at.day}/${at.month}';
}

String clockTime(DateTime at) =>
    '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';

DateTime dateOnly(DateTime at) => DateTime(at.year, at.month, at.day);

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
