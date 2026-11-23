import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/deal.dart';
import 'cheapshark_api.dart';

class GameInfo {
  const GameInfo(this.summary, this.genres, this.banner, this.brazilPrice);
  final String summary, genres, banner;
  final double? brazilPrice;
}

class GameInfoApi {
  GameInfoApi(this.client);
  final http.Client client;

  Future<Map<String, dynamic>> _steam(
    String path,
    Map<String, String> query,
  ) async {
    final response = await client
        .get(
          Uri.https('store.steampowered.com', path, {
            'cc': 'br',
            'l': 'brazilian',
            ...query,
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw const ApiFailure('A Steam está indisponível.');
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  Future<GameInfo?> lookup(Deal deal) async {
    var id =
        deal.steamAppId ?? await CheapSharkApi(client).steamIdFor(deal.gameId);
    if (id == null) {
      // Algumas lojas não informam o appID. Evita confundir jogos com títulos parecidos.
      final matches = await _steam('/api/storesearch/', {'term': deal.title});
      final exact = (matches['items'] as List).where(
        (item) =>
            item['name'].toString().trim().toLowerCase() ==
            deal.title.trim().toLowerCase(),
      );
      if (exact.length != 1) return null;
      id = Deal.validSteamId(exact.single['id']);
      if (id == null) return null;
    }
    final result = (await _steam('/api/appdetails', {'appids': id}))[id];
    if (result == null || result['success'] != true) return null;
    final data = result['data'] as Map<String, dynamic>;
    final price = data['price_overview'];
    final cents = price is Map && price['currency'] == 'BRL'
        ? price['final']
        : null;
    return GameInfo(
      _plainText(data['short_description'] as String? ?? ''),
      (data['genres'] as List? ?? [])
          .map((g) => g['description'])
          .whereType<String>()
          .join(' · '),
      data['header_image'] as String? ?? '',
      cents is num && cents >= 0 ? cents / 100 : null,
    );
  }

  String _plainText(String input) {
    const entities = {
      'amp': '&',
      'lt': '<',
      'gt': '>',
      'quot': '"',
      'apos': "'",
      'nbsp': ' ',
      'ndash': '–',
      'mdash': '—',
      'rsquo': '’',
      'lsquo': '‘',
      'rdquo': '”',
      'ldquo': '“',
      'hellip': '…',
    };
    return input
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAllMapped(RegExp(r'&(#x[\da-fA-F]+|#\d+|\w+);'), (match) {
          final key = match[1]!;
          if (!key.startsWith('#')) return entities[key] ?? match[0]!;
          final hex = key.startsWith('#x');
          final n = int.tryParse(
            key.substring(hex ? 2 : 1),
            radix: hex ? 16 : 10,
          );
          return n != null && n >= 0 && n <= 0x10ffff
              ? String.fromCharCode(n)
              : match[0]!;
        })
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
