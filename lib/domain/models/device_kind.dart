/// Advertised-device categories used by the scanner filter chips.
enum DeviceKind {
  earbuds('Earbuds', 'سماعات', 'EARBUDS', 'AUDIO'),
  watch('Watches', 'ساعات', 'WATCH', 'WEARABLE'),
  tracker('Trackers', 'متعقبات', 'TRACKER', 'TAG'),
  unknown('Unknown', 'غير معروف', 'UNKNOWN', 'BLE');

  const DeviceKind(this.labelEn, this.labelAr, this.code, this.category);

  final String labelEn;
  final String labelAr;

  /// Short uppercase code shown in the mono badge on device cards.
  final String code;

  /// Secondary category hint used in diagnostics.
  final String category;

  bool get isKnown => this != DeviceKind.unknown;
}
