import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/credentials.dart';

/// Stores the user's LLM API key and per-exchange API credentials in the
/// device keychain/keystore. Never transmitted to Arbitron servers.
/// See PRD §7.1 and §8.4.
class SecureKeyStore {
  SecureKeyStore();

  static const _apiKeyKey = 'llm_api_key';
  static const _exchangeCredsPrefix = 'exchange_creds_';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── LLM API key ──────────────────────────────────────────────────────────────
  Future<String?> readApiKey() => _storage.read(key: _apiKeyKey);
  Future<void> writeApiKey(String key) => _storage.write(key: _apiKeyKey, value: key);
  Future<void> deleteApiKey() => _storage.delete(key: _apiKeyKey);

  // ── Exchange credentials ─────────────────────────────────────────────────────
  Future<ExchangeCredentials?> readExchangeCredentials(String exchangeId) async {
    final json = await _storage.read(key: '$_exchangeCredsPrefix$exchangeId');
    if (json == null) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return ExchangeCredentials(
        exchangeId: exchangeId,
        apiKey: map['apiKey'] as String? ?? '',
        apiSecret: map['apiSecret'] as String? ?? '',
        passphrase: map['passphrase'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> writeExchangeCredentials(ExchangeCredentials creds) async {
    final json = jsonEncode({
      'apiKey': creds.apiKey,
      'apiSecret': creds.apiSecret,
      'passphrase': creds.passphrase,
    });
    await _storage.write(key: '$_exchangeCredsPrefix${creds.exchangeId}', value: json);
  }

  Future<void> deleteExchangeCredentials(String exchangeId) async {
    await _storage.delete(key: '$_exchangeCredsPrefix$exchangeId');
  }

  /// Returns the set of exchange IDs that have stored credentials.
  Future<Set<String>> connectedExchangeIds() async {
    final all = await _storage.readAll();
    return all.keys
        .where((k) => k.startsWith(_exchangeCredsPrefix))
        .map((k) => k.substring(_exchangeCredsPrefix.length))
        .toSet();
  }
}