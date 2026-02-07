import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blisticx/src/providers/groups_provider.dart';
import 'package:blisticx/src/screens/analysis/results_summary_screen.dart';
import 'package:blisticx/src/screens/analysis/comparison_screen.dart';
import 'package:blisticx/src/models/analysis_models.dart';
import 'package:blisticx/src/services/comparison_service.dart';

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
        if (_selectedIds.length < 2) {
          _selectedIds.add(id);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Select only 2 groups to compare'))
          );
        }
      }
    });
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
          if (_isSelectionMode && _selectedIds.length == 2)
            TextButton(
              onPressed: () {
                final selectedGroups = groups.where((g) => _selectedIds.contains(g.id)).toList();
                final compResult = ComparisonService.compare(selectedGroups[0], selectedGroups[1]);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => ComparisonScreen(result: compResult))
                );
              },
              child: const Text('COMPARE', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            ),
          if (!_isSelectionMode && groups.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
              onPressed: () => _confirmClearAll(context, groupsProvider),
            )
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
                            '${group.shotCount} Shots - ${group.caliber}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
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
                                  builder: (context) => ResultsSummaryScreen(result: group),
                                ),
                              );
                            }
                          },
                          onLongPress: () {
                            if (!_isSelectionMode) {
                              setState(() {
                                _isSelectionMode = true;
                                _selectedIds.add(group.id);
                              });
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
