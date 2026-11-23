import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../data/app_database.dart';
import '../models/exchange_rate.dart';

class ExchangeProvider extends ChangeNotifier {
  ExchangeProvider(this.client, this.database);
  final http.Client client;
  final AppDatabase database;
  ExchangeRate? quote;
  bool loading = false;
  bool failed = false;

  Future<void> refresh() async {
    if (loading) return;
    loading = true;
    failed = false;
    notifyListeners();
    try {
      if (quote == null) {
        quote = await database.readExchangeRate();
        if (quote != null) notifyListeners();
      }
    } catch (_) {
      // A cotação online continua disponível se a leitura local falhar.
    }
    try {
      final response = await client
          .get(Uri.https('api.frankfurter.dev', '/v2/rate/USD/BRL'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) throw const FormatException();
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['base'] != 'USD' || data['quote'] != 'BRL') {
        throw const FormatException();
      }
      quote = ExchangeRate.fromMap(data);
    } catch (_) {
      failed = true;
    }
    if (!failed) {
      try {
        await database.saveExchangeRate(quote!);
      } catch (_) {
        // O valor recém-consultado ainda pode ser usado nesta sessão.
      }
    }
    loading = false;
    notifyListeners();
  }
}
