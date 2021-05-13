extension NumRangeExtension on num {
  /// Return boolean checking value is in range
  bool isInRange(num minValue, num maxValue) {
    return this >= minValue && this <= maxValue;
  }
}
