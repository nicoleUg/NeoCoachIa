import 'package:flutter/material.dart';

class NeoCoachLogoPainter extends CustomPainter {
  final Color color;

  NeoCoachLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final scaleX = size.width / 100.0;
    final scaleY = size.height / 100.0;

    // Dibujar la "N" estilizada
    path.moveTo(20 * scaleX, 30 * scaleY);
    path.lineTo(40 * scaleX, 30 * scaleY);
    path.lineTo(50 * scaleX, 45 * scaleY);
    path.lineTo(60 * scaleX, 30 * scaleY);
    path.lineTo(80 * scaleX, 30 * scaleY);
    path.lineTo(80 * scaleX, 70 * scaleY);
    path.lineTo(65 * scaleX, 70 * scaleY);
    path.lineTo(65 * scaleX, 50 * scaleY);
    path.lineTo(50 * scaleX, 65 * scaleY);
    path.lineTo(35 * scaleX, 50 * scaleY);
    path.lineTo(35 * scaleX, 70 * scaleY);
    path.lineTo(20 * scaleX, 70 * scaleY);
    path.close();

    // Dibujar el círculo inferior (cx=50, cy=85, r=5)
    final dotRadius = 5.0 * scaleX;
    path.addOval(Rect.fromCircle(
      center: Offset(50 * scaleX, 85 * scaleY),
      radius: dotRadius,
    ));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class NeoCoachLogo extends StatelessWidget {
  final double size;
  final Color color;

  const NeoCoachLogo({
    Key? key,
    this.size = 32.0,
    this.color = const Color(0xFFC3F400),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: NeoCoachLogoPainter(color: color),
    );
  }
}
