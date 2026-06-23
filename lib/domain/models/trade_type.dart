import 'package:flutter/cupertino.dart';

enum TradeType {
  plumbing,
  electrical,
  carpentry,
  painting,
  hvac,
  cleaning,
  generalRepairs;

  String get displayName {
    switch (this) {
      case TradeType.plumbing:
        return 'Plumbing';
      case TradeType.electrical:
        return 'Electrical';
      case TradeType.carpentry:
        return 'Carpentry';
      case TradeType.painting:
        return 'Painting';
      case TradeType.hvac:
        return 'HVAC';
      case TradeType.cleaning:
        return 'Cleaning';
      case TradeType.generalRepairs:
        return 'General Repairs';
    }
  }

  IconData get icon {
    switch (this) {
      case TradeType.plumbing:
        return CupertinoIcons.drop_fill;
      case TradeType.electrical:
        return CupertinoIcons.bolt_fill;
      case TradeType.carpentry:
        return CupertinoIcons.square_grid_2x2_fill;
      case TradeType.painting:
        return CupertinoIcons.paintbrush_fill;
      case TradeType.hvac:
        return CupertinoIcons.wind;
      case TradeType.cleaning:
        return CupertinoIcons.sparkles;
      case TradeType.generalRepairs:
        return CupertinoIcons.wrench_fill;
    }
  }

  static TradeType fromString(String? value) {
    if (value == null) return TradeType.generalRepairs;
    return TradeType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TradeType.generalRepairs,
    );
  }
}
