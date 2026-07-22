import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../domain/models/wallet.dart';
import '../services/supabase_service.dart';
import '../services/paystack_service.dart';
import 'polling_select.dart';

abstract class WalletRepository {
  Future<WorkerWallet?> getMyWallet();
  Stream<WorkerWallet?> watchMyWallet();
  Stream<List<WalletTransaction>> watchMyTransactions();
  Stream<List<Payout>> watchMyPayouts();
  Future<void> saveBankDetails({String? bankName, String? accountNumber, String? accountName});
  Future<String> requestPayout(double amount, {String? bankName, String? accountNumber, String? accountName, String? bankCode});

  // Staff
  Stream<List<WorkerWallet>> streamAllWallets();
  Stream<List<Payout>> streamPendingPayouts();
  Future<WorkerWallet?> getWalletForWorker(String workerId);
  Future<void> creditWorker(String workerId, double amount, {String? description, String? reference});
  Future<Map<String, dynamic>> approvePayout(String payoutId, {required String pin});

  // Admin-managed payout approval PIN
  Future<void> setPayoutPin(String pin);
  Future<String?> getPayoutPin();
}

class SupabaseWalletRepository implements WalletRepository {
  SupabaseWalletRepository(this._client);
  final sb.SupabaseClient _client;

  String? get _uid => _client.auth.currentUser?.id;

  @override
  Future<WorkerWallet?> getMyWallet() async {
    final uid = _uid;
    if (uid == null) return null;
    final data = await _client
        .from('worker_wallets')
        .select()
        .eq('worker_id', uid)
        .maybeSingle();
    if (data != null) return WorkerWallet.fromJson(data);
    // Auto-create a wallet if one doesn't exist yet (e.g. trigger missed).
    try {
      final inserted = await _client
          .from('worker_wallets')
          .insert({'worker_id': uid})
          .select()
          .maybeSingle();
      if (inserted != null) return WorkerWallet.fromJson(inserted);
    } catch (_) {
      // RLS or other error — fall through to null.
    }
    return null;
  }

  @override
  Stream<WorkerWallet?> watchMyWallet() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return pollingSelect<WorkerWallet>(
      client: _client,
      table: 'worker_wallets',
      fromJson: WorkerWallet.fromJson,
      eqColumn: 'worker_id',
      eqValue: uid,
    ).map((list) => list.isEmpty ? null : list.first);
  }

  @override
  Stream<List<WalletTransaction>> watchMyTransactions() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return pollingSelect<WalletTransaction>(
      client: _client,
      table: 'wallet_transactions',
      fromJson: WalletTransaction.fromJson,
      eqColumn: 'worker_id',
      eqValue: uid,
      orderBy: 'created_at',
      ascending: false,
    );
  }

  @override
  Stream<List<Payout>> watchMyPayouts() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return pollingSelect<Payout>(
      client: _client,
      table: 'payouts',
      fromJson: Payout.fromJson,
      eqColumn: 'worker_id',
      eqValue: uid,
      orderBy: 'created_at',
      ascending: false,
    );
  }

  @override
  Future<void> saveBankDetails({String? bankName, String? accountNumber, String? accountName}) async {
    final uid = _uid;
    if (uid == null) return;
    final wallet = await getMyWallet();
    final update = <String, dynamic>{};
    if (bankName != null) update['bank_name'] = bankName;
    if (accountNumber != null) update['bank_account_number'] = accountNumber;
    if (accountName != null) update['bank_account_name'] = accountName;
    if (wallet == null) {
      await _client.from('worker_wallets').insert({
        'worker_id': uid,
        ...update,
      });
    } else {
      await _client.from('worker_wallets').update(update).eq('worker_id', uid);
    }
  }

  @override
  Future<String> requestPayout(double amount, {String? bankName, String? accountNumber, String? accountName, String? bankCode}) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not authenticated');
    final wallet = await getMyWallet();
    if (wallet == null) throw Exception('No wallet found');
    if (amount <= 0) throw Exception('Amount must be greater than zero');
    if (amount > wallet.balance) throw Exception('Insufficient wallet balance');

    final reference = 'PO_${DateTime.now().millisecondsSinceEpoch}_$uid';
    final insert = <String, dynamic>{
      'worker_id': uid,
      'wallet_id': wallet.id,
      'amount': amount,
      'status': 'pending',
      'paystack_transfer_reference': reference,
    };
    if (bankName != null) insert['bank_name'] = bankName;
    if (accountNumber != null) insert['bank_account_number'] = accountNumber;
    if (accountName != null) insert['bank_account_name'] = accountName;
    if (bankCode != null) insert['bank_code'] = bankCode;

    await _client.from('payouts').insert(insert);
    return reference;
  }

  @override
  Stream<List<WorkerWallet>> streamAllWallets() {
    return pollingSelect<WorkerWallet>(
      client: _client,
      table: 'worker_wallets',
      fromJson: WorkerWallet.fromJson,
      orderBy: 'updated_at',
      ascending: false,
    );
  }

  @override
  Stream<List<Payout>> streamPendingPayouts() {
    return pollingSelect<Payout>(
      client: _client,
      table: 'payouts',
      fromJson: Payout.fromJson,
      eqColumn: 'status',
      eqValue: 'pending',
      orderBy: 'created_at',
      ascending: false,
    );
  }

  @override
  Future<WorkerWallet?> getWalletForWorker(String workerId) async {
    final data = await _client
        .from('worker_wallets')
        .select()
        .eq('worker_id', workerId)
        .maybeSingle();
    return data == null ? null : WorkerWallet.fromJson(data);
  }

  @override
  Future<void> creditWorker(String workerId, double amount, {String? description, String? reference}) async {
    await _client.rpc('credit_worker_wallet', params: {
      'p_worker_id': workerId,
      'p_amount': amount,
      'p_description': description,
      'p_reference': reference,
    });
  }

  @override
  Future<Map<String, dynamic>> approvePayout(String payoutId, {required String pin}) async {
    // The edge function validates the PIN and performs the Paystack transfer
    // (recipient creation + transfer) entirely server-side.
    return PaystackService.instance.approvePayout(payoutId: payoutId, pin: pin);
  }

  @override
  Future<void> setPayoutPin(String pin) async {
    await _client.rpc('set_payout_pin', params: {'p_pin': pin});
  }

  @override
  Future<String?> getPayoutPin() async {
    final result = await _client.rpc('get_payout_pin');
    return result as String?;
  }
}

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return SupabaseWalletRepository(SupabaseService.instance.client);
});
