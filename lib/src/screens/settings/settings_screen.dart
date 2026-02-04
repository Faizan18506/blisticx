import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blisticx/src/providers/settings_provider.dart';
import 'package:blisticx/src/screens/settings/caliber_selector_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Local state to handle Save/Cancel logic
  late bool _isImperial;
  late bool _showGroupSize;
  late bool _showGroupWH;
  late bool _showAtz;
  late bool _showElevation;
  late bool _showWindage;
  late bool _isOverlayLarge;
  late bool _isOverlayDark;
  late String _selectedCaliber;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _isImperial = settings.isImperial;
    _showGroupSize = settings.showGroupSize;
    _showGroupWH = settings.showGroupWH;
    _showAtz = settings.showAtz;
    _showElevation = settings.showElevation;
    _showWindage = settings.showWindage;
    _isOverlayLarge = settings.isOverlayLarge;
    _isOverlayDark = settings.isOverlayDark;
    _selectedCaliber = settings.selectedCaliber;
  }

  void _saveSettings() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    settings.setUnitSystem(_isImperial);
    settings.toggleGroupSize(_showGroupSize);
    settings.toggleGroupWH(_showGroupWH);
    settings.toggleAtz(_showAtz);
    settings.toggleElevation(_showElevation);
    settings.toggleWindage(_showWindage);
    settings.setOverlaySize(_isOverlayLarge);
    settings.setOverlayStyle(_isOverlayDark);
    settings.setCaliber(_selectedCaliber);
    Navigator.of(context).pop();
  }

  void _resetToDefaults() {
    setState(() {
      _isImperial = true;
      _showGroupSize = true;
      _showGroupWH = true;
      _showAtz = true;
      _showElevation = true;
      _showWindage = true;
      _isOverlayLarge = false;
      _isOverlayDark = false;
      _selectedCaliber = ".260 / 6.5mm";
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget sectionTitle(String title) {
      return Padding(
        padding: const EdgeInsets.only(top: 24.0, bottom: 0.0),
        child: Column(
          children: [
            Text(
              title.toUpperCase(),
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Divider(color: Colors.grey[800], thickness: 1),
          ],
        ),
      );
    }

    Widget customToggle({
      required String labelTrue,
      required String labelFalse,
      required VoidCallback onLeftTap,
      required VoidCallback onRightTap,
      required bool isLeftSelected,
    }) {
      return Container(
        height: 48,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onLeftTap,
                child: Container(
                  color: isLeftSelected ? Colors.white : Colors.transparent,
                  alignment: Alignment.center,
                  child: Text(
                    labelFalse.toUpperCase(),
                    style: TextStyle(
                      color: isLeftSelected ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Container(width: 1, color: Colors.white24),
            Expanded(
              child: GestureDetector(
                onTap: onRightTap,
                child: Container(
                  color: !isLeftSelected ? Colors.white : Colors.transparent,
                  alignment: Alignment.center,
                  child: Text(
                    labelTrue.toUpperCase(),
                    style: TextStyle(
                      color: !isLeftSelected ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('OPTIONS', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              sectionTitle('Reference Size Units'),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  _isImperial ? "1.00 INCH" : "1.00 CM",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              customToggle(
                labelFalse: 'Inch',
                labelTrue: 'Cm',
                isLeftSelected: _isImperial,
                onLeftTap: () => setState(() => _isImperial = true),
                onRightTap: () => setState(() => _isImperial = false),
              ),
              sectionTitle('Overlay Display Options'),
              _SwitchRow(
                label: 'Group size',
                value: _showGroupSize,
                onChanged: (val) => setState(() => _showGroupSize = val),
              ),
              _SwitchRow(
                label: 'Group W / H',
                value: _showGroupWH,
                onChanged: (val) => setState(() => _showGroupWH = val),
              ),
              _SwitchRow(
                label: 'ATZ',
                value: _showAtz,
                onChanged: (val) => setState(() => _showAtz = val),
              ),
              _SwitchRow(
                label: 'Elevation',
                value: _showElevation,
                onChanged: (val) => setState(() => _showElevation = val),
              ),
              _SwitchRow(
                label: 'Windage',
                value: _showWindage,
                onChanged: (val) => setState(() => _showWindage = val),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.of(context).push<String>(
                    MaterialPageRoute(
                      builder: (context) => CaliberSelectorScreen(initialCaliber: _selectedCaliber),
                    ),
                  );
                  if (result != null) {
                    setState(() {
                      _selectedCaliber = result;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Set Caliber', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      Row(
                        children: [
                          Text(
                            _selectedCaliber,
                            style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  SizedBox(width: 60, child: Text('Size', style: theme.textTheme.bodyLarge)),
                  Expanded(
                    child: customToggle(
                      labelFalse: 'Smaller',
                      labelTrue: 'Larger',
                      isLeftSelected: !_isOverlayLarge,
                      onLeftTap: () => setState(() => _isOverlayLarge = false),
                      onRightTap: () => setState(() => _isOverlayLarge = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(width: 60, child: Text('Style', style: theme.textTheme.bodyLarge)),
                  Expanded(
                    child: customToggle(
                      labelFalse: 'Light',
                      labelTrue: 'Dark',
                      isLeftSelected: !_isOverlayDark,
                      onLeftTap: () => setState(() => _isOverlayDark = false),
                      onRightTap: () => setState(() => _isOverlayDark = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              
              // New Action Buttons: Reset, Cancel, Save
              // Action Buttons: Default & Save
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _resetToDefaults,
                        child: const Text('DEFAULT'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _saveSettings,
                        child: const Text('SAVE'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blueAccent,
          ),
        ],
      ),
    );
  }
}
