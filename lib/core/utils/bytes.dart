String formatBytes(int bytes) {
  if (bytes < 0) return '—';
  const units = ['o', 'Ko', 'Mo', 'Go', 'To'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final digits = unit >= 3 ? 2 : 0;
  return '${value.toStringAsFixed(digits)} ${units[unit]}';
}

String formatPercent(double ratio) => '${(ratio * 100).toStringAsFixed(0)}%';
