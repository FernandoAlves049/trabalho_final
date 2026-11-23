String usd(double value) =>
    'US\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
String brl(double value) =>
    'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
String shortDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
