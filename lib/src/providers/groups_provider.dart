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
  
  Future<void> clearAll() async {
    await _box.clear();
    _groups.clear();
    notifyListeners();
  }
}
