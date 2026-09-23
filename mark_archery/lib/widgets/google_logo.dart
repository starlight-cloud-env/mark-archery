import 'package:flutter/material.dart';

/// Google's multi-color "G" mark, drawn to spec rather than bundled as an
/// image asset. Used to identify the "Continue with Google" button, the way
/// [Icons.apple] identifies the Apple one.
class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.22;
    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Four arcs forming the ring, each a quadrant-ish sweep in Google's
    // brand colors, matching the classic "G" ring composition.
    canvas.drawArc(rect, _deg(-40), _deg(100), false, paint..color = _blue);
    canvas.drawArc(rect, _deg(60), _deg(90), false, paint..color = _green);
    canvas.drawArc(rect, _deg(150), _deg(80), false, paint..color = _yellow);
    canvas.drawArc(rect, _deg(230), _deg(110), false, paint..color = _red);

    // The horizontal bar of the "G", in blue, reaching from the ring's
    // right-middle in to the center.
    final barPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt
      ..color = _blue;
    canvas.drawLine(
      Offset(center.dx + strokeWidth * 0.1, center.dy),
      Offset(center.dx + radius - strokeWidth * 0.1, center.dy),
      barPaint,
    );
  }

  double _deg(double degrees) => degrees * 3.1415926535 / 180;

  @override
  bool shouldRepaint(covariant _GoogleLogoPainter oldDelegate) => false;
}
