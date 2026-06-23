import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/trade_type.dart';

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
  Future<AiDiagnosis> diagnoseImage({
    required String? imagePath,
    required TradeType tradeType,
  }) async {
    // Simulate API request delay
    await Future.delayed(const Duration(milliseconds: 1500));

    switch (tradeType) {
      case TradeType.plumbing:
        return AiDiagnosis(
          problemSummary: 'Thread/joint leakage detected in underneath sink plumbing line. Water pressure has caused a slow gasket leak.',
          requiredTools: ['Adjustable Wrench', 'Thread Seal Tape', 'Pipe Cutter'],
          suggestedParts: ['1/2-inch Rubber Washer', 'PVC Threaded Coupling'],
          priority: 'High (Prevent potential water damage)',
          estimatedDuration: '45 mins',
        );
      case TradeType.electrical:
        return AiDiagnosis(
          problemSummary: 'Loose wiring contact inside single-pole rocker switch housing causing contact arcing and flickering.',
          requiredTools: ['Insulated Screwdriver', 'Wire Strippers', 'Voltage Tester'],
          suggestedParts: ['15A Single Pole Rocker Switch', 'Electrical Wire Nuts'],
          priority: 'Critical (Fire hazard risk)',
          estimatedDuration: '30 mins',
        );
      case TradeType.hvac:
        return AiDiagnosis(
          problemSummary: 'Evaporator coil freezing or low refrigerant charge detected. Filter is highly clogged restricting airflow.',
          requiredTools: ['Manifold Gauge Set', 'Hex Key Set', 'Fin Comb'],
          suggestedParts: ['20x20x1 Air Filter', 'Refrigerant R-410A (charging required)'],
          priority: 'Medium (Climate control degradation)',
          estimatedDuration: '1.5 hours',
        );
      case TradeType.carpentry:
        return AiDiagnosis(
          problemSummary: 'Cabinet door hinge mounting screws have stripped wood threads from cabinet frame. Sagging door.',
          requiredTools: ['Power Drill', 'Phillips Bit', 'Wood Glue'],
          suggestedParts: ['Wooden Dowels (for thread repair)', 'Replacement Cabinet Hinge Screws'],
          priority: 'Low (Cosmetic/Functional annoyance)',
          estimatedDuration: '20 mins',
        );
      case TradeType.painting:
        return AiDiagnosis(
          problemSummary: 'Minor drywall puncture and surrounding paint peeling from moisture exposure.',
          requiredTools: ['Putty Knife', 'Sanding Block', 'Paint Roller'],
          suggestedParts: ['Spackling Paste', 'Wall Primer', 'Matching Latex Paint (Satin)'],
          priority: 'Low (Aesthetic maintenance)',
          estimatedDuration: '1 hour (excl. drying time)',
        );
      case TradeType.cleaning:
        return AiDiagnosis(
          problemSummary: 'Surface calcium buildup and mold colonization in grout joints.',
          requiredTools: ['Grout Brush', 'Safety Goggles', 'Scraper'],
          suggestedParts: ['Mildew Stain Remover', 'Silicone Grout Sealant'],
          priority: 'Medium (Hygiene recommendation)',
          estimatedDuration: '1 hour',
        );
      case TradeType.generalRepairs:
        return AiDiagnosis(
          problemSummary: 'General structural/operational wear on drywall/hardware.',
          requiredTools: ['Universal Toolkit', 'Screwdriver Set'],
          suggestedParts: ['Assorted Mounting Anchors', 'Standard Fasteners'],
          priority: 'Low',
          estimatedDuration: '30 mins',
        );
    }
  }
}

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});
