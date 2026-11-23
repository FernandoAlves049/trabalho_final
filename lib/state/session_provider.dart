import 'package:flutter/foundation.dart';
import '../data/app_database.dart';
import '../data/auth_service.dart';
import '../models/deal.dart';

class SessionProvider extends ChangeNotifier {
  SessionProvider(this.storage) : auth = AuthService(storage);
  final AppDatabase storage;
  final AuthService auth;
  AppUser? _user;
  AppUser? get user => _user;
  final _saved = <String, SavedDeal>{};
  final _pending = <String>{};
  int _generation = 0;

  List<SavedDeal> get favorites =>
      _saved.values.toList()..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  bool isFavorite(String id) => _saved.containsKey(id);
  bool isSaving(String id) => _pending.contains(id);

  Future<void> login(String email, String password) async {
    final generation = ++_generation;
    final account = await auth.authenticate(email, password);
    final items = await storage.favorites(account.id);
    if (generation != _generation) return;
    _user = account;
    _saved
      ..clear()
      ..addEntries(items.map((item) => MapEntry(item.deal.id, item)));
    notifyListeners();
  }

  void logout() {
    _generation++;
    _user = null;
    _saved.clear();
    _pending.clear();
    notifyListeners();
  }

  Future<void> toggle(Deal deal, String store) async {
    final account = _user;
    if (account == null || !_pending.add(deal.id)) return;
    final generation = _generation;
    notifyListeners();
    try {
      if (isFavorite(deal.id)) {
        await storage.remove(account.id, deal.id);
        if (_generation == generation) _saved.remove(deal.id);
      } else {
        final item = SavedDeal(deal, store, DateTime.now());
        await storage.save(account.id, item);
        if (_generation == generation) _saved[deal.id] = item;
      }
    } finally {
      if (_generation == generation) {
        _pending.remove(deal.id);
        notifyListeners();
      }
    }
  }
}
