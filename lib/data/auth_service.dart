import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:cryptography/helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'app_database.dart';

// Em plataformas nativas, compute executa a derivação fora da interface.
Future<List<int>> _derive((String, List<int>) input) async {
  final key = await Argon2id(
    memory: 19456,
    iterations: 2,
    parallelism: 1,
    hashLength: 32,
  ).deriveKeyFromPassword(password: input.$1, nonce: input.$2);
  return key.extractBytes();
}

class AuthService {
  AuthService(this.storage);
  final AppDatabase storage;

  Future<void> register(String name, String email, String password) async {
    final db = await storage.database;
    final random = Random.secure();
    final salt = List.generate(16, (_) => random.nextInt(256));
    final hash = await compute(_derive, (password, salt));
    try {
      await db.insert('users', {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password_hash': base64Encode(hash),
        'password_salt': base64Encode(salt),
      });
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) {
        throw const AccountFailure('Este e-mail já está cadastrado.');
      }
      rethrow;
    }
  }

  Future<AppUser> authenticate(String email, String password) async {
    const invalid = AccountFailure('E-mail ou senha incorretos.');
    final rows = await (await storage.database).query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    if (rows.isEmpty) throw invalid;
    final row = rows.single;
    final hash = await compute(_derive, (
      password,
      base64Decode(row['password_salt'] as String),
    ));
    if (!constantTimeBytesEquality.equals(
      hash,
      base64Decode(row['password_hash'] as String),
    )) {
      throw invalid;
    }
    return AppUser(
      row['id'] as int,
      row['name'] as String,
      row['email'] as String,
    );
  }
}
