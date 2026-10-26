/// Measurement system used in the UI.
enum DistanceUnit {
  meters('m', 'م', 'Metric', 'متري'),
  feet('ft', 'قدم', 'Imperial', 'إمبراطوري');

  const DistanceUnit(this.symbol, this.symbolAr, this.labelEn, this.labelAr);

  final String symbol;
  final String symbolAr;
  final String labelEn;
  final String labelAr;

  String symbolFor(bool arabic) => arabic ? symbolAr : symbol;
}
