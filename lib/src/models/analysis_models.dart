import 'package:flutter/material.dart';

enum DigitizerMode { shots, reference, aiming }

class Shot {
  final Offset position; // Position in pixels on the image
  final DateTime timestamp;

  Shot({
    required this.position,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'dx': position.dx,
        'dy': position.dy,
        'timestamp': timestamp.toIso8601String(),
      };

  factory Shot.fromJson(Map<String, dynamic> json) => Shot(
        position: Offset(json['dx'], json['dy']),
        timestamp: DateTime.parse(json['timestamp']),
      );
}

class AnalysisSession {
  final String imagePath;
  final List<Shot> shots;
  Offset? aimingPoint;
  Offset? refStart;
  Offset? refEnd;
  double knownRefLength; // e.g. 1.0 inch
  double distance; // distance to target
  String unit; // "INCH" or "CM"
  String caliber;

  AnalysisSession({
    required this.imagePath,
    List<Shot>? shots,
    this.aimingPoint,
    this.refStart,
    this.refEnd,
    this.knownRefLength = 1.0,
    this.distance = 100.0,
    this.unit = "INCH",
    this.caliber = ".260 / 6.5mm",
  }) : shots = shots ?? [];
}

class GroupResult {
  final String id;
  final String imagePath;
  final double groupSize; // Max spread
  final double width;
  final double height;
  final double meanRadius;
  final double radialSD; // Radial Standard Deviation
  final double elevation; // Offset from POA (Y)
  final double windage; // Offset from POA (X)
  final int shotCount;
  final String unit;
  final String caliber;
  final List<Offset> normalizedShots; // Coordinates relative to POA in units
  final DateTime timestamp;

  GroupResult({
    required this.id,
    required this.imagePath,
    required this.groupSize,
    required this.width,
    required this.height,
    required this.meanRadius,
    required this.radialSD,
    required this.elevation,
    required this.windage,
    required this.shotCount,
    required this.unit,
    required this.caliber,
    required this.normalizedShots,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imagePath': imagePath,
      'groupSize': groupSize,
      'width': width,
      'height': height,
      'meanRadius': meanRadius,
      'radialSD': radialSD,
      'elevation': elevation,
      'windage': windage,
      'shotCount': shotCount,
      'unit': unit,
      'caliber': caliber,
      'shots_dx': normalizedShots.map((s) => s.dx).toList(),
      'shots_dy': normalizedShots.map((s) => s.dy).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory GroupResult.fromMap(Map<dynamic, dynamic> map) {
    List<double> dx = List<double>.from(map['shots_dx']);
    List<double> dy = List<double>.from(map['shots_dy']);
    List<Offset> shots = [];
    for (int i = 0; i < dx.length; i++) {
      shots.add(Offset(dx[i], dy[i]));
    }

    return GroupResult(
      id: map['id'],
      imagePath: map['imagePath'],
      groupSize: map['groupSize'],
      width: map['width'],
      height: map['height'],
      meanRadius: map['meanRadius'],
      radialSD: map['radialSD'],
      elevation: map['elevation'],
      windage: map['windage'],
      shotCount: map['shotCount'],
      unit: map['unit'],
      caliber: map['caliber'],
      normalizedShots: shots,
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}


