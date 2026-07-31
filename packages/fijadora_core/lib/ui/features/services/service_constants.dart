import 'package:flutter/material.dart';
import '../../../domain/models/trade_type.dart';

// ─── Service Category Display Data ──────────────────────────────────────────

const serviceGradients = {
  TradeType.interiorDesign: [Color(0xFF8E44AD), Color(0xFFBB8FCE), Color(0xFFD7BDE2)],
  TradeType.electrical: [Color(0xFF7D3C98), Color(0xFFA569BD), Color(0xFFD2B4DE)],
  TradeType.plumbing: [Color(0xFF1A5276), Color(0xFF2980B9), Color(0xFF5DADE2)],
  TradeType.masonry: [Color(0xFF935116), Color(0xFFCA6F1E), Color(0xFFE59866)],
  TradeType.tiling: [Color(0xFF0E6251), Color(0xFF148F77), Color(0xFF52BE80)],
  TradeType.designConsultation: [Color(0xFFC0392B), Color(0xFFE74C3C), Color(0xFFF1948A)],
  TradeType.acEngineering: [Color(0xFF1B4F72), Color(0xFF2E86C1), Color(0xFF85C1E9)],
  TradeType.kitchenDesigns: [Color(0xFF4A235A), Color(0xFF76448A), Color(0xFFBB8FCE)],
  TradeType.cleaning: [Color(0xFF1A5276), Color(0xFF2980B9), Color(0xFF5DADE2)],
  TradeType.gardening: [Color(0xFF0E6251), Color(0xFF148F77), Color(0xFF52BE80)],
};

const serviceTaglines = {
  TradeType.interiorDesign: 'Full interior styling, space planning & decor',
  TradeType.electrical: 'Wiring, switches, panels & smart home',
  TradeType.plumbing: 'Fix leaks, unclog drains, install fixtures',
  TradeType.masonry: 'Brickwork, blockwork, concrete & stone repairs',
  TradeType.tiling: 'Floor & wall tiling, grout repair & waterproofing',
  TradeType.designConsultation: 'Expert advice on layout, materials & finishes',
  TradeType.acEngineering: 'AC installation, servicing & ductwork',
  TradeType.kitchenDesigns: 'Custom kitchen cabinetry, countertops & layout',
  TradeType.cleaning: 'Deep clean, move-in/out & routine upkeep',
  TradeType.gardening: 'Landscaping, lawn care, pruning & planting',
};

const serviceStartingPrices = {
  TradeType.interiorDesign: r'GH₵1,200',
  TradeType.electrical: r'GH₵350',
  TradeType.plumbing: r'GH₵400',
  TradeType.masonry: r'GH₵600',
  TradeType.tiling: r'GH₵500',
  TradeType.designConsultation: r'GH₵400',
  TradeType.acEngineering: r'GH₵550',
  TradeType.kitchenDesigns: r'GH₵1,500',
  TradeType.cleaning: r'GH₵250',
  TradeType.gardening: r'GH₵400',
};

/// Formats an amount as Ghana Cedis, e.g. GH₵120.50
String formatGhs(double amount) => 'GH₵${amount.toStringAsFixed(2)}';

const serviceImages = {
  TradeType.interiorDesign: 'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=400&h=500&fit=crop&auto=format',
  TradeType.electrical: 'https://images.unsplash.com/photo-1621905252507-b35492cc74b4?w=400&h=500&fit=crop&auto=format',
  TradeType.plumbing: 'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?w=400&h=500&fit=crop&auto=format',
  TradeType.masonry: 'https://images.unsplash.com/photo-1613665813446-82a78c468a1d?w=400&h=500&fit=crop&auto=format',
  TradeType.tiling: 'https://images.unsplash.com/photo-1622372738946-62e02505f1a4?w=400&h=500&fit=crop&auto=format',
  TradeType.designConsultation: 'https://images.unsplash.com/photo-1618220179428-22790b461013?w=400&h=500&fit=crop&auto=format',
  TradeType.acEngineering: 'https://images.unsplash.com/photo-1631545806600-52e4fdc2cade?w=400&h=500&fit=crop&auto=format',
  TradeType.kitchenDesigns: 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=500&fit=crop&auto=format',
  TradeType.cleaning: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400&h=500&fit=crop&auto=format',
  TradeType.gardening: 'https://images.unsplash.com/photo-1558904541-efa843a96f01?w=400&h=500&fit=crop&auto=format',
};

// ─── Business Rules ─────────────────────────────────────────────────────────

const operatingHoursStart = 13; // 1 PM
const operatingHoursEnd = 22; // 10 PM

const operatingHoursMessage =
    'Fijadora operates between 1 PM and 10 PM. Requests placed outside working hours will be reviewed next morning.';

const afterHoursMessage =
    'Operating hours are 1 PM to 10 PM. Since your request is outside operations, we\'re closed and will handle it in the morning.';
