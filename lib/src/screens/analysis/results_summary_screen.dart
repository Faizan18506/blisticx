import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blisticx/src/models/analysis_models.dart';
import 'package:blisticx/src/providers/groups_provider.dart';
import 'package:blisticx/src/providers/settings_provider.dart';
import 'package:blisticx/src/services/coordinate_converter.dart';

class ResultsSummaryScreen extends StatefulWidget {
  final GroupResult result;
  final bool isHistory;

  const ResultsSummaryScreen({
    super.key, 
    required this.result, 
    this.isHistory = false,
  });

  @override
  State<ResultsSummaryScreen> createState() => _ResultsSummaryScreenState();
}

class _ResultsSummaryScreenState extends State<ResultsSummaryScreen> {
  late String _currentGroupName;

  @override
  void initState() {
    super.initState();
    _currentGroupName = widget.result.groupName;
    print("--- [RESULTS SCREEN INIT] ---");
    print("Base Unit: ${widget.result.unit}");
    print("Distance: ${widget.result.distance} ${widget.result.distanceUnit}");
    print("Is History: ${widget.isHistory}");
  }

  // Robust conversion engine based on client formulas
  double _convert(double value, String targetUnit) {
    if (widget.result.unit == targetUnit) return value;
    
    final double dist = widget.result.distance;
    final bool isFromInch = widget.result.unit == "INCH";

    if (targetUnit == "INCH") return isFromInch ? value : value / 2.54;
    if (targetUnit == "CM") return isFromInch ? value * 2.54 : value;

    if (targetUnit == "MOA") {
      return isFromInch 
        ? value / ((dist / 100.0) * 1.047)
        : value / (dist * 2.9089);
    } 
    
    if (targetUnit == "MIL") {
      return isFromInch
        ? value / ((dist / 100.0) * 3.6)
        : (value * 10.0) / dist;
    }

    return value;
  }

  void _showRenameDialog() {
    final controller = TextEditingController(text: _currentGroupName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Rename Group"),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter group name",
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() => _currentGroupName = controller.text);
              }
              Navigator.pop(context);
            },
            child: const Text("SAVE"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // We use the units saved INSIDE the result to ensure history items 
    // don't change automatically when global settings change.
    final gUnit = widget.result.groupUnit;
    final aUnit = widget.result.atzUnit;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: GestureDetector(
          onTap: _showRenameDialog,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(_currentGroupName)),
              const SizedBox(width: 8),
              const Icon(Icons.edit, size: 18, color: Colors.blueAccent),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Target Image Preview (OR Graph for Combined Groups)
            AspectRatio(
              aspectRatio: widget.result.isCombined || (widget.result.imageWidth > 0 && widget.result.imageHeight > 0)
                ? (widget.result.isCombined ? 1.0 : widget.result.imageWidth / widget.result.imageHeight)
                : 1,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.result.isCombined ? Colors.grey[900] : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                clipBehavior: Clip.antiAlias,
                child: widget.result.isCombined 
                  ? CustomPaint(
                      painter: _SavedGraphPainter(result: widget.result),
                    )
                  : Stack(
                  children: [
                    Positioned.fill(
                      child: Image.file(
                        File(widget.result.imagePath),
                        fit: BoxFit.contain,
                      ),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return CustomPaint(
                          size: Size(constraints.maxWidth, constraints.maxHeight),
                          painter: _OverlayPainter(
                            shots: widget.result.rawShots,
                            aimingPoint: widget.result.aimingPoint,
                            imageWidth: widget.result.imageWidth,
                            imageHeight: widget.result.imageHeight,
                            caliber: widget.result.caliber,
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
                          '${widget.result.shotCount} SHOT GROUP',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                   _ResultTile(
                     label: 'GROUP SIZE',
                     value: '${_convert(widget.result.groupSize, gUnit).toStringAsFixed(3)} $gUnit',
                     isMain: true,
                   ),
                   const SizedBox(height: 16),
                   Row(
                     children: [
                       Expanded(
                         child: _ResultTile(
                           label: 'WIDTH',
                           value: '${_convert(widget.result.width, gUnit).toStringAsFixed(3)} $gUnit',
                         ),
                       ),
                       const SizedBox(width: 16),
                       Expanded(
                         child: _ResultTile(
                           label: 'HEIGHT',
                           value: '${_convert(widget.result.height, gUnit).toStringAsFixed(3)} $gUnit',
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
                           value: '${_convert(widget.result.windage, aUnit).toStringAsFixed(3)} $aUnit',
                           subLabel: widget.result.windage > 0 ? 'RIGHT' : 'LEFT',
                         ),
                       ),
                       const SizedBox(width: 16),
                       Expanded(
                         child: _ResultTile(
                           label: 'ELEVATION',
                           value: '${_convert(widget.result.elevation, aUnit).toStringAsFixed(3)} $aUnit',
                           subLabel: widget.result.elevation > 0 ? 'HIGH' : 'LOW',
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
                           value: '${_convert(widget.result.meanRadius, gUnit).toStringAsFixed(3)} $gUnit',
                         ),
                       ),
                       const SizedBox(width: 16),
                       Expanded(
                         child: _ResultTile(
                           label: 'RADIAL SD',
                           value: '${_convert(widget.result.radialSD, gUnit).toStringAsFixed(3)} $gUnit',
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
                            Text(widget.result.caliber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                  
                  if (!widget.isHistory)
                  ElevatedButton(
                    onPressed: () {
                      // Final result to save (with potentially modified name)
                      final finalResult = GroupResult(
                        id: widget.result.id,
                        imagePath: widget.result.imagePath,
                        groupSize: widget.result.groupSize,
                        width: widget.result.width,
                        height: widget.result.height,
                        meanRadius: widget.result.meanRadius,
                        radialSD: widget.result.radialSD,
                        elevation: widget.result.elevation,
                        windage: widget.result.windage,
                        shotCount: widget.result.shotCount,
                        unit: widget.result.unit,
                        groupUnit: widget.result.groupUnit,
                        atzUnit: widget.result.atzUnit,
                        caliber: widget.result.caliber,
                        normalizedShots: widget.result.normalizedShots,
                        rawShots: widget.result.rawShots,
                        aimingPoint: widget.result.aimingPoint,
                        imageWidth: widget.result.imageWidth,
                        imageHeight: widget.result.imageHeight,
                        timestamp: widget.result.timestamp,
                        groupName: _currentGroupName,
                        distance: widget.result.distance,
                        distanceUnit: widget.result.distanceUnit,
                      );
                      
                      Provider.of<GroupsProvider>(context, listen: false).addGroup(finalResult);
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

class _SavedGraphPainter extends CustomPainter {
  final GroupResult result;

  _SavedGraphPainter({required this.result});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // 1. Draw Grid (1-inch grid lines approximation)
    final paintGrid = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1;

    // Use max dimension for scale
    double maxDim = max(result.width, result.height);
    if (maxDim == 0) maxDim = 1.0; 
    
    // Pixels per Unit (e.g., px per Inch)
    // We want the group to fit in 80% of width
    final double scale = (size.width * 0.8) / maxDim;

    // 2. Draw Center Crosshair (POA)
    final paintAxis = Paint()..color = Colors.white24..strokeWidth = 1;
    // X-Axis
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), paintAxis);
    // Y-Axis
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), paintAxis);

    // 3. Draw Mean Point of Impact (MPI)
    // Normalized Y is UP, Canvas Y is DOWN. 
    // ScreenY = CenterY - (NormalizedY * scale)
    final mpiX = center.dx + (result.windage * scale);
    final mpiY = center.dy - (result.elevation * scale);
    
    // Draw MPI as Yellow Circle
    canvas.drawCircle(Offset(mpiX, mpiY), 6.0, Paint()..color = Colors.yellowAccent..style = PaintingStyle.stroke..strokeWidth=2);
    
    // 4. Plot Shots (Green)
    final paintShot = Paint()..color = Colors.greenAccent..style = PaintingStyle.fill;
    
    for (var shot in result.normalizedShots) {
       final dx = shot.dx * scale; 
       final dy = shot.dy * scale; 
       
       final screenX = center.dx + dx;
       final screenY = center.dy - dy;
       
       canvas.drawCircle(Offset(screenX, screenY), 4.0, paintShot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _UnitTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _UnitTab({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.blueAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.black : Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

