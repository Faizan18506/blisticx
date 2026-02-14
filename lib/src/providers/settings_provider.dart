import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isImperial = true; // Overall base system
  
  // New Global Unit Settings
  String _groupSizeUnit = "INCH"; // INCH, CM, MOA, MIL
  String _atzUnit = "MIL";       // MOA, MIL, INCH, CM
  String _distanceUnit = "YARDS"; // YARDS, METERS
  
  // Overlay Options
  bool _showGroupSize = true;
  bool _showGroupWH = true;
  bool _showAtz = true;
  bool _showElevation = true;
  bool _showWindage = true;
  
  // Appearance
  bool _isOverlayLarge = false; 
  bool _isOverlayDark = false; 

  String _selectedCaliber = ".17 / 4.4mm";

  // Getters
  bool get isImperial => _isImperial;
  String get groupSizeUnit => _groupSizeUnit;
  String get atzUnit => _atzUnit;
  String get distanceUnit => _distanceUnit;
  
  bool get showGroupSize => _showGroupSize;
  bool get showGroupWH => _showGroupWH;
  bool get showAtz => _showAtz;
  bool get showElevation => _showElevation;
  bool get showWindage => _showWindage;
  bool get isOverlayLarge => _isOverlayLarge;
  bool get isOverlayDark => _isOverlayDark;
  String get selectedCaliber => _selectedCaliber;

  // Setters
  void setGroupSizeUnit(String unit) {
    _groupSizeUnit = unit;
    // Auto-sync isImperial for base calcs if user picks INCH or CM
    if (unit == "INCH") _isImperial = true;
    if (unit == "CM") _isImperial = false;
    notifyListeners();
  }

  void setAtzUnit(String unit) {
    _atzUnit = unit;
    notifyListeners();
  }

  void setDistanceUnit(String unit) {
    _distanceUnit = unit;
    notifyListeners();
  }

  void setCaliber(String caliber) {
    _selectedCaliber = caliber;
    notifyListeners();
  }

  void setUnitSystem(bool isImperial) {
    _isImperial = isImperial;
    _groupSizeUnit = isImperial ? "INCH" : "CM";
    _distanceUnit = isImperial ? "YARDS" : "METERS";
    notifyListeners();
  }

  void toggleGroupSize(bool value) {
    _showGroupSize = value;
    notifyListeners();
  }

  void toggleGroupWH(bool value) {
    _showGroupWH = value;
    notifyListeners();
  }

  void toggleAtz(bool value) {
    _showAtz = value;
    notifyListeners();
  }

  void toggleElevation(bool value) {
    _showElevation = value;
    notifyListeners();
  }

  void toggleWindage(bool value) {
    _showWindage = value;
    notifyListeners();
  }

  void setOverlaySize(bool isLarge) {
    _isOverlayLarge = isLarge;
    notifyListeners();
  }

  void setOverlayStyle(bool isDark) {
    _isOverlayDark = isDark;
    notifyListeners();
  }

  void resetToDefaults() {
    _isImperial = true;
    _groupSizeUnit = "INCH";
    _atzUnit = "MIL";
    _distanceUnit = "YARDS";
    _showGroupSize = true;
    _showGroupWH = true;
    _showAtz = true;
    _showElevation = true;
    _showWindage = true;
    _isOverlayLarge = false;
    _isOverlayDark = false;
    notifyListeners();
  }
}
