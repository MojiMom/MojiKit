int daysSinceStartOfYear(DateTime date) {
  return DateTime.utc(date.year, date.month, date.day).difference(DateTime.utc(date.year)).inDays;
}
