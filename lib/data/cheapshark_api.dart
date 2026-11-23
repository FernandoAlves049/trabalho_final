import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/deal.dart';

class CheapSharkApi {
  CheapSharkApi(this.client);
  final http.Client client;

  Future<dynamic> _get(String path, [Map<String, String>? params]) async {
    final response = await client
        .get(
          Uri.https('www.cheapshark.com', '/api/1.0/$path', params),
          headers: {
            if (!kIsWeb)
              'User-Agent':
                  'PixelRadar/1.0 (Flutter; IF Goiano academic project)',
          },
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode == 429) {
      throw const ApiFailure(
        'Muitas consultas. Aguarde um pouco e tente novamente.',
      );
    }
    if (response.statusCode != 200) {
      throw ApiFailure(
        'A CheapShark retornou o código ${response.statusCode}. Tente novamente.',
      );
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<List<Store>> stores() async => (await _get('stores') as List)
      .cast<Map<String, dynamic>>()
      .map(Store.fromJson)
      .toList();

  Future<List<Deal>> deals(String? storeId) async =>
      (await _get('deals', {
                'onSale': '1',
                'pageSize': '30',
                'storeID': ?storeId,
              })
              as List)
          .cast<Map<String, dynamic>>()
          .map(Deal.fromJson)
          .toList();

  Future<String?> steamIdFor(String gameId) async {
    final result = await _get('games', {'id': gameId});
    return Deal.validSteamId(result['info']?['steamAppID']);
  }
}

class ApiFailure implements Exception {
  const ApiFailure(this.message);
  final String message;
}
