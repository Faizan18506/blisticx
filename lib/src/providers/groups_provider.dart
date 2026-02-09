import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:blisticx/src/models/analysis_models.dart';

class GroupsProvider with ChangeNotifier {
  List<GroupResult> _groups = [];
  final Box _box = Hive.box('groups_box');

  List<GroupResult> get groups => _groups;

  void loadGroups() {
    print("--- [HIVE DATA LOAD] ---");
    final data = _box.values;
    _groups = data.map((e) => GroupResult.fromMap(Map<dynamic, dynamic>.from(e))).toList();
    _groups.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Latest first
    print(" - Total groups loaded from storage: ${_groups.length}");
    notifyListeners();
  }

  Future<void> addGroup(GroupResult result) async {
    print("--- [HIVE DATA SAVE] ---");
    await _box.put(result.id, result.toMap());
    _groups.insert(0, result);
    print(" - Group ${result.id} saved successfully.");
    notifyListeners();
  }

  Future<void> deleteGroup(String id) async {
    await _box.delete(id);
    _groups.removeWhere((g) => g.id == id);
    notifyListeners();
  }

  Future<void> renameGroup(String id, String newName) async {
    final index = _groups.indexWhere((g) => g.id == id);
    if (index != -1) {
      final updatedGroup = GroupResult(
        id: _groups[index].id,
        imagePath: _groups[index].imagePath,
        groupSize: _groups[index].groupSize,
        width: _groups[index].width,
        height: _groups[index].height,
        meanRadius: _groups[index].meanRadius,
        radialSD: _groups[index].radialSD,
        elevation: _groups[index].elevation,
        windage: _groups[index].windage,
        shotCount: _groups[index].shotCount,
        unit: _groups[index].unit,
        caliber: _groups[index].caliber,
        normalizedShots: _groups[index].normalizedShots,
        rawShots: _groups[index].rawShots,
        aimingPoint: _groups[index].aimingPoint,
        imageWidth: _groups[index].imageWidth,
        imageHeight: _groups[index].imageHeight,
        timestamp: _groups[index].timestamp,
        groupName: newName,
      );
      
      _groups[index] = updatedGroup;
      await _box.put(id, updatedGroup.toMap());
      notifyListeners();
    }
  }

  
  Future<void> clearAll() async {
    await _box.clear();
    _groups.clear();
    notifyListeners();
  }
}
