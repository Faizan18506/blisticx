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

  AnalysisSession({
    required this.imagePath,
    List<Shot>? shots,
    this.aimingPoint,
    this.refStart,
    this.refEnd,
    this.knownRefLength = 1.0,
    this.distance = 100.0,
  }) : shots = shots ?? [];
}
