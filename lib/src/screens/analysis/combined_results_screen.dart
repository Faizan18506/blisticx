import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blisticx/src/models/analysis_models.dart';
import 'package:blisticx/src/providers/groups_provider.dart';
import 'package:blisticx/src/services/comparison_service.dart';

class CombinedResultsScreen extends StatelessWidget {
  final CombinedResult result;

  const CombinedResultsScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('COMBINED ANALYSIS'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Combined Graph View
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: CustomPaint(
                  painter: _CombinedGraphPainter(
                    result: result,
                  ),
                ),
              ),
            ),

            // 2. Legend
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: result.sourceGroups.asMap().entries.map((entry) {
                  final index = entry.key;
                  final group = entry.value;
                  final color = _getColorForIndex(index);
                  
                  return Chip(
                    avatar: CircleAvatar(backgroundColor: color, radius: 6),
                    label: Text(
                      group.groupName,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.white10,
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // 3. Aggregate Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  _ResultTile(
                    label: 'COMBINED GROUP SIZE',
                    value: '${result.groupSize.toStringAsFixed(3)} ${result.unit}',
                    isMain: true,
                  ),
                  const SizedBox(height: 16),
                  
                   _ResultTile(
                    label: 'COMBINED MEAN RADIUS',
                    value: '${result.meanRadius.toStringAsFixed(3)} ${result.unit}',
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.merge_type, color: Colors.blueAccent),
                        const SizedBox(width: 12),
                        Text(
                          '${result.combinedShots.length} SHOTS FROM ${result.sourceGroups.length} GROUPS',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: Colors.white,
                            fontSize: 14
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
             const SizedBox(height: 24),
             
             // 4. Save Button
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 24.0),
               child: ElevatedButton(
                 onPressed: () => _showSaveDialog(context),
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.greenAccent,
                   foregroundColor: Colors.black,
                   padding: const EdgeInsets.symmetric(vertical: 16),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                 ),
                 child: const Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Icon(Icons.save_rounded),
                     SizedBox(width: 8),
                     Text('SAVE AS NEW DATASET', style: TextStyle(fontWeight: FontWeight.bold)),
                   ],
                 )
               ),
             ),
             
             const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showSaveDialog(BuildContext context) {
    final controller = TextEditingController(text: "Combined Group");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Save Combined Dataset"),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter dataset name",
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                 final newGroup = result.toGroupResult(controller.text);
                 Provider.of<GroupsProvider>(context, listen: false).addGroup(newGroup);
                 Navigator.pop(context); // Close dialog
                 Navigator.pop(context); // Go back to history
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Combined dataset saved to history!'))
                 );
              }
            },
            child: const Text("SAVE"),
          ),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final String label;
  final String value;
  final bool isMain;

  const _ResultTile({
    required this.label,
    required this.value,
    this.isMain = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMain ? Colors.blueAccent : Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
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
              fontSize: isMain ? 28 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _CombinedGraphPainter extends CustomPainter {
  final CombinedResult result;

  _CombinedGraphPainter({required this.result});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // 1. Draw Grid (1-inch grid lines)
    final paintGrid = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1;
      
    // Determine scale: We want the group to fit with some padding
    // Let's say the viewport is roughly 1.5x the group size
    double maxDim = max(result.width, result.height);
    if (maxDim == 0) maxDim = 1.0; // Avoid division by zero
    
    // Pixels per Unit (e.g., px per Inch)
    // We map `maxDim` units to `size.width * 0.8` pixels
    final double scale = (size.width * 0.8) / maxDim;
    
    // Draw Center Crosshair (POA)
    final paintAxis = Paint()..color = Colors.white24..strokeWidth = 1;
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), paintAxis);
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), paintAxis);
    
    // 2. Plot Shots
    for (int i = 0; i < result.sourceGroups.length; i++) {
        final group = result.sourceGroups[i];
        final color = _getColorForIndex(i);
        final paintShot = Paint()..color = color..style = PaintingStyle.fill;
        
        for (var shot in group.normalizedShots) {
           // shot.dx is in INCHES (or CM) relative to center
           // We need to convert it to screen pixels
           final dx = shot.dx * scale; 
           final dy = shot.dy * scale; // In math, Y is up, but screens are down.
           // Since our normalized dy was calculated as (poa.dy - shot.dy), positive MEANS UP.
           // On canvas, UP is negative relative to center if we want cartesian feel, 
           // BUT wait: normalized Y was (POA.y - shot.y).
           // If shot is ABOVE POA (smaller pixel y), result is Positive.
           // On this graph, we want Positive Y to be UP (Top half).
           // Screen Y = Center - (shot.dy * scale)
           
           final screenX = center.dx + dx;
           final screenY = center.dy - dy;
           
           canvas.drawCircle(Offset(screenX, screenY), 4.0, paintShot);
        }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

Color _getColorForIndex(int index) {
  const colors = [
    Colors.redAccent,
    Colors.greenAccent,
    Colors.blueAccent,
    Colors.orangeAccent,
    Colors.purpleAccent,
    Colors.cyanAccent,
    Colors.pinkAccent,
    Colors.tealAccent,
    Colors.amberAccent,
    Colors.indigoAccent,
  ];
  return colors[index % colors.length];
}
