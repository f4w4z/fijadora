import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/trade_type.dart';
import 'supabase_service.dart';

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
    // Try calling through Supabase Edge Function
    try {
      final client = SupabaseService.instance.client;
      final imageBase64 = imageBytes != null ? base64Encode(imageBytes) : null;

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
    } catch (e) {
      debugPrint('GeminiService: Edge Function call failed ($e), using mock fallback');
      return _mockDiagnosis(tradeType);
    }
  }

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

AiDiagnosis _mockDiagnosis(TradeType tradeType) {
  switch (tradeType) {
    case TradeType.interiorDesign:
      return AiDiagnosis(
        problemSummary: 'Room layout and color scheme assessment. Existing furniture arrangement underutilizes space.',
        requiredTools: ['Measuring Tape', 'Mood Board', 'Design Software'],
        suggestedParts: ['Sample Paint Swatches', 'Fabric Samples'],
        priority: 'Low',
        estimatedDuration: '2 hours',
      );
    case TradeType.electrical:
      return AiDiagnosis(
        problemSummary: 'Loose wiring contact inside single-pole rocker switch housing causing contact arcing and flickering.',
        requiredTools: ['Insulated Screwdriver', 'Wire Strippers', 'Voltage Tester'],
        suggestedParts: ['15A Single Pole Rocker Switch', 'Electrical Wire Nuts'],
        priority: 'Critical',
        estimatedDuration: '30 mins',
      );
    case TradeType.plumbing:
      return AiDiagnosis(
        problemSummary: 'Thread/joint leakage detected in underneath sink plumbing line. Water pressure has caused a slow gasket leak.',
        requiredTools: ['Adjustable Wrench', 'Thread Seal Tape', 'Pipe Cutter'],
        suggestedParts: ['1/2-inch Rubber Washer', 'PVC Threaded Coupling'],
        priority: 'High',
        estimatedDuration: '45 mins',
      );
    case TradeType.masonry:
      return AiDiagnosis(
        problemSummary: 'Crack detected in brick mortar joint. Water ingress possible during heavy rain.',
        requiredTools: ['Mortar Mix', 'Trowel', 'Joint Raker'],
        suggestedParts: ['Type N Mortar Mix', 'Wall Ties'],
        priority: 'Medium',
        estimatedDuration: '1.5 hours',
      );
    case TradeType.tiling:
      return AiDiagnosis(
        problemSummary: 'Loose ceramic tile with cracked grout lines. Underlayment may be compromised.',
        requiredTools: ['Tile Cutter', 'Notched Trowel', 'Grout Float'],
        suggestedParts: ['Replacement Tile', 'Thinset Mortar', 'Grout'],
        priority: 'Low',
        estimatedDuration: '1 hour',
      );
    case TradeType.designConsultation:
      return AiDiagnosis(
        problemSummary: 'Space planning review. Current layout does not optimize natural light or traffic flow.',
        requiredTools: ['Laser Measure', 'Floor Plan Software'],
        suggestedParts: ['Material Sample Kit'],
        priority: 'Low',
        estimatedDuration: '1 hour',
      );
    case TradeType.acEngineering:
      return AiDiagnosis(
        problemSummary: 'Evaporator coil freezing or low refrigerant charge detected. Filter is highly clogged restricting airflow.',
        requiredTools: ['Manifold Gauge Set', 'Hex Key Set', 'Fin Comb'],
        suggestedParts: ['20x20x1 Air Filter', 'Refrigerant R-410A (charging required)'],
        priority: 'Medium',
        estimatedDuration: '1.5 hours',
      );
    case TradeType.kitchenDesigns:
      return AiDiagnosis(
        problemSummary: 'Cabinet door hinge mounting screws have stripped wood threads from cabinet frame. Sagging door.',
        requiredTools: ['Power Drill', 'Phillips Bit', 'Wood Glue'],
        suggestedParts: ['Wooden Dowels (for thread repair)', 'Replacement Cabinet Hinge Screws'],
        priority: 'Low',
        estimatedDuration: '30 mins',
      );
    case TradeType.cleaning:
      return AiDiagnosis(
        problemSummary: 'Surface calcium buildup and mold colonization in grout joints.',
        requiredTools: ['Grout Brush', 'Safety Goggles', 'Scraper'],
        suggestedParts: ['Mildew Stain Remover', 'Silicone Grout Sealant'],
        priority: 'Medium',
        estimatedDuration: '1 hour',
      );
    case TradeType.gardening:
      return AiDiagnosis(
        problemSummary: 'Overgrown shrubs and weeds. Soil compaction detected in planting beds.',
        requiredTools: ['Pruning Shears', 'Garden Fork', 'Leaf Rake'],
        suggestedParts: ['Compost Mix', 'Mulch'],
        priority: 'Low',
        estimatedDuration: '2 hours',
      );
  }
}

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});