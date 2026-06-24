import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/trade_type.dart';
import '../view_models/jobs_view_model.dart';

class VoiceAssistantPage extends ConsumerStatefulWidget {
  const VoiceAssistantPage({super.key});

  @override
  ConsumerState<VoiceAssistantPage> createState() => _VoiceAssistantPageState();
}

class _VoiceAssistantPageState extends ConsumerState<VoiceAssistantPage> with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  String _assistantStateText = 'Listening... Say what needs fixing';
  String _userSpeechMock = '';
  bool _isListening = true;
  bool _isProcessing = false;
  Timer? _flowTimer;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _runSimulatedConversationFlow();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _flowTimer?.cancel();
    super.dispose();
  }

  void _runSimulatedConversationFlow() {
    _flowTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _isListening = false;
        _isProcessing = true;
        _userSpeechMock = '"My kitchen sink is leaking from the pipe washer underneath."';
        _assistantStateText = 'Analyzing voice input...';
      });

      _flowTimer = Timer(const Duration(seconds: 3), () async {
        if (!mounted) return;
        setState(() {
          _assistantStateText = 'Booking Plumbing Service...';
        });

        try {
          await ref.read(jobsViewModelProvider.notifier).raiseJob(
                description: 'Kitchen sink pipe is leaking from the washer underneath. Booked via Voice Assistant.',
                tradeType: TradeType.plumbing,
                schedule: DateTime.now().add(const Duration(days: 1, hours: 2)),
                address: 'Apartment 4B, Oakwood Heights, NY',
                images: const [],
              );

          if (mounted) {
            setState(() {
              _isProcessing = false;
              _assistantStateText = 'Plumbing service scheduled successfully for tomorrow!';
            });

            _flowTimer = Timer(const Duration(milliseconds: 2500), () {
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Plumbing request booked by Voice Assistant!')),
                );
              }
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isProcessing = false;
              _assistantStateText = 'Error booking service: $e';
            });
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(CupertinoIcons.waveform, size: 20),
            SizedBox(width: 8),
            Text(
              'Phoebe Voice AI',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.xmark_circle_fill, color: Colors.grey),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),

              Text(
                _assistantStateText,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),

              if (_userSpeechMock.isNotEmpty)
                Text(
                  _userSpeechMock,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),

              const SizedBox(height: 40),

              if (_isListening || _isProcessing)
                Center(
                  child: SizedBox(
                    height: 60,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(11, (index) {
                        final scale = 1.0 + (index % 3 == 0 ? 1.5 : (index % 2 == 0 ? 0.8 : 1.2));
                        return AnimatedBuilder(
                          animation: _waveController,
                          builder: (context, child) {
                            final value = _waveController.value;
                            final animatedHeight = 10.0 + (25.0 * value * scale);
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3.0),
                              width: 3.5,
                              height: animatedHeight,
                              decoration: BoxDecoration(
                                color: _isProcessing
                                    ? theme.colorScheme.secondary
                                    : theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(2.0),
                              ),
                            );
                          },
                        );
                      }),
                    ),
                  ),
                )
              else
                Center(
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.green.withValues(alpha: 0.1),
                    child: const Icon(CupertinoIcons.checkmark_alt, color: Colors.green, size: 36),
                  ),
                ),

              const Spacer(flex: 3),

              Text(
                _isListening
                    ? 'Active Mic Connection'
                    : _isProcessing
                        ? 'Processing Audio Input...'
                        : 'Request Registered',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
