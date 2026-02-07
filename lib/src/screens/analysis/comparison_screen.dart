import 'package:flutter/material.dart';
import 'package:blisticx/src/services/comparison_service.dart';

class ComparisonScreen extends StatelessWidget {
  final ComparisonResult result;

  const ComparisonScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('GROUP COMPARISON', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Side by Side Groups
            Row(
              children: [
                Expanded(child: _GroupMiniCard(groupName: "Group 1", caliber: result.group1.caliber, color: Colors.blueAccent)),
                const SizedBox(width: 16),
                Expanded(child: _GroupMiniCard(groupName: "Group 2", caliber: result.group2.caliber, color: Colors.orangeAccent)),
              ],
            ),
            const SizedBox(height: 32),
            
            // Stats Table
            _DataTable(result: result),
            
            const SizedBox(height: 32),
            
            // Significance Result Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: result.isSignificant ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: result.isSignificant ? Colors.greenAccent : Colors.redAccent,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Icon(
                         result.isSignificant ? Icons.check_circle_outline : Icons.error_outline,
                         color: result.isSignificant ? Colors.greenAccent : Colors.redAccent,
                       ),
                       const SizedBox(width: 8),
                       const Text(
                         'STATISTICAL SIGNIFICANCE',
                         style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1, fontSize: 12),
                       ),
                     ],
                   ),
                   const SizedBox(height: 12),
                   Text(
                     result.message,
                     textAlign: TextAlign.center,
                     style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                   ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white10,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
              ),
              child: const Text('BACK TO HISTORY'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupMiniCard extends StatelessWidget {
  final String groupName;
  final String caliber;
  final Color color;

  const _GroupMiniCard({required this.groupName, required this.caliber, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(groupName, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Text(caliber, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}

class _DataTable extends StatelessWidget {
  final ComparisonResult result;
  const _DataTable({required this.result});

  @override
  Widget build(BuildContext context) {
    final g1 = result.group1;
    final g2 = result.group2;

    return Column(
      children: [
        _DataRow(label: 'Mean Radius', val1: g1.meanRadius, val2: g2.meanRadius, unit: g1.unit),
        _DataRow(label: 'Radial SD', val1: g1.radialSD, val2: g2.radialSD, unit: g1.unit),
        _DataRow(label: 'Offset X (Windage)', val1: g1.windage, val2: g2.windage, unit: g1.unit),
        _DataRow(label: 'Offset Y (Elevation)', val1: g1.elevation, val2: g2.elevation, unit: g1.unit),
        const Divider(color: Colors.white10, height: 32),
        _DataRow(label: 'Difference', val1: result.meanRadiusDiff, isDiff: true, unit: g1.unit),
        _DataRow(label: 'p-value', val1: result.pValue, isPValue: true),
      ],
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final double val1;
  final double? val2;
  final String unit;
  final bool isDiff;
  final bool isPValue;

  const _DataRow({
    required this.label,
    required this.val1,
    this.val2,
    this.unit = "",
    this.isDiff = false,
    this.isPValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))),
          if (!isDiff && !isPValue) ...[
            Expanded(flex: 2, child: Center(child: Text(val1.toStringAsFixed(4), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
            Expanded(flex: 2, child: Center(child: Text(val2!.toStringAsFixed(4), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
          ] else ...[
            Expanded(flex: 4, child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                isPValue ? val1.toStringAsFixed(4) : val1.toStringAsFixed(4) + " " + unit,
                style: TextStyle(
                  color: isPValue ? (val1 < 0.05 ? Colors.greenAccent : Colors.redAccent) : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }
}
