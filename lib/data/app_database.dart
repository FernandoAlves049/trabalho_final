import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/deal.dart';
import '../models/exchange_rate.dart';

class AppUser {
  const AppUser(this.id, this.name, this.email);
  final int id;
  final String name, email;
}

class AccountFailure implements Exception {
  const AccountFailure(this.message);
  final String message;
}

class AppDatabase {
  AppDatabase(this.factory, {this.path});
  final DatabaseFactory factory;
  final String? path;
  Database? _opened;
  Future<Database>? _opening;

  Future<Database> get database async {
    if (_opened != null) return _opened!;
    try {
      return _opened = await (_opening ??= _open());
    } finally {
      _opening = null;
    }
  }

  Future<Database> _open() async => factory.openDatabase(
    path ?? p.join(await factory.getDatabasesPath(), 'pixel_radar.db'),
    options: OpenDatabaseOptions(
      version: 2,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, _) async {
        await db.execute('''CREATE TABLE users (
          id INTEGER PRIMARY KEY, name TEXT NOT NULL, email TEXT NOT NULL UNIQUE,
          password_hash TEXT NOT NULL, password_salt TEXT NOT NULL)''');
        await db.execute(
          '''CREATE TABLE favorites (
          user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          deal_id TEXT NOT NULL, game_id TEXT NOT NULL, store_id TEXT NOT NULL,
          store_name TEXT NOT NULL, title TEXT NOT NULL, thumb TEXT NOT NULL,
          regular REAL NOT NULL, price REAL NOT NULL, discount INTEGER NOT NULL,
          saved_at TEXT NOT NULL, steam_app_id TEXT, PRIMARY KEY(user_id, deal_id))''',
        );
        await _createExchangeTable(db);
      },
      onUpgrade: (db, oldVersion, _) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE favorites ADD COLUMN steam_app_id TEXT',
          );
          await _createExchangeTable(db);
        }
      },
    ),
  );

  Future<void> _createExchangeTable(Database db) => db.execute(
    'CREATE TABLE usd_brl (id INTEGER PRIMARY KEY, rate REAL NOT NULL, date TEXT NOT NULL)',
  );

  Future<ExchangeRate?> readExchangeRate() async {
    final rows = await (await database).query('usd_brl', limit: 1);
    return rows.isEmpty ? null : ExchangeRate.fromMap(rows.single);
  }

  Future<void> saveExchangeRate(ExchangeRate quote) async {
    await (await database).insert('usd_brl', {
      'id': 1,
      'rate': quote.rate,
      'date': quote.date.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<SavedDeal>> favorites(int owner) async =>
      (await (await database).query(
        'favorites',
        where: 'user_id = ?',
        whereArgs: [owner],
        orderBy: 'saved_at DESC, deal_id',
      )).map(SavedDeal.fromRow).toList();

  Future<void> save(int owner, SavedDeal item) async {
    await (await database).insert(
      'favorites',
      item.toRow(owner),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> remove(int owner, String id) async {
    await (await database).delete(
      'favorites',
      where: 'user_id = ? AND deal_id = ?',
      whereArgs: [owner, id],
    );
  }
}
