import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isImperial = true; // Inch vs Cm
  
  // Overlay Options
  bool _showGroupSize = true;
  bool _showGroupWH = true;
  bool _showAtz = true;
  bool _showElevation = true;
  bool _showWindage = true;
  
  // Appearance
  bool _isOverlayLarge = false; // Smaller vs Larger
  bool _isOverlayDark = false; // Light vs Dark (Note: this is overlay style, not app theme)

  String _selectedCaliber = ".260 / 6.5mm";

  // Getters
  bool get isImperial => _isImperial;
  bool get showGroupSize => _showGroupSize;
  bool get showGroupWH => _showGroupWH;
  bool get showAtz => _showAtz;
  bool get showElevation => _showElevation;
  bool get showWindage => _showWindage;
  bool get isOverlayLarge => _isOverlayLarge;
  bool get isOverlayDark => _isOverlayDark;
  String get selectedCaliber => _selectedCaliber;

  // Setters
  void setCaliber(String caliber) {
    _selectedCaliber = caliber;
    notifyListeners();
  }

  void setUnitSystem(bool isImperial) {
    _isImperial = isImperial;
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
