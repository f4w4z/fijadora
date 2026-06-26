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
      case TradeType.interiorDesign:
        return AiDiagnosis(
          problemSummary: 'Room layout and color scheme assessment. Existing furniture arrangement underutilizes space.',
          requiredTools: ['Measuring Tape', 'Mood Board', 'Design Software'],
          suggestedParts: ['Sample Paint Swatches', 'Fabric Samples'],
          priority: 'Low (Aesthetic enhancement)',
          estimatedDuration: '2 hours',
        );
      case TradeType.electrical:
        return AiDiagnosis(
          problemSummary: 'Loose wiring contact inside single-pole rocker switch housing causing contact arcing and flickering.',
          requiredTools: ['Insulated Screwdriver', 'Wire Strippers', 'Voltage Tester'],
          suggestedParts: ['15A Single Pole Rocker Switch', 'Electrical Wire Nuts'],
          priority: 'Critical (Fire hazard risk)',
          estimatedDuration: '30 mins',
        );
      case TradeType.plumbing:
        return AiDiagnosis(
          problemSummary: 'Thread/joint leakage detected in underneath sink plumbing line. Water pressure has caused a slow gasket leak.',
          requiredTools: ['Adjustable Wrench', 'Thread Seal Tape', 'Pipe Cutter'],
          suggestedParts: ['1/2-inch Rubber Washer', 'PVC Threaded Coupling'],
          priority: 'High (Prevent potential water damage)',
          estimatedDuration: '45 mins',
        );
      case TradeType.masonry:
        return AiDiagnosis(
          problemSummary: 'Crack detected in brick mortar joint. Water ingress possible during heavy rain.',
          requiredTools: ['Mortar Mix', 'Trowel', 'Joint Raker'],
          suggestedParts: ['Type N Mortar Mix', 'Wall Ties'],
          priority: 'Medium (Structural integrity)',
          estimatedDuration: '1.5 hours',
        );
      case TradeType.tiling:
        return AiDiagnosis(
          problemSummary: 'Loose ceramic tile with cracked grout lines. Underlayment may be compromised.',
          requiredTools: ['Tile Cutter', 'Notched Trowel', 'Grout Float'],
          suggestedParts: ['Replacement Tile', 'Thinset Mortar', 'Grout'],
          priority: 'Low (Cosmetic)',
          estimatedDuration: '1 hour',
        );
      case TradeType.designConsultation:
        return AiDiagnosis(
          problemSummary: 'Space planning review. Current layout does not optimize natural light or traffic flow.',
          requiredTools: ['Laser Measure', 'Floor Plan Software'],
          suggestedParts: ['Material Sample Kit'],
          priority: 'Low (Planning phase)',
          estimatedDuration: '1 hour',
        );
      case TradeType.acEngineering:
        return AiDiagnosis(
          problemSummary: 'Evaporator coil freezing or low refrigerant charge detected. Filter is highly clogged restricting airflow.',
          requiredTools: ['Manifold Gauge Set', 'Hex Key Set', 'Fin Comb'],
          suggestedParts: ['20x20x1 Air Filter', 'Refrigerant R-410A (charging required)'],
          priority: 'Medium (Climate control degradation)',
          estimatedDuration: '1.5 hours',
        );
      case TradeType.kitchenDesigns:
        return AiDiagnosis(
          problemSummary: 'Cabinet door hinge mounting screws have stripped wood threads from cabinet frame. Sagging door.',
          requiredTools: ['Power Drill', 'Phillips Bit', 'Wood Glue'],
          suggestedParts: ['Wooden Dowels (for thread repair)', 'Replacement Cabinet Hinge Screws'],
          priority: 'Low (Functional)',
          estimatedDuration: '30 mins',
        );
      case TradeType.cleaning:
        return AiDiagnosis(
          problemSummary: 'Surface calcium buildup and mold colonization in grout joints.',
          requiredTools: ['Grout Brush', 'Safety Goggles', 'Scraper'],
          suggestedParts: ['Mildew Stain Remover', 'Silicone Grout Sealant'],
          priority: 'Medium (Hygiene recommendation)',
          estimatedDuration: '1 hour',
        );
      case TradeType.gardening:
        return AiDiagnosis(
          problemSummary: 'Overgrown shrubs and weeds. Soil compaction detected in planting beds.',
          requiredTools: ['Pruning Shears', 'Garden Fork', 'Leaf Rake'],
          suggestedParts: ['Compost Mix', 'Mulch'],
          priority: 'Low (Seasonal maintenance)',
          estimatedDuration: '2 hours',
        );
    }
  }
}

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});
