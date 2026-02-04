import 'package:flutter/material.dart';

class CaliberSelectorScreen extends StatefulWidget {
  final String initialCaliber;

  const CaliberSelectorScreen({super.key, required this.initialCaliber});

  @override
  State<CaliberSelectorScreen> createState() => _CaliberSelectorScreenState();
}

class _CaliberSelectorScreenState extends State<CaliberSelectorScreen> {
  final List<String> _calibers = [
    ".17 HMR",
    ".22 LR",
    ".22 / 5.56mm",
    ".223 Rem",
    ".243 / 6mm",
    ".25 / 6.35mm",
    ".260 / 6.5mm",
    ".270 / 7mm",
    ".280 / 7.2mm",
    ".308 / 7.62mm",
    ".338 Lapua",
    ".50 BMG",
  ];

  late FixedExtentScrollController _controller;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _calibers.indexOf(widget.initialCaliber);
    if (_selectedIndex == -1) _selectedIndex = 6; // Default to .260
    _controller = FixedExtentScrollController(initialItem: _selectedIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () {
            setState(() {
              _selectedIndex = _calibers.indexOf(".260 / 6.5mm");
              _controller.animateToItem(_selectedIndex, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(_calibers[_selectedIndex]),
          ),
        ],
        title: const Text('SET CALIBER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 60),
          const Text(
            'SELECTED CALIBER',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            _calibers[_selectedIndex],
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Selection Highlight Lines
                Container(
                  height: 60,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.white24, width: 1),
                      bottom: BorderSide(color: Colors.white24, width: 1),
                    ),
                  ),
                ),
                ListWheelScrollView.useDelegate(
                  controller: _controller,
                  itemExtent: 60,
                  perspective: 0.005,
                  diameterRatio: 1.5,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) {
                      final isSelected = _selectedIndex == index;
                      return Center(
                        child: Text(
                          _calibers[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white24,
                            fontSize: isSelected ? 24 : 18,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                    childCount: _calibers.length,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 40.0),
            child: Text(
              'Select the Caliber that was used',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
