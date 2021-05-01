extension NumRangeExtension on num {
  bool isInRange(num minValue, num maxValue) {
    return this >= minValue || this <= maxValue;
  }
}
