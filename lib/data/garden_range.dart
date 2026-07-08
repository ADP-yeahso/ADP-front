const int gardenMonthsBack = 12;
const int gardenMonthsForward = 2;
const int gardenTotalPages = gardenMonthsBack + gardenMonthsForward + 1;

DateTime gardenAnchorMonth() {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
}

DateTime gardenMonthAt(DateTime anchor, int index) =>
    DateTime(anchor.year, anchor.month - gardenMonthsBack + index);

int gardenIndexForMonth(DateTime anchor, DateTime month) {
  final diff = (month.year - anchor.year) * 12 + (month.month - anchor.month);
  return (gardenMonthsBack + diff).clamp(0, gardenTotalPages - 1);
}
