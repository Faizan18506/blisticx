import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:blisticx/src/models/analysis_models.dart';

class CoordinateConverter {
  static const _uuid = Uuid();

  static double parseCaliber(String caliberStr) {
    try {
      // Handle cases like ".260 / 6.5mm" or "9mm" or ".308"
      final RegExp regex = RegExp(r'(\d*\.?\d+)');
      final match = regex.firstMatch(caliberStr);
      if (match != null) {
        String val = match.group(1)!;
        double numVal = double.parse(val);
        
        // If it's a "mm" caliber or a number > 1 (unlikely to be inches)
        if (caliberStr.toLowerCase().contains("mm") || numVal > 1.0) {
           return numVal / 25.4; // Convert MM to Inches for internal scaling
        }
        return numVal; 
      }
    } catch (e) {
      print("Error parsing caliber: $e");
    }
    return 0.264; // Default
  }


  static GroupResult analyze(AnalysisSession session, {required double imageWidth, required double imageHeight}) {
    print("--- [BALLISTIC CALCULATION START] ---");
    
    if (session.refStart == null || session.refEnd == null) {
      throw Exception("Reference points not set");
    }

    // 1. Calculate Pixels-per-Unit
    final double pixelDistance = (session.refEnd! - session.refStart!).distance;
    final double pixelsPerUnit = pixelDistance / session.knownRefLength;
    
    print("Step 1: Scaling");
    print(" - Image Size: ${imageWidth.toInt()} x ${imageHeight.toInt()}");
    print(" - Pixel Distance of Ref Line: ${pixelDistance.toStringAsFixed(2)} px");
    print(" - Known Ref length: ${session.knownRefLength} ${session.unit}");
    print(" - Scale Factor (Pixels per Unit): ${pixelsPerUnit.toStringAsFixed(4)} px/${session.unit}");

    if (pixelsPerUnit == 0) throw Exception("Invalid reference length");

    // 2. Normalize shots relative to POA
    final Offset poa = session.aimingPoint ?? Offset.zero;
    print("Step 2: Normalization");
    print(" - Point of Aim (POA) in Pixels: (${poa.dx.toStringAsFixed(1)}, ${poa.dy.toStringAsFixed(1)})");
    
    print(" - Processing Shots (Pixel Coordinates):");
    for (int i = 0; i < session.shots.length; i++) {
       final s = session.shots[i].position;
       print("    Shot $i: (${s.dx.toStringAsFixed(1)}, ${s.dy.toStringAsFixed(1)})");
    }

    List<Offset> normalizedShots = session.shots.map((shot) {

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
        rawShots: [],
        aimingPoint: session.aimingPoint,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        timestamp: DateTime.now(),
        groupName: "Empty Group",
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
    
    // Group Size (Max Spread)
    double maxSpread = 0;
    for (int i = 0; i < normalizedShots.length; i++) {
      for (int j = i + 1; j < normalizedShots.length; j++) {
        double d = (normalizedShots[i] - normalizedShots[j]).distance;
        if (d > maxSpread) maxSpread = d;
      }
    }

    double centerX = normalizedShots.map((s) => s.dx).reduce((a, b) => a + b) / normalizedShots.length;
    double centerY = normalizedShots.map((s) => s.dy).reduce((a, b) => a + b) / normalizedShots.length;
    Offset groupCenter = Offset(centerX, centerY);
    
    List<double> individualRadii = normalizedShots.map((s) => (s - groupCenter).distance).toList();
    double meanRadius = individualRadii.reduce((a, b) => a + b) / normalizedShots.length;

    // Correct Radial SD calculation (Standard Deviation of radii from center)
    double sumSquaredDiff = 0;
    for (double r in individualRadii) {
      sumSquaredDiff += pow(r - meanRadius, 2);
    }
    
    // Use Sample Standard Deviation (N-1) for more than 1 shot
    double radialSD = normalizedShots.length > 1 
        ? sqrt(sumSquaredDiff / (normalizedShots.length - 1))
        : 0.0;

    print(" - Statistics Info:");
    print("    * Mean Point of Impact (MPI): (${centerX.toStringAsFixed(3)}, ${centerY.toStringAsFixed(3)})");
    print("    * Number of Radii: ${individualRadii.length}");
    print("    * Mean Radius: ${meanRadius.toStringAsFixed(4)}");
    print("    * Radial SD: ${radialSD.toStringAsFixed(4)}");


    print(" - Results: Size=${maxSpread.toStringAsFixed(4)}, MeanRadius=${meanRadius.toStringAsFixed(4)}, RadialSD=${radialSD.toStringAsFixed(4)}");
    print("--- [BALLISTIC CALCULATION END] ---");

    return GroupResult(
      id: _uuid.v4(),
      imagePath: session.imagePath,
      groupSize: maxSpread,
      width: width,
      height: height,
      meanRadius: meanRadius,
      radialSD: radialSD,
      elevation: centerY,
      windage: centerX,
      shotCount: normalizedShots.length,
      unit: session.unit,
      caliber: session.caliber,
      normalizedShots: normalizedShots,
      rawShots: session.shots.map((s) => s.position).toList(),
      aimingPoint: session.aimingPoint,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      timestamp: DateTime.now(),
      groupName: "Group - ${DateTime.now().hour}:${DateTime.now().minute}",
    );

  }
}
