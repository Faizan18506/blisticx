import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blisticx/src/models/analysis_models.dart';
import 'package:blisticx/src/providers/groups_provider.dart';

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
              aspectRatio: 1,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                  image: DecorationImage(
                    image: FileImage(File(result.imagePath)),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Container(color: Colors.black38),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.analytics_outlined, color: Colors.blueAccent, size: 48),
                          Text(
                            '${result.shotCount} SHOT GROUP',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
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
