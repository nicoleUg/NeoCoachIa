import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  final Pose pose;
  final Size imageSize;
  final InputImageRotation rotation;
  final Color color;
  final bool isFrontCamera;

  PosePainter(
    this.pose,
    this.imageSize,
    this.rotation,
    this.color, {
    this.isFrontCamera = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = color
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final paintDot = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.fill;

    final paintOuterDot = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill;

    // Helper method to translate coordinate space
    Offset translateOffset(PoseLandmark landmark) {
      final double x = translateX(landmark.x, rotation, size, imageSize, isFrontCamera);
      final double y = translateY(landmark.y, rotation, size, imageSize);
      return Offset(x, y);
    }

    void drawLine(PoseLandmarkType type1, PoseLandmarkType type2) {
      final landmark1 = pose.landmarks[type1];
      final landmark2 = pose.landmarks[type2];
      if (landmark1 != null && landmark2 != null && landmark1.likelihood > 0.4 && landmark2.likelihood > 0.4) {
        canvas.drawLine(translateOffset(landmark1), translateOffset(landmark2), paintLine);
      }
    }

    // Dibujar el esqueleto (huesos)
    // Hombros y Caderas (Tronco)
    drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    drawLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
    drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
    drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);

    // Brazo izquierdo
    drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
    drawLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);

    // Brazo derecho
    drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
    drawLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);

    // Pierna izquierda
    drawLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
    drawLine(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle);

    // Pierna derecha
    drawLine(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);
    drawLine(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle);

    // Dibujar los nodos en cada articulación
    for (final landmark in pose.landmarks.values) {
      if (landmark.likelihood > 0.4) {
        final offset = translateOffset(landmark);
        // Dibujar borde externo de color
        canvas.drawCircle(offset, 6.0, paintOuterDot);
        // Dibujar centro blanco
        canvas.drawCircle(offset, 3.0, paintDot);
      }
    }
  }

  double translateX(double x, InputImageRotation rotation, Size size, Size absoluteImageSize, bool isFrontCamera) {
    double val;
    switch (rotation) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        val = x * size.width / absoluteImageSize.height;
        break;
      default:
        val = x * size.width / absoluteImageSize.width;
        break;
    }
    // Para la cámara frontal necesitamos reflejar horizontalmente
    if (isFrontCamera) {
      return size.width - val;
    }
    return val;
  }

  double translateY(double y, InputImageRotation rotation, Size size, Size absoluteImageSize) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        return y * size.height / absoluteImageSize.width;
      default:
        return y * size.height / absoluteImageSize.height;
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.pose != pose || oldDelegate.color != color;
  }
}
