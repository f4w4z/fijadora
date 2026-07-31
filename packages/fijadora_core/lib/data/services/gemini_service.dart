import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/product.dart';
import '../../domain/models/trade_type.dart';
import 'supabase_service.dart';

String _encodeBase64(Uint8List bytes) => base64Encode(bytes);

class AiDiagnosis {
  final String problemSummary;
  final List<String> requiredTools;
  final List<String> suggestedParts;
  final String priority;
  final String estimatedDuration;

  AiDiagnosis({
    required this.problemSummary,
    required this.requiredTools,
    required this.suggestedParts,
    required this.priority,
    required this.estimatedDuration,
  });

  factory AiDiagnosis.fromJson(Map<String, dynamic> json) => AiDiagnosis(
    problemSummary: json['problemSummary'] as String? ?? '',
    requiredTools: (json['requiredTools'] as List<dynamic>?)?.cast<String>() ?? [],
    suggestedParts: (json['suggestedParts'] as List<dynamic>?)?.cast<String>() ?? [],
    priority: json['priority'] as String? ?? 'Medium',
    estimatedDuration: json['estimatedDuration'] as String? ?? '1 hour',
  );

  @override
  String toString() {
    return '=== AI DIAGNOSIS ===\n'
        'Summary: $problemSummary\n'
        'Tools Needed: ${requiredTools.join(", ")}\n'
        'Parts Suggested: ${suggestedParts.join(", ")}\n'
        'Priority: $priority\n'
        'Est. Duration: $estimatedDuration';
  }
}

class GeminiService {
  static const _model = String.fromEnvironment('OPENROUTER_MODEL', defaultValue: 'google/gemini-2.0-flash-lite-001');

  Future<AiDiagnosis> diagnoseImage({
    required Uint8List? imageBytes,
    required TradeType tradeType,
  }) async {
    final client = SupabaseService.instance.client;
    final imageBase64 = imageBytes != null ? await compute(_encodeBase64, imageBytes) : null;

    final messages = [
      {'role': 'system', 'content': _systemPrompt},
      {'role': 'user', 'content': [
        {'type': 'text', 'text': _buildPrompt(tradeType)},
        if (imageBase64 != null)
          {'type': 'image_url', 'image_url': {'url': 'data:image/jpeg;base64,$imageBase64'}},
      ]},
    ];

    final resp = await client.functions.invoke('openrouter-proxy', body: {
      'model': _model,
      'messages': messages,
      'maxTokens': 512,
    });

    final data = resp.data;
    if (data != null) {
      final dataMap = data as Map<String, dynamic>;
      final choice = dataMap['choices']?[0];
      final text = choice?['message']?['content'] as String?;
      if (text != null) {
        final json = jsonDecode(text) as Map<String, dynamic>;
        return AiDiagnosis.fromJson(json);
      }
    }

    throw Exception('Empty response from OpenRouter proxy');
  }

  Future<List<Product>> getDesignRecommendations({
    required Uint8List? imageBytes,
    required List<Product> catalog,
  }) async {
    final client = SupabaseService.instance.client;
    final imageBase64 = imageBytes != null ? await compute(_encodeBase64, imageBytes) : null;

    final catalogText = catalog.asMap().entries.map((e) =>
      '[${e.key}] ${e.value.name} — GH₵${e.value.price.toStringAsFixed(0)} — ${e.value.category}'
    ).join('\n');

    final messages = [
      {'role': 'system', 'content': _designPrompt},
      {'role': 'user', 'content': [
        {'type': 'text', 'text': 'Catalog:\n$catalogText\n\nAnalyze the room photo and return indices of up to 4 matching products.'},
        if (imageBase64 != null)
          {'type': 'image_url', 'image_url': {'url': 'data:image/jpeg;base64,$imageBase64'}},
      ]},
    ];

    final resp = await client.functions.invoke('openrouter-proxy', body: {
      'model': _model,
      'messages': messages,
      'maxTokens': 512,
    });

    final data = resp.data;
    if (data != null) {
      final dataMap = data as Map<String, dynamic>;
      final choice = dataMap['choices']?[0];
      final text = choice?['message']?['content'] as String?;
      if (text != null) {
        final indices = jsonDecode(text) as List<dynamic>;
        return indices.map((i) => catalog[i as int]).toList();
      }
    }

    throw Exception('Empty response from OpenRouter proxy');
  }

  static const _designPrompt = '''
You are an interior design assistant. Analyze the room photo and return a JSON array of catalog product indices that match the room's style, color scheme, and function. Only return the array, no markdown.
''';

  static const _systemPrompt = '''
You are a maintenance diagnosis assistant. Analyze the provided image and trade type, then return a JSON object with:
- problemSummary: concise description of the issue
- requiredTools: list of tools needed
- suggestedParts: list of parts/materials needed
- priority: one of Critical, High, Medium, Low
- estimatedDuration: human readable estimated repair time (e.g. "30 mins", "2 hours")
Only return valid JSON, no markdown.
''';

  String _buildPrompt(TradeType tradeType) {
    return 'Diagnose the issue in this image for trade: ${tradeType.displayName}.';
  }
}

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});