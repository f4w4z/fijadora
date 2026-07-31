import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/wallet_repository.dart';
import '../../../../domain/models/wallet.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../../core/utilities/responsive_helpers.dart';
import '../../services/service_constants.dart';

final myWalletProvider = StreamProvider<WorkerWallet?>((ref) {
  return ref.watch(walletRepositoryProvider).watchMyWallet();
});

final myTransactionsProvider = StreamProvider<List<WalletTransaction>>((ref) {
  return ref.watch(walletRepositoryProvider).watchMyTransactions();
});

final myPayoutsProvider = StreamProvider<List<Payout>>((ref) {
  return ref.watch(walletRepositoryProvider).watchMyPayouts();
});

class WorkerWalletView extends ConsumerWidget {
  const WorkerWalletView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final walletAsync = ref.watch(myWalletProvider);
    final txAsync = ref.watch(myTransactionsProvider);
    final payoutsAsync = ref.watch(myPayoutsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('My Wallet')),
      body: ListView(
        padding: EdgeInsets.all(context.pagePad),
        children: [
          walletAsync.when(
            loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Could not load wallet', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('$e', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            ),
            data: (wallet) => _BalanceCard(
              balance: wallet?.balance ?? 0,
              onWithdraw: wallet == null
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const WithdrawView()),
                      ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Recent Activity', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          txAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Could not load transactions: $e',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
            ),
            data: (txs) {
              if (txs.isEmpty) return const EmptyStateWidget(icon: CupertinoIcons.creditcard, title: 'No activity', message: 'Your earnings will appear here.');
              return Column(
                children: txs.map((t) => _TxTile(t)).toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          Text('Withdrawal History', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          payoutsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Could not load payouts: $e',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
            ),
            data: (payouts) {
              if (payouts.isEmpty) return const Text('No withdrawals yet.', style: TextStyle(fontSize: 13));
              return Column(
                children: payouts.map((p) => _PayoutTile(p)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance, required this.onWithdraw});
  final double balance;
  final VoidCallback? onWithdraw;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.75)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text(formatGhs(balance), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: onWithdraw,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: theme.colorScheme.primary,
              ),
              child: const Text('Withdraw'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  const _TxTile(this.tx);
  final WalletTransaction tx;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCredit = tx.type == WalletTransactionType.credit || tx.type == WalletTransactionType.adjustment;
    final amountColor = isCredit ? Colors.green : theme.colorScheme.error;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: amountColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(isCredit ? CupertinoIcons.arrow_down_left : CupertinoIcons.arrow_up_right,
                color: amountColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.description ?? tx.type.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text('${tx.createdAt.day}/${tx.createdAt.month}/${tx.createdAt.year}',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
          Text('${isCredit ? '+' : '-'}${formatGhs(tx.amount)}',
              style: TextStyle(color: amountColor, fontWeight: FontWeight.w700, fontSize: 14)),
        ],
      ),
    );
  }
}

class _PayoutTile extends StatelessWidget {
  const _PayoutTile(this.payout);
  final Payout payout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (payout.status) {
      PayoutStatus.completed => Colors.green,
      PayoutStatus.processing || PayoutStatus.approved => Colors.orange,
      PayoutStatus.rejected => theme.colorScheme.error,
      PayoutStatus.pending => theme.colorScheme.primary,
    };
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(CupertinoIcons.money_dollar, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatGhs(payout.amount), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  payout.bankAccountNumber != null
                      ? '****${payout.bankAccountNumber!.substring(payout.bankAccountNumber!.length - 4)}'
                      : 'No account',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
          StatusPill(label: payout.status.label, color: color),
        ],
      ),
    );
  }
}

class WithdrawView extends ConsumerStatefulWidget {
  const WithdrawView({super.key});

  @override
  ConsumerState<WithdrawView> createState() => _WithdrawViewState();
}

class _WithdrawViewState extends ConsumerState<WithdrawView> {
  final _amountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _bankCodeController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _bankCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(walletRepositoryProvider).requestPayout(
            amount,
            bankName: _bankNameController.text.trim(),
            accountNumber: _accountNumberController.text.trim(),
            accountName: _accountNameController.text.trim(),
            bankCode: _bankCodeController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawal requested. Staff will process it.')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wallet = ref.watch(myWalletProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Withdraw')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(context.pagePad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (wallet != null)
              Text('Available: ${formatGhs(wallet.balance)}', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bankNameController,
              decoration: const InputDecoration(labelText: 'Bank name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _accountNumberController,
              decoration: const InputDecoration(labelText: 'Account number', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _accountNameController,
              decoration: const InputDecoration(labelText: 'Account name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bankCodeController,
              decoration: const InputDecoration(labelText: 'Bank code (e.g. 058 for Zenith)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting ? const CircularProgressIndicator() : const Text('Request Withdrawal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
