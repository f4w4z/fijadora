import 'dart:convert';
import 'supabase_service.dart';

/// Server-side operations proxied through the `paystack` Supabase edge
/// function so the secret key never ships in the app bundle.
class PaystackService {
  static final PaystackService instance = PaystackService._();
  PaystackService._();

  Future<Map<String, dynamic>> _invoke(String action, Map<String, dynamic> body) async {
    final res = await SupabaseService.instance.client.functions.invoke(
      'paystack',
      body: {'action': action, ...body},
    );
    final decoded = jsonDecode(res.data is String ? res.data as String : jsonEncode(res.data));
    if (res.status != 200 || decoded is Map && decoded['error'] != null) {
      throw Exception(decoded is Map ? (decoded['error']?.toString() ?? 'Paystack error') : 'Paystack error');
    }
    return decoded as Map<String, dynamic>;
  }

  /// Initialize a charge for a customer checkout.
  /// Returns the authorization url + reference to open in a webview/browser.
  Future<Map<String, dynamic>> initializeCheckout({
    required String email,
    required int amountKobo,
    required String reference,
    String? orderId,
    String? callbackUrl,
  }) async {
    return _invoke('initialize', {
      'email': email,
      'amount': amountKobo,
      'reference': reference,
      'orderId': orderId,
      if (callbackUrl != null) 'callbackUrl': callbackUrl,
    });
  }

  /// Verify a completed transaction by reference.
  Future<Map<String, dynamic>> verifyTransaction(String reference) async {
    return _invoke('verify', {'reference': reference});
  }

  /// Create a Paystack transfer recipient for a worker's bank account.
  Future<Map<String, dynamic>> createTransferRecipient({
    required String name,
    required String accountNumber,
    required String bankCode,
    required String currency,
  }) async {
    return _invoke('create_recipient', {
      'name': name,
      'accountNumber': accountNumber,
      'bankCode': bankCode,
      'currency': currency,
    });
  }

  /// Initiate a transfer (payout) to a previously created recipient.
  Future<Map<String, dynamic>> initiateTransfer({
    required int amountKobo,
    required String recipientCode,
    required String reference,
  }) async {
    return _invoke('transfer', {
      'amount': amountKobo,
      'recipientCode': recipientCode,
      'reference': reference,
    });
  }

  /// Staff releases a worker withdrawal. Validates the approval PIN and
  /// performs the Paystack transfer server-side (recipient + transfer).
  Future<Map<String, dynamic>> approvePayout({
    required String payoutId,
    required String pin,
  }) async {
    return _invoke('approve_payout', {
      'payoutId': payoutId,
      'pin': pin,
    });
  }
}
