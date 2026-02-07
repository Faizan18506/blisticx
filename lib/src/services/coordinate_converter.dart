import 'dart:math';
import 'package:flutter/material.dart';
import 'package:blisticx/src/models/analysis_models.dart';

class CoordinateConverter {
  static GroupResult analyze(AnalysisSession session) {
    if (session.refStart == null || session.refEnd == null) {
      throw Exception("Reference points not set");
    }

    // 1. Calculate Pixels-per-Unit
    final double pixelDistance = (session.refEnd! - session.refStart!).distance;
    final double pixelsPerUnit = pixelDistance / session.knownRefLength;

    if (pixelsPerUnit == 0) throw Exception("Invalid reference length");

    // 2. Normalize shots relative to POA
    final Offset poa = session.aimingPoint ?? Offset.zero;
    
    // Convert pixels to units and rotate/shift so POA is (0,0)
    // In screen coordinates, Y increases downwards. We usually want Y to increase UPWARDS for ballistics.
    List<Offset> normalizedShots = session.shots.map((shot) {
      double dx = (shot.position.dx - poa.dx) / pixelsPerUnit;
      double dy = (poa.dy - shot.position.dy) / pixelsPerUnit; // Invert Y
      return Offset(dx, dy);
    }).toList();

    if (normalizedShots.isEmpty) {
      return GroupResult(
        imagePath: session.imagePath,
        groupSize: 0,
        width: 0,
        height: 0,
        meanRadius: 0,
        elevation: 0,
        windage: 0,
        shotCount: 0,
        unit: session.unit,
        caliber: session.caliber,
        normalizedShots: [],
      );
    }

    // 3. Calculate Stats
    double minX = normalizedShots.map((s) => s.dx).reduce(min);
    double maxX = normalizedShots.map((s) => s.dx).reduce(max);
    double minY = normalizedShots.map((s) => s.dy).reduce(min);
    double maxY = normalizedShots.map((s) => s.dy).reduce(max);

    double width = maxX - minX;
    double height = maxY - minY;

    // Group Size (Max Spread - furthest two points)
    double maxSpread = 0;
    for (int i = 0; i < normalizedShots.length; i++) {
      for (int j = i + 1; j < normalizedShots.length; j++) {
        double d = (normalizedShots[i] - normalizedShots[j]).distance;
        if (d > maxSpread) maxSpread = d;
      }
    }

    // Mean Radius
    double centerX = normalizedShots.map((s) => s.dx).reduce((a, b) => a + b) / normalizedShots.length;
    double centerY = normalizedShots.map((s) => s.dy).reduce((a, b) => a + b) / normalizedShots.length;
    Offset groupCenter = Offset(centerX, centerY);
    
    double totalRadius = normalizedShots.map((s) => (s - groupCenter).distance).reduce((a, b) => a + b);
    double meanRadius = totalRadius / normalizedShots.length;

    // Offsets from POA (POA is 0,0)
    double windage = centerX;
    double elevation = centerY;

    return GroupResult(
      imagePath: session.imagePath,
      groupSize: maxSpread,
      width: width,
      height: height,
      meanRadius: meanRadius,
      elevation: elevation,
      windage: windage,
      shotCount: normalizedShots.length,
      unit: session.unit,
      caliber: session.caliber,
      normalizedShots: normalizedShots,
    );
  }
}
