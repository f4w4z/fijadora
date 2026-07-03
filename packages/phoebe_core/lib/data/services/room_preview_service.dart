import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

class RoomPreviewService {
  final Dio _dio = Dio();

  Future<List<Uint8List>> generatePreviews({
    required String productImageUrl,
    required Uint8List roomPhotoBytes,
  }) async {
    final productBytes = await _downloadImage(productImageUrl);

    final roomImage = await _decodeImage(roomPhotoBytes, maxDimension: 800);
    final productImage = await _decodeImage(productBytes, maxDimension: 400);

    final roomW = roomImage.width.toDouble();
    final roomH = roomImage.height.toDouble();
    final prodW = productImage.width.toDouble();
    final prodH = productImage.height.toDouble();

    final baseScale = (roomW * 0.35) / prodW;

    final angles = <_AngleConfig>[
      _AngleConfig(scale: baseScale, leftPct: 0.06, topPct: 0.38),
      _AngleConfig(scale: baseScale, leftPct: 0.52, topPct: 0.32),
      _AngleConfig(scale: baseScale * 1.3, leftPct: 0.28, topPct: 0.22),
      _AngleConfig(scale: baseScale * 0.7, leftPct: 0.08, topPct: 0.50),
    ];

    final results = <Uint8List>[];
    for (final angle in angles) {
      final left = roomW * angle.leftPct;
      final top = roomH * angle.topPct - (prodH * angle.scale);
      final img = await _composite(
        room: roomImage,
        product: productImage,
        dx: left.clamp(0, roomW - prodW * angle.scale),
        dy: top.clamp(0, roomH - prodH * angle.scale),
        scale: angle.scale,
      );
      results.add(img);
    }

    return results;
  }

  Future<Uint8List> _downloadImage(String url) async {
    final response = await _dio.get<Uint8List>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data!;
  }

  Future<ui.Image> _decodeImage(Uint8List bytes, {int maxDimension = 800}) async {
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: maxDimension);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<Uint8List> _composite({
    required ui.Image room,
    required ui.Image product,
    required double dx,
    required double dy,
    required double scale,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    canvas.drawImage(room, ui.Offset.zero, ui.Paint());

    final prodW = product.width.toDouble() * scale;
    final prodH = product.height.toDouble() * scale;

    final shadowPaint = ui.Paint()
      ..color = const ui.Color(0x40000000)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6);
    canvas.drawOval(
      ui.Rect.fromLTWH(dx + 6, dy + prodH - 3, prodW - 12, prodH * 0.08),
      shadowPaint,
    );

    final src = ui.Rect.fromLTWH(0, 0, product.width.toDouble(), product.height.toDouble());
    final dst = ui.Rect.fromLTWH(dx, dy, prodW, prodH);
    canvas.drawImageRect(product, src, dst, ui.Paint());

    final picture = recorder.endRecording();
    final img = await picture.toImage(room.width, room.height);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }
}

class _AngleConfig {
  final double scale;
  final double leftPct;
  final double topPct;
  const _AngleConfig({required this.scale, required this.leftPct, required this.topPct});
}

final roomPreviewServiceProvider = Provider<RoomPreviewService>((ref) {
  return RoomPreviewService();
});
