class Deal {
  const Deal({
    required this.id,
    required this.gameId,
    required this.storeId,
    required this.title,
    required this.thumb,
    required this.regular,
    required this.price,
    required this.discount,
    this.steamAppId,
  });

  final String id, gameId, storeId, title, thumb;
  final double regular, price;
  final int discount;
  final String? steamAppId;

  static String? validSteamId(Object? value) {
    final id = value?.toString() ?? '';
    return RegExp(r'^[1-9][0-9]*$').hasMatch(id) ? id : null;
  }

  factory Deal.fromJson(Map<String, dynamic> json) => Deal(
    id: json['dealID'] as String,
    gameId: json['gameID'].toString(),
    steamAppId: validSteamId(json['steamAppID']),
    storeId: json['storeID'].toString(),
    title: json['title'] as String,
    thumb: json['thumb'] as String? ?? '',
    regular: double.parse(json['normalPrice'].toString()),
    price: double.parse(json['salePrice'].toString()),
    discount: double.parse(json['savings'].toString()).round(),
  );

  Uri get link => Uri.https('www.cheapshark.com', '/redirect', {
    'dealID': Uri.decodeComponent(id),
  });
}

class SavedDeal {
  const SavedDeal(this.deal, this.store, this.savedAt);
  final Deal deal;
  final String store;
  final DateTime savedAt;

  Map<String, Object?> toRow(int owner) => {
    'user_id': owner,
    'deal_id': deal.id,
    'game_id': deal.gameId,
    'steam_app_id': deal.steamAppId,
    'store_id': deal.storeId,
    'store_name': store,
    'title': deal.title,
    'thumb': deal.thumb,
    'regular': deal.regular,
    'price': deal.price,
    'discount': deal.discount,
    'saved_at': savedAt.toUtc().toIso8601String(),
  };

  factory SavedDeal.fromRow(Map<String, Object?> row) => SavedDeal(
    Deal(
      id: row['deal_id'] as String,
      gameId: row['game_id'] as String,
      steamAppId: row['steam_app_id'] as String?,
      storeId: row['store_id'] as String,
      title: row['title'] as String,
      thumb: row['thumb'] as String,
      regular: (row['regular'] as num).toDouble(),
      price: (row['price'] as num).toDouble(),
      discount: row['discount'] as int,
    ),
    row['store_name'] as String,
    DateTime.parse(row['saved_at'] as String).toLocal(),
  );
}

class Store {
  const Store(this.id, this.name, this.active);
  final String id, name;
  final bool active;

  factory Store.fromJson(Map<String, dynamic> json) => Store(
    json['storeID'].toString(),
    json['storeName'] as String,
    json['isActive'].toString() == '1',
  );
}
