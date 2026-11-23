class ExchangeRate {
  const ExchangeRate(this.rate, this.date);
  final double rate;
  final DateTime date;

  factory ExchangeRate.fromMap(Map<String, Object?> map) {
    final rate = (map['rate'] as num).toDouble();
    if (!rate.isFinite || rate <= 0) {
      throw const FormatException('Cotação inválida');
    }
    return ExchangeRate(rate, DateTime.parse(map['date'] as String));
  }

  double inReais(double usd) => usd * rate;
}
