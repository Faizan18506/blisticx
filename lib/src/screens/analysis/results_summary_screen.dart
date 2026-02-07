import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blisticx/src/models/analysis_models.dart';
import 'package:blisticx/src/providers/groups_provider.dart';
import 'package:blisticx/src/services/coordinate_converter.dart';

class ResultsSummaryScreen extends StatelessWidget {

  final GroupResult result;

  const ResultsSummaryScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isInch = result.unit == "INCH";

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('ANALYSIS RESULTS'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Target Image Preview with Overlay (Simulated)
            AspectRatio(
              aspectRatio: result.imageWidth > 0 && result.imageHeight > 0 
                ? result.imageWidth / result.imageHeight 
                : 1,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.file(
                        File(result.imagePath),
                        fit: BoxFit.contain,
                      ),
                    ),
                    // Draw Shots and Aiming Point
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return CustomPaint(
                          size: Size(constraints.maxWidth, constraints.maxHeight),
                          painter: _OverlayPainter(
                            shots: result.rawShots,
                            aimingPoint: result.aimingPoint,
                            imageWidth: result.imageWidth,
                            imageHeight: result.imageHeight,
                            caliber: result.caliber,
                          ),
                        );
                      },
                    ),

                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        color: Colors.black54,
                        child: Text(
                          '${result.shotCount} SHOT GROUP',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),



            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  _ResultTile(
                    label: 'GROUP SIZE',
                    value: '${result.groupSize.toStringAsFixed(3)} ${result.unit}',
                    isMain: true,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ResultTile(
                          label: 'WIDTH',
                          value: '${result.width.toStringAsFixed(3)} ${result.unit}',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ResultTile(
                          label: 'HEIGHT',
                          value: '${result.height.toStringAsFixed(3)} ${result.unit}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ResultTile(
                          label: 'WINDAGE',
                          value: '${result.windage.toStringAsFixed(3)} ${result.unit}',
                          subLabel: result.windage > 0 ? 'RIGHT' : 'LEFT',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ResultTile(
                          label: 'ELEVATION',
                          value: '${result.elevation.toStringAsFixed(3)} ${result.unit}',
                          subLabel: result.elevation > 0 ? 'HIGH' : 'LOW',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ResultTile(
                          label: 'MEAN RADIUS',
                          value: '${result.meanRadius.toStringAsFixed(3)} ${result.unit}',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ResultTile(
                          label: 'RADIAL SD',
                          value: '${result.radialSD.toStringAsFixed(3)} ${result.unit}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Ammo Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.adjust, color: Colors.blueAccent),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('CALIBER', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                            Text(result.caliber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      // Save to Hive via Provider
                      Provider.of<GroupsProvider>(context, listen: false).addGroup(result);
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('FINISH & SAVE'),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final String label;
  final String value;
  final String? subLabel;
  final bool isMain;

  const _ResultTile({
    required this.label,
    required this.value,
    this.subLabel,
    this.isMain = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMain ? Colors.blueAccent : Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: isMain ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isMain ? Colors.white70 : Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isMain ? 28 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subLabel != null) ...[
             const SizedBox(height: 2),
             Text(
               subLabel!,
               style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
             ),
          ]
        ],
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final List<Offset> shots;
  final Offset? aimingPoint;
  final double imageWidth;
  final double imageHeight;
  final String caliber;

  _OverlayPainter({
    required this.shots,
    this.aimingPoint,
    required this.imageWidth,
    required this.imageHeight,
    required this.caliber,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageWidth == 0 || imageHeight == 0) return;

    // Calculate BoxFit.contain scale and offsets
    final double scale = min(size.width / imageWidth, size.height / imageHeight);
    final double sw = imageWidth * scale;
    final double sh = imageHeight * scale;
    final double dx = (size.width - sw) / 2;
    final double dy = (size.height - sh) / 2;


    final shotPaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final aimingPaint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Helper to map original pixel to screen pixel
    Offset mapToScreen(Offset original) {
      return Offset(
        original.dx * scale + dx,
        original.dy * scale + dy,
      );
    }

    // Calculate caliber based size
    final double caliberValue = CoordinateConverter.parseCaliber(caliber);
    // Since we don't store pixelsPerUnit directly in Result, we derive it from normalized vs raw
    // Or just use the original imageWidth and a realistic ratio.
    // A better way: Marker size in pixels on original image = caliber * pixelsPerUnit.
    // We already have this in ResultsSummaryScreen as result.caliber anyway.

    // Draw Shots
    for (var shot in shots) {
      final screenPos = mapToScreen(shot);
      
      // Let's use a smart size that looks like a bullet hole but scales
      double markerSize = (size.width * 0.02).clamp(4.0, 15.0);
      
      canvas.drawCircle(screenPos, markerSize, shotPaint);
      canvas.drawCircle(screenPos, 1.0, shotPaint); // Center dot
    }


    // Draw Aiming Point (Reticle style)
    if (aimingPoint != null) {
      final screenPos = mapToScreen(aimingPoint!);
      double aimSize = (size.width * 0.05).clamp(10.0, 30.0);
      
      canvas.drawCircle(screenPos, aimSize, aimingPaint);
      canvas.drawLine(
        Offset(screenPos.dx - aimSize * 1.2, screenPos.dy),
        Offset(screenPos.dx + aimSize * 1.2, screenPos.dy),
        aimingPaint,
      );
      canvas.drawLine(
        Offset(screenPos.dx, screenPos.dy - aimSize * 1.2),
        Offset(screenPos.dx, screenPos.dy + aimSize * 1.2),
        aimingPaint,
      );
    }

  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

