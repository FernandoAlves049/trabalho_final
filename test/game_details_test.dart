import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trabalho_final/data/app_database.dart';
import 'package:trabalho_final/data/game_info_api.dart';
import 'package:trabalho_final/models/deal.dart';
import 'package:trabalho_final/models/exchange_rate.dart';
import 'package:trabalho_final/state/exchange_provider.dart';
import 'package:trabalho_final/ui/money.dart';

class RateStore extends Fake implements AppDatabase {
  ExchangeRate? last;
  @override
  Future<ExchangeRate?> readExchangeRate() async => last;
  @override
  Future<void> saveExchangeRate(ExchangeRate quote) async {
    last = quote;
  }
}

const oldDeal = Deal(
  id: 'x',
  gameId: '123',
  storeId: '1',
  title: 'Exemplo',
  thumb: '',
  regular: 10,
  price: 3.99,
  discount: 60,
);
http.Response jsonResponse(Object data) =>
    http.Response.bytes(utf8.encode(jsonEncode(data)), 200);

void main() {
  test(
    'Converte USD em BRL e recupera a última cotação quando a rede falha',
    () async {
      final store = RateStore();
      final online = ExchangeProvider(
        MockClient(
          (_) async => jsonResponse({
            'date': '2026-11-23',
            'rate': 5.9485,
            'base': 'USD',
            'quote': 'BRL',
          }),
        ),
        store,
      );
      await online.refresh();
      expect(brl(online.quote!.inReais(3.99)), r'R$ 23,73');
      final offline = ExchangeProvider(
        MockClient((_) async => http.Response('', 503)),
        store,
      );
      await offline.refresh();
      expect(offline.failed, isTrue);
      expect(offline.quote!.date, DateTime(2026, 11, 23));
      expect(brl(offline.quote!.inReais(0)), r'R$ 0,00');
    },
  );
  test(
    'Favorito antigo recupera o appID e a sinopse; preço regional exige BRL',
    () async {
      final api = GameInfoApi(
        MockClient((req) async {
          if (req.url.path.endsWith('/games')) {
            return jsonResponse({
              'info': {'steamAppID': '77'},
            });
          }
          expect(req.url.queryParameters, {
            'appids': '77',
            'cc': 'br',
            'l': 'brazilian',
          });
          return jsonResponse({
            '77': {
              'success': true,
              'data': {
                'short_description': '<b>Ação</b> &amp; aventura',
                'genres': [
                  {'description': 'Aventura'},
                ],
                'price_overview': {'currency': 'USD', 'final': 399},
              },
            },
          });
        }),
      );
      final info = await api.lookup(oldDeal);
      expect(info!.summary, 'Ação & aventura');
      expect(info.brazilPrice, isNull);
    },
  );
  test('Não usa a descrição de um jogo com nome parecido', () async {
    final api = GameInfoApi(
      MockClient(
        (req) async => req.url.path.endsWith('/games')
            ? jsonResponse({
                'info': {'steamAppID': null},
              })
            : jsonResponse({
                'items': [
                  {'name': 'Exemplo II', 'id': 82},
                ],
              }),
      ),
    );
    expect(await api.lookup(oldDeal), isNull);
  });
}
