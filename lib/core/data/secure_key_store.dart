import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the user's LLM API key in the device keychain/keystore.
/// Never transmitted to Arbitron servers. See PRD §7.1.
class SecureKeyStore {
  SecureKeyStore();

  static const _apiKeyKey = 'llm_api_key';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<String?> readApiKey() => _storage.read(key: _apiKeyKey);

  Future<void> writeApiKey(String key) => _storage.write(key: _apiKeyKey, value: key);

  Future<void> deleteApiKey() => _storage.delete(key: _apiKeyKey);
}