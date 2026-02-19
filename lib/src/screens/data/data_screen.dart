import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blisticx/src/providers/groups_provider.dart';
import 'package:blisticx/src/screens/analysis/results_summary_screen.dart';
import 'package:blisticx/src/screens/analysis/comparison_screen.dart';
import 'package:blisticx/src/models/analysis_models.dart';
import 'package:blisticx/src/services/comparison_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'package:blisticx/src/screens/analysis/combined_results_screen.dart';

import 'package:blisticx/src/providers/settings_provider.dart';

import 'package:file_picker/file_picker.dart';

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        if (_selectedIds.length < 10) {
          _selectedIds.add(id);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Limit reached: Select up to 10 groups'))
          );
        }
      }
    });
  }

  double _convert(GroupResult group, double value, String targetUnit) {
    if (group.unit == targetUnit) return value;
    final double dist = group.distance;
    final bool isFromInch = group.unit == "INCH";

    if (targetUnit == "INCH") return isFromInch ? value : value / 2.54;
    if (targetUnit == "CM") return isFromInch ? value * 2.54 : value;
    if (targetUnit == "MOA") {
      return isFromInch ? value / ((dist / 100.0) * 1.047) : value / (dist * 2.9089);
    } 
    if (targetUnit == "MIL") {
      return isFromInch ? value / ((dist / 100.0) * 3.6) : (value * 10.0) / dist;
    }
    return value;
  }

  Future<void> _exportToCSV(List<GroupResult> groups) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final gUnit = settings.groupSizeUnit;
    final aUnit = settings.atzUnit;

    try {
      StringBuffer csv = StringBuffer();
      // Updated Header for Summary and Detailed Shot Data
      csv.writeln("RecordType,Date,GroupName,Shot#,ShotX($gUnit),ShotY($gUnit),Caliber,ShotCount,GroupSize($gUnit),MeanRadius($gUnit),Width($gUnit),Height($gUnit),Windage($aUnit),Elevation($aUnit),DistValue,DistUnit");

      for (var group in groups) {
        String date = group.timestamp.toIso8601String().split('T')[0];
        
        double size = _convert(group, group.groupSize, gUnit);
        double radius = _convert(group, group.meanRadius, gUnit);
        double w = _convert(group, group.width, gUnit);
        double h = _convert(group, group.height, gUnit);
        double wind = _convert(group, group.windage, aUnit);
        double elev = _convert(group, group.elevation, aUnit);

        // 1. Write the Summary Row for this group (Empty strings for ShotX/ShotY)
        
        csv.writeln("SUMMARY,${date},\"${group.groupName}\",ALL,,,${group.caliber},${group.shotCount},${size.toStringAsFixed(3)},${radius.toStringAsFixed(3)},${w.toStringAsFixed(3)},${h.toStringAsFixed(3)},${wind.toStringAsFixed(3)},${elev.toStringAsFixed(3)},${group.distance},${group.distanceUnit}");

        // 2. Write individual shot rows (Empty strings for Group Stats)
        for (int i = 0; i < group.normalizedShots.length; i++) {
          final shot = group.normalizedShots[i];
          // Convert X and Y coordinates to the preferred display units
          double shotX = _convert(group, shot.dx, gUnit);
          double shotY = _convert(group, shot.dy, gUnit);
          
          csv.writeln("SHOT,${date},\"${group.groupName}\",${i + 1},${shotX.toStringAsFixed(4)},${shotY.toStringAsFixed(4)},${group.caliber},1,,,,,,,${group.distance},${group.distanceUnit}");
        }
        
        // Add an empty line between groups for better readability
        csv.writeln("");
      }

      final fileName = "BulletPros_Export_${DateTime.now().millisecondsSinceEpoch}.csv";
      
      // Use FilePicker to allow the user to save it directly to a folder
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save CSV Export',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: Uint8List.fromList(csv.toString().codeUnits),
      );

      if (outputFile != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved: ${outputFile.split('/').last}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("Error during CSV Export: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsProvider = Provider.of<GroupsProvider>(context);
    final groups = groupsProvider.groups;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(_isSelectionMode ? '${_selectedIds.length} SELECTED' : 'HISTORY', 
          style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: _isSelectionMode 
          ? IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _isSelectionMode = false;
                _selectedIds.clear();
              }),
            )
          : null,
        actions: [
          if (!_isSelectionMode && groups.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.file_download_outlined, color: Colors.blueAccent),
              onPressed: () => _exportToCSV(groups),
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
              onPressed: () => _confirmClearAll(context, groupsProvider),
            ),
          ],
          if (_isSelectionMode && _selectedIds.length >= 2) ...[
             if (_selectedIds.length == 2)
               TextButton(
                 onPressed: () {
                   final selectedGroups = groups.where((g) => _selectedIds.contains(g.id)).toList();
                   final compResult = ComparisonService.compare(selectedGroups[0], selectedGroups[1]);
                   Navigator.of(context).push(
                     MaterialPageRoute(builder: (context) => ComparisonScreen(result: compResult))
                   ).then((_) => setState(() {
                      _isSelectionMode = false;
                      _selectedIds.clear();
                   }));
                 },
                 child: const Text('COMPARE', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
               ),
             TextButton(
               onPressed: () {
                 final selectedGroups = groups.where((g) => _selectedIds.contains(g.id)).toList();
                 try {
                    final combinedResult = ComparisonService.combine(selectedGroups);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => CombinedResultsScreen(result: combinedResult))
                    ).then((_) => setState(() {
                       _isSelectionMode = false;
                       _selectedIds.clear();
                    }));
                 } catch (e) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text('Error combining groups: $e'))
                   );
                 }
               },
               child: const Text('COMBINE', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
             ),
          ],
        ],
      ),

      body: groups.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_open_rounded, size: 80, color: Colors.white10),
                  const SizedBox(height: 16),
                  Text(
                    'No saved groups yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white24),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                if (!_isSelectionMode)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    color: Colors.blueAccent.withOpacity(0.1),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blueAccent, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Long press a card to select and compare',
                          style: TextStyle(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      final isSelected = _selectedIds.contains(group.id);

                      return Card(
                        color: isSelected ? Colors.blueAccent.withOpacity(0.1) : Colors.grey[900],
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected ? Colors.blueAccent : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Stack(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: FileImage(File(group.imagePath)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Icon(Icons.check_circle, color: Colors.blueAccent, size: 20),
                                ),
                            ],
                          ),
                          title: Text(
                            group.groupName,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                '${group.shotCount} Shots - ${group.caliber}',
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              Text(
                                'Size: ${group.groupSize.toStringAsFixed(3)} ${group.unit}',
                                style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _formatDate(group.timestamp),
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                          trailing: _isSelectionMode 
                            ? null 
                            : const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
                          onTap: () {
                            if (_isSelectionMode) {
                              _toggleSelection(group.id);
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ResultsSummaryScreen(
                                    result: group,
                                    isHistory: true,
                                  ),
                                ),
                              );
                            }
                          },
                          onLongPress: () {
                            if (!_isSelectionMode) {
                              _showGroupOptions(context, groupsProvider, group);
                            } else {
                              _confirmDelete(context, groupsProvider, group.id);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }


  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  void _showGroupOptions(BuildContext context, GroupsProvider provider, GroupResult group) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: Colors.blueAccent),
              title: const Text('Rename Group', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialogFromList(context, provider, group);
              },
            ),
            ListTile(
              leading: const Icon(Icons.compare_arrows_rounded, color: Colors.orangeAccent),
              title: const Text('Select for Comparison', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _isSelectionMode = true;
                  _selectedIds.add(group.id);
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: const Text('Delete Analysis', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, provider, group.id);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showRenameDialogFromList(BuildContext context, GroupsProvider provider, GroupResult group) {
    final controller = TextEditingController(text: group.groupName);
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.renameGroup(group.id, controller.text);
              }
              Navigator.pop(context);
            },
            child: const Text("SAVE"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, GroupsProvider provider, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Delete Group?', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to remove this analysis?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              provider.deleteGroup(id);
              Navigator.pop(context);
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context, GroupsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Clear All History?', style: TextStyle(color: Colors.white)),
        content: const Text('This will delete all saved analysis. This action cannot be undone.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              provider.clearAll();
              Navigator.pop(context);
            },
            child: const Text('CLEAR ALL', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
