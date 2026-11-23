import 'package:flutter/foundation.dart';
import '../data/cheapshark_api.dart';
import '../models/deal.dart';

class DealsProvider extends ChangeNotifier {
  DealsProvider(this.api);
  final CheapSharkApi api;
  List<Store> stores = [];
  List<Deal> deals = [];
  String? selected, error;
  bool loading = true;
  int _request = 0;

  List<Store> get filters => [
    for (final name in ['Steam', 'Epic Games Store', 'GOG'])
      ...stores.where((s) => s.active && s.name == name),
  ];

  String storeName(String id) =>
      stores.where((s) => s.id == id).firstOrNull?.name ?? 'Loja $id';

  Future<void> load([String? storeId]) async {
    final request = ++_request;
    selected = storeId;
    loading = true;
    error = null;
    deals = [];
    notifyListeners();
    try {
      if (stores.isEmpty) {
        final available = await api.stores();
        if (request != _request) return;
        stores = available;
        notifyListeners();
      }
      final results = await api.deals(storeId);
      if (request != _request) return;
      deals = results;
    } catch (e) {
      if (request != _request) return;
      error = e is ApiFailure
          ? e.message
          : 'Verifique sua conexão e tente carregar as ofertas novamente.';
    } finally {
      if (request == _request) {
        loading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _request++;
    super.dispose();
  }
}
