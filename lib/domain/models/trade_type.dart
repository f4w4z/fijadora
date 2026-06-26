import 'package:flutter/cupertino.dart';

enum TradeType {
  interiorDesign,
  electrical,
  plumbing,
  masonry,
  tiling,
  designConsultation,
  acEngineering,
  kitchenDesigns,
  cleaning,
  gardening;

  String get displayName {
    switch (this) {
      case TradeType.interiorDesign:
        return 'Interior Design';
      case TradeType.electrical:
        return 'Electrical';
      case TradeType.plumbing:
        return 'Plumbing';
      case TradeType.masonry:
        return 'Masonry';
      case TradeType.tiling:
        return 'Tiling';
      case TradeType.designConsultation:
        return 'Design Consultation';
      case TradeType.acEngineering:
        return 'AC Engineering';
      case TradeType.kitchenDesigns:
        return 'Kitchen Designs';
      case TradeType.cleaning:
        return 'Cleaning';
      case TradeType.gardening:
        return 'Gardening';
    }
  }

  IconData get icon {
    switch (this) {
      case TradeType.interiorDesign:
        return CupertinoIcons.house_fill;
      case TradeType.electrical:
        return CupertinoIcons.bolt_fill;
      case TradeType.plumbing:
        return CupertinoIcons.drop_fill;
      case TradeType.masonry:
        return CupertinoIcons.hammer_fill;
      case TradeType.tiling:
        return CupertinoIcons.square_grid_2x2_fill;
      case TradeType.designConsultation:
        return CupertinoIcons.paintbrush_fill;
      case TradeType.acEngineering:
        return CupertinoIcons.wind;
      case TradeType.kitchenDesigns:
        return CupertinoIcons.rectangle_stack_fill;
      case TradeType.cleaning:
        return CupertinoIcons.sparkles;
      case TradeType.gardening:
        return CupertinoIcons.leaf_arrow_circlepath;
    }
  }

  static TradeType fromString(String? value) {
    if (value == null) return TradeType.plumbing;
    return TradeType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TradeType.plumbing,
    );
  }
}
