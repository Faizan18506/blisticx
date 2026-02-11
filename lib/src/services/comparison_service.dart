import 'dart:math';
import 'dart:ui'; // Required for Offset
import 'package:blisticx/src/models/analysis_models.dart';

class ComparisonResult {
  final GroupResult group1;
  final GroupResult group2;
  final double meanRadiusDiff;
  final double pValue;
  final bool isSignificant;
  final String message;

  ComparisonResult({
    required this.group1,
    required this.group2,
    required this.meanRadiusDiff,
    required this.pValue,
    required this.isSignificant,
    required this.message,
  });
}

class CombinedResult {
  final List<GroupResult> sourceGroups;
  final List<Offset> combinedShots; // Combined normalized shots
  final double groupSize;
  final double meanRadius;
  final double width;
  final double height;
  final double radialSD;
  final double elevation;
  final double windage;
  final String unit;
  final String caliber;

  CombinedResult({
    required this.sourceGroups,
    required this.combinedShots,
    required this.groupSize,
    required this.meanRadius,
    required this.width,
    required this.height,
    required this.radialSD,
    required this.elevation,
    required this.windage,
    required this.unit,
    required this.caliber,
  });

  GroupResult toGroupResult(String name) {
    final first = sourceGroups.first;
    return GroupResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: first.imagePath,
      groupSize: groupSize,
      width: width,
      height: height,
      meanRadius: meanRadius,
      radialSD: radialSD,
      elevation: elevation,
      windage: windage,
      shotCount: combinedShots.length,
      unit: unit,
      caliber: caliber,
      normalizedShots: combinedShots,
      rawShots: [], // Virtual group doesn't have original pixel shots
      aimingPoint: null,
      imageWidth: first.imageWidth,
      imageHeight: first.imageHeight,
      timestamp: DateTime.now(),
      groupName: name,
    );
  }
}

class ComparisonService {
  static CombinedResult combine(List<GroupResult> groups) {
    print("--- [ACCURATE COMBINED ANALYSIS START] ---");
    print("Merging ${groups.length} datasets...");

    List<Offset> allShots = [];
    for (var g in groups) {
      allShots.addAll(g.normalizedShots);
    }

    if (allShots.isEmpty) {
       throw Exception("No shots found in selected groups");
    }

    // 1. Calculate Group Center (MPI - Mean Point of Impact)
    double sumX = allShots.map((s) => s.dx).fold(0, (a, b) => a + b);
    double sumY = allShots.map((s) => s.dy).fold(0, (a, b) => a + b);
    double centerX = sumX / allShots.length;
    double centerY = sumY / allShots.length;
    
    print(" - MPI Calculated: Windage=${centerX.toStringAsFixed(4)}, Elevation=${centerY.toStringAsFixed(4)}");

    // 2. Physical Dimensions
    double minX = allShots.map((s) => s.dx).reduce(min);
    double maxX = allShots.map((s) => s.dx).reduce(max);
    double minY = allShots.map((s) => s.dy).reduce(min);
    double maxY = allShots.map((s) => s.dy).reduce(max);

    double width = maxX - minX;
    double height = maxY - minY;

    // 3. Combined Group Size (Max Spread between any two shots)
    double maxSpread = 0;
    for (int i = 0; i < allShots.length; i++) {
      for (int j = i + 1; j < allShots.length; j++) {
        double d = (allShots[i] - allShots[j]).distance;
        if (d > maxSpread) maxSpread = d;
      }
    }

    // 4. Mean Radius (Distance from EACH shot to the MPI)
    Offset mpi = Offset(centerX, centerY);
    double totalRadius = allShots.map((s) => (s - mpi).distance).fold(0, (a, b) => a + b);
    double meanRadius = totalRadius / allShots.length;

    // 5. Radial Standard Deviation (Consistency)
    double sumSquaredDiff = allShots
        .map((s) => pow((s - mpi).distance - meanRadius, 2))
        .fold(0.0, (prev, element) => prev + element.toDouble());
    
    double radialSD = sqrt(sumSquaredDiff / (allShots.length > 1 ? allShots.length - 1 : 1));

    print(" - Aggregate Stats: Size=$maxSpread, MR=$meanRadius, SD=$radialSD");
    print("--- [ACCURATE COMBINED ANALYSIS END] ---");

    return CombinedResult(
      sourceGroups: groups,
      combinedShots: allShots,
      groupSize: maxSpread,
      meanRadius: meanRadius,
      width: width,
      height: height,
      radialSD: radialSD,
      elevation: centerY,
      windage: centerX,
      unit: groups.first.unit,
      caliber: groups.first.caliber,
    );
  }

  static ComparisonResult compare(GroupResult g1, GroupResult g2) {
    print("--- [STATISTICAL COMPARISON START] ---");
    print("Comparing Group 1 (${g1.groupName}) vs Group 2 (${g2.groupName})");

    // 1. Mean Radius Difference
    // Mean Radius is ALREADY calculated from the group's center in the improved logic
    double diff = (g1.meanRadius - g2.meanRadius).abs();
    print(" - Mean Radius 1 (MPI-based): ${g1.meanRadius.toStringAsFixed(4)}");
    print(" - Mean Radius 2 (MPI-based): ${g2.meanRadius.toStringAsFixed(4)}");
    print(" - Difference: ${diff.toStringAsFixed(4)}");

    // 2. Mann-Whitney U Test
    // We want to compare the "Tightness" (Precision) of the groups.
    // So we use the distance of each shot from its OWN group center (MPI), not the POA (0,0).
    
    final Offset mpi1 = Offset(g1.windage, g1.elevation);
    final Offset mpi2 = Offset(g2.windage, g2.elevation);

    // Calculate distance of each shot from its own group center
    List<double> samples1 = g1.normalizedShots.map((s) => (s - mpi1).distance).toList();
    List<double> samples2 = g2.normalizedShots.map((s) => (s - mpi2).distance).toList();

    print(" - Sample Sizes: n1=${samples1.length}, n2=${samples2.length}");

    double pValue = _calculateMannWhitneyPValue(samples1, samples2);
    bool significant = pValue < 0.05;
    
    print(" - Calculated p-value: ${pValue.toStringAsFixed(4)}");
    print(" - Significant at 95% level? ${significant ? 'YES' : 'NO'}");

    String msg;
    if (significant) {
      final betterGroup = g1.meanRadius < g2.meanRadius ? g1.groupName : g2.groupName;
      final worseGroup = g1.meanRadius < g2.meanRadius ? g2.groupName : g1.groupName;
      // Calculate % improvement
      double improvement = (diff / max(g1.meanRadius, g2.meanRadius)) * 100;
      
      msg = "Significant Difference!\n$betterGroup is ${improvement.toStringAsFixed(1)}% tighter (more precise) than $worseGroup.";
    } else {
      msg = "No significant statistical difference detected between the two groups.";
    }

    print("--- [STATISTICAL COMPARISON END] ---");

    return ComparisonResult(
      group1: g1,
      group2: g2,
      meanRadiusDiff: diff,
      pValue: pValue,
      isSignificant: significant,
      message: msg,
    );
  }

  static double _calculateMannWhitneyPValue(List<double> s1, List<double> s2) {
    int n1 = s1.length;
    int n2 = s2.length;
    
    List<_RankItem> combined = [];
    for (var x in s1) combined.add(_RankItem(x, 1));
    for (var x in s2) combined.add(_RankItem(x, 2));
    
    combined.sort((a, b) => a.value.compareTo(b.value));
    
    List<double> ranks = List.filled(combined.length, 0.0);
    int i = 0;
    while (i < combined.length) {
      int j = i;
      while (j < combined.length - 1 && combined[j+1].value == combined[i].value) {
        j++;
      }
      double averageRank = (i + j + 2) / 2.0; // 1-indexed
      for (int k = i; k <= j; k++) {
        ranks[k] = averageRank;
      }
      i = j + 1;
    }
    
    double rankSum1 = 0;
    for (int k = 0; k < combined.length; k++) {
      if (combined[k].group == 1) {
        rankSum1 += ranks[k];
      }
    }
    
    double u1 = rankSum1 - (n1 * (n1 + 1) / 2.0);
    double u2 = (n1 * n2) - u1;
    double uMin = min(u1, u2);
    
    double meanU = (n1 * n2) / 2.0;
    double sigmaU = sqrt((n1 * n2 * (n1 + n2 + 1)) / 12.0);
    
    // Continuity correction
    double z = (uMin + 0.5 - meanU) / sigmaU;
    
    return _zToPValue(z.abs()) * 2;
  }

  static double _zToPValue(double z) {
    // Normal distribution approximation (Error function)
    const double a1 = 0.254829592;
    const double a2 = -0.284496736;
    const double a3 = 1.421413741;
    const double a4 = -1.453152027;
    const double a5 = 1.061405429;
    const double p = 0.3275911;

    int sign = z < 0 ? -1 : 1;
    z = z.abs() / sqrt(2.0);

    double t = 1.0 / (1.0 + p * z);
    double y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * exp(-z * z);

    return 0.5 * (1.0 - sign * y);
  }
}

class _RankItem {
  final double value;
  final int group;
  _RankItem(this.value, this.group);
}
