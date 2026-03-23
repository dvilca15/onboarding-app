import 'package:flutter/material.dart';
import 'dart:math' as math;

class DonutChart extends StatelessWidget {
  final int completados;
  final int enProgreso;
  final int pendientes;

  const DonutChart({
    super.key,
    required this.completados,
    required this.enProgreso,
    required this.pendientes,
  });

  int get total => completados + enProgreso + pendientes;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: CustomPaint(
        painter: _DonutPainter(
          completados: completados,
          enProgreso: enProgreso,
          pendientes: pendientes,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                total.toString(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const Text(
                'total',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final int completados;
  final int enProgreso;
  final int pendientes;

  _DonutPainter({
    required this.completados,
    required this.enProgreso,
    required this.pendientes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = completados + enProgreso + pendientes;
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 22.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    const totalAngle = 2 * math.pi;

    paint.color = const Color(0xFFF3F4F6);
    canvas.drawCircle(center, radius, paint);

    double currentAngle = startAngle;
    final segments = [
      (completados, const Color(0xFF10B981)),
      (enProgreso, const Color(0xFFF59E0B)),
      (pendientes, const Color(0xFFE5E7EB)),
    ];

    for (final seg in segments) {
      if (seg.$1 == 0) continue;
      final sweep = (seg.$1 / total) * totalAngle;
      paint.color = seg.$2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle + 0.03,
        sweep - 0.06,
        false,
        paint,
      );
      currentAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.completados != completados ||
      old.enProgreso != enProgreso ||
      old.pendientes != pendientes;
}


class LegendItem extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;

  const LegendItem({
    super.key,
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (value / total * 100).round() : 0;
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
          ),
        ),
        Text(
          '$value ($pct%)',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }
}