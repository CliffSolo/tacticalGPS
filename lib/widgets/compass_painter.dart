import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/catppuccin.dart';

class WaypointArrow {
  final double bearing;
  final Color color;
  final String label;
  final double distance;

  WaypointArrow({
    required this.bearing,
    required this.color,
    required this.label,
    this.distance = 0.0,
  });
}

class CompassPainter extends CustomPainter {
  final double heading;
  final double? destinationBearing;
  final bool showDestination;
  final List<WaypointArrow> waypoints;
  final Color primaryColor;
  final Color surfaceColor;
  final Color surface1Color;
  final Color overlay0Color;
  final Color textColor;
  final Color subtext0Color;
  final Color surface2Color;
  final Color northColor;

  CompassPainter({
    required this.heading,
    this.destinationBearing,
    this.showDestination = false,
    this.waypoints = const [],
    this.primaryColor = const Color(0xFF89B4FA),
    this.surfaceColor = const Color(0xFF313244),
    this.surface1Color = const Color(0xFF45475A),
    this.overlay0Color = const Color(0xFF6C7086),
    this.textColor = const Color(0xFFCDD6F4),
    this.subtext0Color = const Color(0xFFA6ADC8),
    this.surface2Color = const Color(0xFF585B70),
    this.northColor = const Color(0xFFF38BA8),
  });

  String _formatShortDistance(double meters) {
    if (meters < 1000) {
      final feet = meters * 3.28084;
      return '${feet.toStringAsFixed(0)}ft';
    } else {
      final miles = meters / 1609.344;
      return '${miles.toStringAsFixed(1)}mi';
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Rotate canvas for compass rose
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-heading * math.pi / 180);
    canvas.translate(-center.dx, -center.dy);

    _drawCompassRose(canvas, center, radius);
    _drawTickMarks(canvas, center, radius);
    _drawCardinalLabels(canvas, center, radius);

    canvas.restore();

    // Draw degree labels inside ring (fixed, not rotating)
    _drawDegreeLabels(canvas, center, radius);

    // Draw waypoint arrows
    for (final wp in waypoints) {
      // Scale arrow length based on distance
      // Max length at 1600m (1 mile), min length at 0m
      const double maxDist = 1600.0;
      const double maxFactor = 0.42;
      const double minFactor = 0.08;
      final double clampedDist = wp.distance.clamp(0.0, maxDist);
      final double factor = minFactor + (maxFactor - minFactor) * (clampedDist / maxDist);
      _drawColoredArrow(canvas, center, radius, wp.bearing, wp.color, factor,
          label: _formatShortDistance(wp.distance));
    }

    // Draw destination arrow
    if (showDestination && destinationBearing != null) {
      // Destination arrow also scales with distance if available
      _drawColoredArrow(canvas, center, radius, destinationBearing!,
          CatppuccinMocha.peach, 0.48);
    }

    // Draw heading arrow on top
    _drawHeadingArrow(canvas, center, radius);

    // Draw red N caret at top (fixed, always points up = North indicator)
    _drawNorthCaret(canvas, center, radius);
    _drawCenterInfo(canvas, center);
  }

  void _drawCompassRose(Canvas canvas, Offset center, double radius) {
    final ringPaint = Paint()
      ..color = surface1Color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 4, ringPaint);

    final innerPaint = Paint()
      ..color = surfaceColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 6, innerPaint);

    final ring2Paint = Paint()
      ..color = overlay0Color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius * 0.75, ring2Paint);
  }

  void _drawTickMarks(Canvas canvas, Offset center, double radius) {
    final majorPaint = Paint()
      ..color = subtext0Color
      ..strokeWidth = 2;
    final minorPaint = Paint()
      ..color = surface2Color
      ..strokeWidth = 1;

    for (int i = 0; i < 360; i += 5) {
      final angle = i * math.pi / 180;
      final isMajor = i % 45 == 0;
      final isMinor = i % 10 == 0;
      final tickLength = isMajor
          ? radius * 0.18
          : (isMinor ? radius * 0.12 : radius * 0.07);
      final paint = (isMajor || isMinor) ? majorPaint : minorPaint;

      final outerX = center.dx + (radius - 6) * math.sin(angle);
      final outerY = center.dy - (radius - 6) * math.cos(angle);
      final innerX = center.dx + (radius - 6 - tickLength) * math.sin(angle);
      final innerY = center.dy - (radius - 6 - tickLength) * math.cos(angle);

      canvas.drawLine(Offset(outerX, outerY), Offset(innerX, innerY), paint);
    }
  }

  void _drawCardinalLabels(Canvas canvas, Offset center, double radius) {
    final cardinals = {'N': 0.0, 'E': 90.0, 'S': 180.0, 'W': 270.0};
    final intercardinals = {
      'NE': 45.0, 'SE': 135.0, 'SW': 225.0, 'NW': 315.0
    };

    for (final entry in cardinals.entries) {
      _drawLabel(canvas, center, radius, entry.key, entry.value,
          entry.key == 'N' ? northColor : textColor, 16);
    }
    for (final entry in intercardinals.entries) {
      _drawLabel(canvas, center, radius, entry.key, entry.value,
          subtext0Color, 11);
    }
  }

  void _drawLabel(Canvas canvas, Offset center, double radius, String label,
      double angleDeg, Color color, double fontSize) {
    final angle = angleDeg * math.pi / 180;
    final labelRadius = radius * 0.58;
    final x = center.dx + labelRadius * math.sin(angle);
    final y = center.dy - labelRadius * math.cos(angle);

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, y - textPainter.height / 2),
    );
  }

  // Fixed degree labels inside the ring — N/S/E/W positions relative to heading
  void _drawDegreeLabels(Canvas canvas, Offset center, double radius) {
    final innerRadius = radius * 0.82;
    final positions = [
      {'deg': 0.0, 'angle': -heading},           // Top = current heading
      {'deg': 90.0, 'angle': 90.0 - heading},    // Right
      {'deg': 180.0, 'angle': 180.0 - heading},  // Bottom
      {'deg': 270.0, 'angle': 270.0 - heading},  // Left
    ];

    for (final pos in positions) {
      final deg = pos['deg']!;
      final displayDeg = ((heading + deg) % 360).toStringAsFixed(0);
      final angleRad = pos['angle']! * math.pi / 180;

      final x = center.dx + innerRadius * math.sin(angleRad);
      final y = center.dy - innerRadius * math.cos(angleRad);

      final textPainter = TextPainter(
        text: TextSpan(
          text: displayDeg,
          style: TextStyle(
            color: CatppuccinMocha.subtext0.withOpacity(0.8),
            fontSize: 9,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  // Red downward caret at top of compass — fixed North indicator

  String _cardinalFromDeg(double deg) {
    final d = deg % 360;
    if (d < 22.5 || d >= 337.5) return 'N';
    if (d < 67.5) return 'NE';
    if (d < 112.5) return 'E';
    if (d < 157.5) return 'SE';
    if (d < 202.5) return 'S';
    if (d < 247.5) return 'SW';
    if (d < 292.5) return 'W';
    return 'NW';
  }

  void _drawCenterInfo(Canvas canvas, Offset center) {
    final deg = heading.toStringAsFixed(0);
    final cardinal = _cardinalFromDeg(heading);
    const gap = 10.0;

    // Degrees on left
    final degPainter = TextPainter(
      text: TextSpan(
        text: '$deg°',
        style: TextStyle(
          color: CatppuccinMocha.blue.withOpacity(0.85),
          fontSize: 13,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    degPainter.layout();

    // Cardinal on right
    final cardPainter = TextPainter(
      text: TextSpan(
        text: cardinal,
        style: TextStyle(
          color: CatppuccinMocha.subtext0.withOpacity(0.85),
          fontSize: 13,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    cardPainter.layout();

    final totalWidth = degPainter.width + gap + cardPainter.width;
    final startX = center.dx - totalWidth / 2;
    final y = center.dy - degPainter.height / 2 + 2;

    // Subtle background pill
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + 2),
        width: totalWidth + 16,
        height: degPainter.height + 8,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      bgRect,
      Paint()..color = CatppuccinMocha.base.withOpacity(0.55),
    );

    // Draw degrees left of center
    degPainter.paint(canvas, Offset(startX, y));

    // Separator dot
    canvas.drawCircle(
      Offset(startX + degPainter.width + gap / 2, center.dy + 2),
      2,
      Paint()..color = CatppuccinMocha.overlay0.withOpacity(0.6),
    );

    // Draw cardinal right of center
    cardPainter.paint(canvas, Offset(startX + degPainter.width + gap, y));
  }

  void _drawNorthCaret(Canvas canvas, Offset center, double radius) {
    final caretY = center.dy - (radius - 4);
    final caretSize = 8.0;

    final paint = Paint()
      ..color = CatppuccinMocha.red
      ..style = PaintingStyle.fill;

    // Downward pointing triangle (caret) at very top of ring
    final path = Path()
      ..moveTo(center.dx, caretY + caretSize)
      ..lineTo(center.dx - caretSize * 0.6, caretY)
      ..lineTo(center.dx + caretSize * 0.6, caretY)
      ..close();

    canvas.drawPath(path, paint);
  }

  void _drawHeadingArrow(Canvas canvas, Offset center, double radius) {
    final arrowLength = radius * 0.5;
    final paint = Paint()
      ..color = primaryColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final tipX = center.dx;
    final tipY = center.dy - arrowLength;
    final tailY = center.dy + arrowLength * 0.4;

    canvas.drawLine(Offset(center.dx, tailY), Offset(tipX, tipY), paint);

    final arrowPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(tipX, tipY)
      ..lineTo(tipX - 8, tipY + 18)
      ..lineTo(tipX + 8, tipY + 18)
      ..close();
    canvas.drawPath(path, arrowPaint);

    canvas.drawCircle(center, 6, Paint()..color = surfaceColor);
    canvas.drawCircle(center, 4, Paint()..color = primaryColor);
  }

  void _drawColoredArrow(Canvas canvas, Offset center, double radius,
      double bearing, Color color, double lengthFactor,
      {String? label}) {
    final angle = (bearing - heading) * math.pi / 180;
    final arrowLength = radius * lengthFactor;

    final tipX = center.dx + arrowLength * math.sin(angle);
    final tipY = center.dy - arrowLength * math.cos(angle);
    final tailX = center.dx - arrowLength * 0.3 * math.sin(angle);
    final tailY = center.dy + arrowLength * 0.3 * math.cos(angle);

    final paint = Paint()
      ..color = color.withOpacity(0.85)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(tailX, tailY), Offset(tipX, tipY), paint);

    final perpAngle = angle + math.pi / 2;
    final arrowPaint = Paint()
      ..color = color.withOpacity(0.85)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(tipX, tipY)
      ..lineTo(
        tipX - 10 * math.cos(perpAngle) - 12 * math.sin(angle),
        tipY - 10 * math.sin(perpAngle) + 12 * math.cos(angle),
      )
      ..lineTo(
        tipX + 10 * math.cos(perpAngle) - 12 * math.sin(angle),
        tipY + 10 * math.sin(perpAngle) + 12 * math.cos(angle),
      )
      ..close();
    canvas.drawPath(path, arrowPaint);

    if (label != null && label.isNotEmpty) {
      final labelOffset = 16.0;
      final lx = tipX + labelOffset * math.sin(angle);
      final ly = tipY - labelOffset * math.cos(angle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final bgRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(lx, ly),
          width: textPainter.width + 6,
          height: textPainter.height + 4,
        ),
        const Radius.circular(3),
      );
      canvas.drawRRect(
        bgRect,
        Paint()..color = CatppuccinMocha.base.withOpacity(0.75),
      );

      textPainter.paint(
        canvas,
        Offset(lx - textPainter.width / 2, ly - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(CompassPainter oldDelegate) {
    return oldDelegate.heading != heading ||
        oldDelegate.destinationBearing != destinationBearing ||
        oldDelegate.waypoints != waypoints;
  }
}
