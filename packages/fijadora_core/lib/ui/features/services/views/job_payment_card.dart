import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../data/services/paystack_service.dart';
import '../../../../data/services/supabase_service.dart';
import '../../../../domain/models/maintenance_job.dart';
import '../../../../domain/models/job_status.dart';
import '../view_models/jobs_view_model.dart';
import '../service_constants.dart';

enum JobPaymentKind { deposit, balance, changeOrder }

/// Customer-facing payment cards for a service job:
/// - quote + deposit payment (status = quoted)
/// - approved change orders awaiting payment
/// - balance payment (status = completed, payment_status = balance_due)
class JobPaymentCard extends ConsumerStatefulWidget {
  const JobPaymentCard({super.key, required this.job});

  final MaintenanceJob job;

  @override
  ConsumerState<JobPaymentCard> createState() => _JobPaymentCardState();
}

class _JobPaymentCardState extends ConsumerState<JobPaymentCard>
    with WidgetsBindingObserver {
  bool _busy = false;
  String? _pendingRef;
  JobPaymentKind? _pendingKind;
  String? _pendingChangeOrderId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _pendingRef != null) {
      final refToVerify = _pendingRef;
      final kind = _pendingKind;
      final changeOrderId = _pendingChangeOrderId;
      _pendingRef = null;
      _pendingKind = null;
      _pendingChangeOrderId = null;
      if (refToVerify != null && kind != null) {
        _verifyPayment(refToVerify, kind, changeOrderId);
      }
    }
  }

  String _kindName(JobPaymentKind kind) => switch (kind) {
        JobPaymentKind.deposit => 'deposit',
        JobPaymentKind.balance => 'balance',
        JobPaymentKind.changeOrder => 'change_order',
      };

  Future<void> _pay({
    required JobPaymentKind kind,
    required double amount,
    String? changeOrderId,
  }) async {
    final job = widget.job;
    setState(() => _busy = true);
    try {
      final user = SupabaseService.instance.client.auth.currentUser;
      final email = user?.email ?? 'customer@fijadora.com';
      final reference =
          'JOB_${job.id.substring(0, 8)}_${_kindName(kind)}_${DateTime.now().millisecondsSinceEpoch}';

      final init = await PaystackService.instance.initializeCheckout(
        email: email,
        amountKobo: (amount * 100).round(),
        reference: reference,
        jobId: job.id,
        paymentKind: _kindName(kind),
        changeOrderId: changeOrderId,
        callbackUrl: 'fijadora://app/paystack-callback',
      );

      final isMock = init['mock'] == true;
      final authUrl = init['authorization_url'] as String?;

      if (isMock) {
        await _verifyPayment(reference, kind, changeOrderId);
        return;
      }

      if (authUrl != null) {
        final uri = Uri.parse(authUrl);
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not open browser. Pay at:\n$authUrl')),
            );
          }
          return;
        }
        _pendingRef = reference;
        _pendingKind = kind;
        _pendingChangeOrderId = changeOrderId;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Complete payment in browser, then return here to verify.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Payment failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyPayment(
      String reference, JobPaymentKind kind, String? changeOrderId) async {
    try {
      final result = await PaystackService.instance.verifyTransaction(
        reference,
        jobId: widget.job.id,
        paymentKind: _kindName(kind),
        changeOrderId: changeOrderId,
      );
      final status = result['status'] as String?;
      final gatewayResponse = result['gateway_response'] as String?;

      if (status == 'success') {
        ref.invalidate(jobsStreamProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment successful!')),
          );
        }
      } else if (status == 'failed') {
        final reason = gatewayResponse ?? 'Payment declined by bank or card issuer';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment failed: $reason. Please try again.')),
          );
        }
      } else if (status == 'abandoned') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment was not completed. Please try again.')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment could not be verified. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Verification failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final job = widget.job;
    final cards = <Widget>[];

    if (job.status == JobStatus.quoted) {
      cards.add(_buildQuoteCard(theme));
    }

    final unpaidChangeOrders = job.changeOrders
        .where((c) => c.status == 'approved' && job.paymentStatus != JobPaymentStatus.paid)
        .toList();
    for (final co in unpaidChangeOrders) {
      cards.add(_buildChangeOrderCard(theme, co));
    }

    if (job.status == JobStatus.completed &&
        job.paymentStatus == JobPaymentStatus.balanceDue) {
      cards.add(_buildBalanceCard(theme));
    }

    if (cards.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          cards[i],
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildQuoteCard(ThemeData theme) {
    final job = widget.job;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.doc_text, size: 18, color: Colors.amber),
              const SizedBox(width: 8),
              Text('Your Quote',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: theme.colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 12),
          _PriceRow(label: 'Service price', value: job.quoteAmount ?? 0),
          if (job.maxAmount != null && job.maxAmount! > 0) ...[
            const SizedBox(height: 6),
            _PriceRow(
              label: 'Maximum (not to exceed)',
              value: job.maxAmount!,
              muted: true,
            ),
          ],
          const Divider(height: 20),
          _PriceRow(label: 'Deposit to pay now', value: job.depositAmount ?? 0, bold: true),
          const SizedBox(height: 6),
          Text(
            'Paying the deposit confirms this quote. The balance is due when the job is complete.',
            style: TextStyle(fontSize: 11.5, color: theme.colorScheme.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _busy
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: () => _pay(
                      kind: JobPaymentKind.deposit,
                      amount: job.depositAmount ?? 0,
                    ),
                    icon: const Icon(CupertinoIcons.creditcard, size: 16),
                    label: Text(
                        'Pay Deposit ${formatGhs(job.depositAmount ?? 0)}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeOrderCard(ThemeData theme, JobChangeOrder co) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.hammer, size: 18, color: Colors.orange),
              const SizedBox(width: 8),
              Text('Approved Extra Work',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: theme.colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 8),
          Text(co.description,
              style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant, height: 1.4)),
          const SizedBox(height: 8),
          _PriceRow(label: 'Additional cost', value: co.amount, bold: true),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _busy
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: () => _pay(
                      kind: JobPaymentKind.changeOrder,
                      amount: co.amount,
                      changeOrderId: co.id,
                    ),
                    icon: const Icon(CupertinoIcons.creditcard, size: 16),
                    label: Text('Pay ${formatGhs(co.amount)}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade800,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(ThemeData theme) {
    final job = widget.job;
    final balance = job.balanceDue;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.checkmark_seal_fill, size: 18, color: Color(0xFF2E7D32)),
              const SizedBox(width: 8),
              Text('Work Complete',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: theme.colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 12),
          _PriceRow(label: 'Final amount', value: job.finalAmount ?? job.quoteAmount ?? 0),
          const SizedBox(height: 6),
          _PriceRow(label: 'Deposit paid', value: job.depositAmount ?? 0, muted: true),
          const Divider(height: 20),
          _PriceRow(label: 'Balance due', value: balance, bold: true),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _busy
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: () => _pay(kind: JobPaymentKind.balance, amount: balance),
                    icon: const Icon(CupertinoIcons.creditcard, size: 16),
                    label: Text('Pay Balance ${formatGhs(balance)}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.muted = false,
  });

  final String label;
  final double value;
  final bool bold;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = muted ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: bold ? 14 : 12.5,
              fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
              color: color,
            )),
        Text(formatGhs(value),
            style: TextStyle(
              fontSize: bold ? 15 : 12.5,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              color: bold ? theme.colorScheme.primary : color,
            )),
      ],
    );
  }
}
