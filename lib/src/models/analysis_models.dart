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
  final List<Offset> rawShots; // Original pixel coordinates
  final Offset? aimingPoint; // Original pixel aiming point
  final double imageWidth;
  final double imageHeight;
  final DateTime timestamp;
  final String groupName;
  final bool isCombined; // New flag

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
    required this.rawShots,
    this.aimingPoint,
    required this.imageWidth,
    required this.imageHeight,
    required this.timestamp,
    required this.groupName,
    this.isCombined = false,
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
      'isCombined': isCombined,
      
      // Serialize lists of doubles for Hive compatibility
      'shots_dx': normalizedShots.map((s) => s.dx).toList(),
      'shots_dy': normalizedShots.map((s) => s.dy).toList(),
      'raw_shots_dx': rawShots.map((s) => s.dx).toList(),
      'raw_shots_dy': rawShots.map((s) => s.dy).toList(),
      
      'aiming_dx': aimingPoint?.dx,
      'aiming_dy': aimingPoint?.dy,
      'imageWidth': imageWidth,
      'imageHeight': imageHeight,
      'timestamp': timestamp.toIso8601String(),
      'groupName': groupName,
    };
  }

  factory GroupResult.fromMap(Map<dynamic, dynamic> map) {
    // Reconstruct normalized shots
    List<dynamic> dxList = map['shots_dx'] ?? [];
    List<dynamic> dyList = map['shots_dy'] ?? [];
    List<Offset> shots = [];
    for (int i = 0; i < dxList.length; i++) {
      if (i < dyList.length) {
         shots.add(Offset((dxList[i] as num).toDouble(), (dyList[i] as num).toDouble()));
      }
    }

    // Reconstruct raw shots
    List<dynamic> rdxList = map['raw_shots_dx'] ?? [];
    List<dynamic> rdyList = map['raw_shots_dy'] ?? [];
    List<Offset> rawShotsList = [];
    for (int i = 0; i < rdxList.length; i++) {
       if (i < rdyList.length) {
         rawShotsList.add(Offset((rdxList[i] as num).toDouble(), (rdyList[i] as num).toDouble()));
       }
    }

    Offset? aiming;
    if (map['aiming_dx'] != null) {
      aiming = Offset((map['aiming_dx'] as num).toDouble(), (map['aiming_dy'] as num).toDouble());
    }

    return GroupResult(
      id: map['id'],
      imagePath: map['imagePath'],
      groupSize: (map['groupSize'] ?? 0).toDouble(),
      width: (map['width'] ?? 0).toDouble(),
      height: (map['height'] ?? 0).toDouble(),
      meanRadius: (map['meanRadius'] ?? 0).toDouble(),
      radialSD: (map['radialSD'] ?? 0).toDouble(),
      elevation: (map['elevation'] ?? 0).toDouble(),
      windage: (map['windage'] ?? 0).toDouble(),
      shotCount: map['shotCount'] ?? 0,
      unit: map['unit'] ?? "INCH",
      caliber: map['caliber'] ?? "Unknown",
      normalizedShots: shots,
      rawShots: rawShotsList,
      aimingPoint: aiming,
      imageWidth: (map['imageWidth'] ?? 0).toDouble(),
      imageHeight: (map['imageHeight'] ?? 0).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      groupName: map['groupName'] ?? "Unnamed Group",
      isCombined: map['isCombined'] ?? false,
    );
  }
}





