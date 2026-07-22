import 'package:flutter/foundation.dart';

enum WalletTransactionType {
  credit,
  debit,
  payout,
  adjustment;

  String get label => name[0].toUpperCase() + name.substring(1);
}

@immutable
class WalletTransaction {
  final String id;
  final String walletId;
  final String workerId;
  final WalletTransactionType type;
  final double amount;
  final String? reference;
  final String? description;
  final DateTime createdAt;

  const WalletTransaction({
    required this.id,
    required this.walletId,
    required this.workerId,
    required this.type,
    required this.amount,
    this.reference,
    this.description,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] as String,
      walletId: json['wallet_id'] as String,
      workerId: json['worker_id'] as String,
      type: WalletTransactionType.values.firstWhere(
        (e) => e.name == (json['type'] as String? ?? 'credit'),
        orElse: () => WalletTransactionType.credit,
      ),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      reference: json['reference'] as String?,
      description: json['description'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wallet_id': walletId,
      'worker_id': workerId,
      'type': type.name,
      'amount': amount,
      'reference': reference,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

@immutable
class WorkerWallet {
  final String id;
  final String workerId;
  final double balance;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountName;
  final DateTime updatedAt;

  const WorkerWallet({
    required this.id,
    required this.workerId,
    required this.balance,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountName,
    required this.updatedAt,
  });

  factory WorkerWallet.fromJson(Map<String, dynamic> json) {
    return WorkerWallet(
      id: json['id'] as String,
      workerId: json['worker_id'] as String,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      bankName: json['bank_name'] as String?,
      bankAccountNumber: json['bank_account_number'] as String?,
      bankAccountName: json['bank_account_name'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'worker_id': workerId,
      'balance': balance,
      'bank_name': bankName,
      'bank_account_number': bankAccountNumber,
      'bank_account_name': bankAccountName,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

enum PayoutStatus {
  pending, // requested by worker, awaiting staff approval
  approved, // approved, Paystack transfer initiated
  processing, // transfer in flight
  completed, // funds transferred
  rejected; // denied by staff

  String get label => name[0].toUpperCase() + name.substring(1);
}

@immutable
class Payout {
  final String id;
  final String workerId;
  final String walletId;
  final double amount;
  final PayoutStatus status;
  final String? paystackTransferReference;
  final String? paystackRecipientCode;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Payout({
    required this.id,
    required this.workerId,
    required this.walletId,
    required this.amount,
    required this.status,
    this.paystackTransferReference,
    this.paystackRecipientCode,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Payout.fromJson(Map<String, dynamic> json) {
    return Payout(
      id: json['id'] as String,
      workerId: json['worker_id'] as String,
      walletId: json['wallet_id'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: PayoutStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? 'pending'),
        orElse: () => PayoutStatus.pending,
      ),
      paystackTransferReference: json['paystack_transfer_reference'] as String?,
      paystackRecipientCode: json['paystack_recipient_code'] as String?,
      bankName: json['bank_name'] as String?,
      bankAccountNumber: json['bank_account_number'] as String?,
      bankAccountName: json['bank_account_name'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'worker_id': workerId,
      'wallet_id': walletId,
      'amount': amount,
      'status': status.name,
      'paystack_transfer_reference': paystackTransferReference,
      'paystack_recipient_code': paystackRecipientCode,
      'bank_name': bankName,
      'bank_account_number': bankAccountNumber,
      'bank_account_name': bankAccountName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
