import 'package:flutter/material.dart';
import 'dart:math';

class FieldPainter extends CustomPainter {
  final String shape;
  final List<Map<String, dynamic>> sensorDetails;
  final List<Offset> manualVertices;
  final BuildContext context;

  FieldPainter({required this.shape, required this.sensorDetails, required this.manualVertices, required this.context});

  @override
  void paint(Canvas canvas, Size size) {
    final colorScheme = Theme.of(context).colorScheme;
    
    final fieldPaint = Paint()
      ..color = colorScheme.primary.withOpacity(0.1)
      ..style = PaintingStyle.fill;
      
    final borderPaint = Paint()
      ..color = colorScheme.primary.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0;
      
    final gridPaint = Paint()
      ..color = colorScheme.primary.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final sensorHaloPaint = Paint()
      ..color = colorScheme.secondary.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final sensorCorePaint = Paint()
      ..color = colorScheme.secondary
      ..style = PaintingStyle.fill;
      
    // Draw Grid
    double step = 20;
    for(double x=0; x<size.width; x+=step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for(double y=0; y<size.height; y+=step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Draw Field
    if (shape == 'Circle') {
      final center = size.center(Offset.zero);
      final radius = min(size.width, size.height) / 2 * 0.85;
      canvas.drawCircle(center, radius, fieldPaint);
      canvas.drawCircle(center, radius, borderPaint);
    } else if (shape == 'Rectangle') {
      final rect = Rect.fromCenter(center: size.center(Offset.zero), width: size.width*0.85, height: size.height*0.85);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(20)), fieldPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(20)), borderPaint);
    } else {
      if (manualVertices.isEmpty) return;
      double minX = manualVertices.map((p) => p.dx).reduce(min);
      double maxX = manualVertices.map((p) => p.dx).reduce(max);
      double minY = manualVertices.map((p) => p.dy).reduce(min);
      double maxY = manualVertices.map((p) => p.dy).reduce(max);

      double w = maxX - minX; if(w==0) w=1;
      double h = maxY - minY; if(h==0) h=1;

      double scale = min((size.width * 0.85) / w, (size.height * 0.85) / h);
      double offX = (size.width - w * scale) / 2;
      double offY = (size.height - h * scale) / 2;

      final path = Path();
      path.moveTo(offX + (manualVertices[0].dx - minX) * scale, offY + (manualVertices[0].dy - minY) * scale);
      for(int i=1; i<manualVertices.length; i++) {
        path.lineTo(offX + (manualVertices[i].dx - minX) * scale, offY + (manualVertices[i].dy - minY) * scale);
      }
      path.close();

      canvas.drawPath(path, fieldPaint);
      canvas.drawPath(path, borderPaint);
    }

    // Draw Dynamic Sensors
    for (final detail in sensorDetails) {
      Offset normPos = detail['offset'] as Offset;
      Offset canvasPos;

      if (shape == 'Circle') {
        final center = size.center(Offset.zero);
        final maxR = min(size.width, size.height) / 2 * 0.85;
        double dx = (normPos.dx - 0.5) * 2 * maxR;
        double dy = (normPos.dy - 0.5) * 2 * maxR;
        canvasPos = center + Offset(dx, dy);
      } else if (shape == 'Rectangle') {
        final rect = Rect.fromCenter(center: size.center(Offset.zero), width: size.width*0.85, height: size.height*0.85);
        canvasPos = Offset(rect.left + normPos.dx * rect.width, rect.top + normPos.dy * rect.height);
      } else {
        double minX = manualVertices.map((p) => p.dx).reduce(min);
        double minY = manualVertices.map((p) => p.dy).reduce(min);
        double w = manualVertices.map((p) => p.dx).reduce(max) - minX;
        double h = manualVertices.map((p) => p.dy).reduce(max) - minY;
        if(w==0) w=1; if(h==0) h=1;
        double scale = min((size.width*0.85)/w, (size.height*0.85)/h);
        double offX = (size.width - w*scale)/2;
        double offY = (size.height - h*scale)/2;
        canvasPos = Offset(offX + (normPos.dx * w) * scale, offY + (normPos.dy * h) * scale);
      }

      canvas.drawCircle(canvasPos, 16, sensorHaloPaint);
      canvas.drawCircle(canvasPos, 6, sensorCorePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}