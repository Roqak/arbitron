import 'package:equatable/equatable.dart';

/// API credentials for a single exchange. Stored in secure storage, never in
/// app state. See PRD §4 (per-exchange configuration) and §8.4.
class ExchangeCredentials extends Equatable {
  final String exchangeId;
  final String apiKey;
  final String apiSecret;
  final String? passphrase; // OKX requires this

  const ExchangeCredentials({
    required this.exchangeId,
    required this.apiKey,
    required this.apiSecret,
    this.passphrase,
  });

  bool get isComplete => apiKey.isNotEmpty && apiSecret.isNotEmpty;

  @override
  List<Object?> get props => [exchangeId, apiKey, apiSecret, passphrase];
}