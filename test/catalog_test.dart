import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trabalho_final/data/cheapshark_api.dart';
import 'package:trabalho_final/state/deals_provider.dart';

http.Response response(Object data) =>
    http.Response.bytes(utf8.encode(jsonEncode(data)), 200);
void main() {
  test(
    'Filtro mais recente prevalece mesmo se uma resposta anterior chegar depois',
    () async {
      final slow = Completer<http.Response>();
      final queries = <Map<String, String>>[];
      final api = CheapSharkApi(
        MockClient((req) async {
          if (req.url.path.endsWith('stores')) {
            return response([
              {'storeID': '1', 'storeName': 'Steam', 'isActive': 1},
              {'storeID': '7', 'storeName': 'GOG', 'isActive': 1},
              {'storeID': '25', 'storeName': 'Epic Games Store', 'isActive': 0},
            ]);
          }
          queries.add(req.url.queryParameters);
          final store = req.url.queryParameters['storeID'];
          if (store == '1') return slow.future;
          if (store == null) return response([]);
          return response([
            {
              'dealID': 'A%2BB',
              'gameID': '2',
              'storeID': store,
              'title': 'Jogo',
              'thumb': '',
              'normalPrice': '20',
              'salePrice': '5',
              'savings': '75',
            },
          ]);
        }),
      );
      final state = DealsProvider(api);
      await state.load();
      expect(state.filters.map((s) => s.name), ['Steam', 'GOG']);
      expect(queries.first, {'onSale': '1', 'pageSize': '30'});
      final first = state.load('1');
      await state.load('7');
      slow.complete(response([]));
      await first;
      expect(state.selected, '7');
      expect(state.deals.single.discount, 75);
      expect(state.deals.single.link.queryParameters['dealID'], 'A+B');
      expect(state.loading, isFalse);
      expect(state.error, isNull);
    },
  );

  test('Falha da API pode ser recuperada com nova consulta', () async {
    var available = false;
    final state = DealsProvider(
      CheapSharkApi(
        MockClient(
          (req) async => available ? response([]) : http.Response('', 503),
        ),
      ),
    );
    await state.load();
    expect(state.error, contains('503'));
    available = true;
    await state.load();
    expect(state.error, isNull);
    expect(state.deals, isEmpty);
  });
}
