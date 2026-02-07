import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:blisticx/src/models/analysis_models.dart';

class CoordinateConverter {
  static const _uuid = Uuid();

  static GroupResult analyze(AnalysisSession session) {
    print("--- [BALLISTIC CALCULATION START] ---");
    
    if (session.refStart == null || session.refEnd == null) {
      throw Exception("Reference points not set");
    }

    // 1. Calculate Pixels-per-Unit
    final double pixelDistance = (session.refEnd! - session.refStart!).distance;
    final double pixelsPerUnit = pixelDistance / session.knownRefLength;
    
    print("Step 1: Scaling");
    print(" - Pixel Distance of Ref Line: ${pixelDistance.toStringAsFixed(2)} px");
    print(" - Known Ref length: ${session.knownRefLength} ${session.unit}");
    print(" - Scale Factor (Pixels per Unit): ${pixelsPerUnit.toStringAsFixed(4)} px/${session.unit}");

    if (pixelsPerUnit == 0) throw Exception("Invalid reference length");

    // 2. Normalize shots relative to POA
    final Offset poa = session.aimingPoint ?? Offset.zero;
    print("Step 2: Normalization");
    print(" - Point of Aim (POA) in Pixels: (${poa.dx.toStringAsFixed(1)}, ${poa.dy.toStringAsFixed(1)})");
    
    List<Offset> normalizedShots = session.shots.map((shot) {
      // Logic: (ShotX - POA_X) / Scale = X offset in Units
      // (POA_Y - ShotY) / Scale = Y offset in Units (Inverted because Y decreases going up in ballistics)
      double dx = (shot.position.dx - poa.dx) / pixelsPerUnit;
      double dy = (poa.dy - shot.position.dy) / pixelsPerUnit; 
      return Offset(dx, dy);
    }).toList();

    if (normalizedShots.isEmpty) {
      print(" - Error: No shots marked.");
      return GroupResult(
        id: _uuid.v4(),
        imagePath: session.imagePath,
        groupSize: 0,
        width: 0,
        height: 0,
        meanRadius: 0,
        radialSD: 0,
        elevation: 0,
        windage: 0,
        shotCount: 0,
        unit: session.unit,
        caliber: session.caliber,
        normalizedShots: [],
        timestamp: DateTime.now(),
      );
    }

    // 3. Calculate Stats
    print("Step 3: Calculating Statistics");
    
    double minX = normalizedShots.map((s) => s.dx).reduce(min);
    double maxX = normalizedShots.map((s) => s.dx).reduce(max);
    double minY = normalizedShots.map((s) => s.dy).reduce(min);
    double maxY = normalizedShots.map((s) => s.dy).reduce(max);

    double width = maxX - minX;
    double height = maxY - minY;
    print(" - Group Bounding Box: ${width.toStringAsFixed(4)} x ${height.toStringAsFixed(4)} ${session.unit}");

    // Group Size (Max Spread - furthest two points)
    double maxSpread = 0;
    for (int i = 0; i < normalizedShots.length; i++) {
      for (int j = i + 1; j < normalizedShots.length; j++) {
        double d = (normalizedShots[i] - normalizedShots[j]).distance;
        if (d > maxSpread) maxSpread = d;
      }
    }
    print(" - Group Size (Max Spread): ${maxSpread.toStringAsFixed(4)} ${session.unit}");

    // Mean RADIUS and MPI (Mean Point of Impact)
    double centerX = normalizedShots.map((s) => s.dx).reduce((a, b) => a + b) / normalizedShots.length;
    double centerY = normalizedShots.map((s) => s.dy).reduce((a, b) => a + b) / normalizedShots.length;
    Offset groupCenter = Offset(centerX, centerY);
    
    print(" - Mean Point of Impact (MPI): X: ${centerX.toStringAsFixed(4)}, Y: ${centerY.toStringAsFixed(4)}");

    List<double> individualRadii = normalizedShots.map((s) => (s - groupCenter).distance).toList();
    double totalRadius = individualRadii.reduce((a, b) => a + b);
    double meanRadius = totalRadius / normalizedShots.length;
    print(" - Mean Radius: ${meanRadius.toStringAsFixed(4)} ${session.unit}");

    // Radial Standard Deviation (This matches the "Radial SD" in the client's Excel)
    // Formula: sqrt( sum((radius - meanRadius)^2) / (count - 1) )
    double sumSquaredDiff = individualRadii.map((r) => pow(r - meanRadius, 2)).reduce((a, b) => double.parse(a.toString()) + double.parse(b.toString())).toDouble();
    double radialSD = sqrt(sumSquaredDiff / (normalizedShots.length > 1 ? normalizedShots.length - 1 : 1));
    print(" - Radial Standard Deviation: ${radialSD.toStringAsFixed(4)} (Matches Excel Standard)");

    // Offsets from POA (Calculated from MPI)
    double windage = centerX;
    double elevation = centerY;
    print(" - Windage Offset (X): ${windage.toStringAsFixed(4)}");
    print(" - Elevation Offset (Y): ${elevation.toStringAsFixed(4)}");

    print("--- [BALLISTIC CALCULATION END] ---");

    return GroupResult(
      id: _uuid.v4(),
      imagePath: session.imagePath,
      groupSize: maxSpread,
      width: width,
      height: height,
      meanRadius: meanRadius,
      radialSD: radialSD,
      elevation: elevation,
      windage: windage,
      shotCount: normalizedShots.length,
      unit: session.unit,
      caliber: session.caliber,
      normalizedShots: normalizedShots,
      timestamp: DateTime.now(),
    );
  }
}
