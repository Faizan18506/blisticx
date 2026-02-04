import 'dart:io';
import 'package:flutter/material.dart';
import 'package:blisticx/src/models/analysis_models.dart';

class AnalysisScreen extends StatefulWidget {
  final String imagePath;

  const AnalysisScreen({super.key, required this.imagePath});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  late AnalysisSession _session;
  final TransformationController _transformationController = TransformationController();
  
  DigitizerMode _mode = DigitizerMode.shots;
  Offset? _tempDragPosition;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _session = AnalysisSession(imagePath: widget.imagePath);
  }

  void _handleInteraction(Offset scenePosition) {
    setState(() {
      switch (_mode) {
        case DigitizerMode.shots:
          _session.shots.add(Shot(position: scenePosition));
          break;
        case DigitizerMode.reference:
          if (_session.refStart == null) {
            _session.refStart = scenePosition;
          } else if (_session.refEnd == null) {
            _session.refEnd = scenePosition;
          } else {
            // Already have both? Replace the closest or just reset
            _session.refStart = scenePosition;
            _session.refEnd = null;
          }
          break;
        case DigitizerMode.aiming:
          _session.aimingPoint = scenePosition;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_mode == DigitizerMode.shots 
          ? 'Mark Shots' 
          : _mode == DigitizerMode.aiming ? 'Mark Aim Point' : 'Set Reference'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo_rounded),
            onPressed: () {
              setState(() {
                if (_mode == DigitizerMode.shots && _session.shots.isNotEmpty) {
                  _session.shots.removeLast();
                } else if (_mode == DigitizerMode.reference) {
                   if (_session.refEnd != null) _session.refEnd = null;
                   else _session.refStart = null;
                } else if (_mode == DigitizerMode.aiming) {
                  _session.aimingPoint = null;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
            onPressed: () {
               // Validate and proceed
               if (_session.shots.isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mark at least one shot')));
                 return;
               }
               if (_session.refStart == null || _session.refEnd == null) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Set a reference length')));
                 return;
               }
               // Proceed to results
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                GestureDetector(
                  onLongPressStart: (details) {
                    setState(() {
                      _isDragging = true;
                      _tempDragPosition = _transformationController.toScene(details.localPosition);
                    });
                  },
                  onLongPressMoveUpdate: (details) {
                    setState(() {
                      _tempDragPosition = _transformationController.toScene(details.localPosition);
                    });
                  },
                  onLongPressEnd: (details) {
                    if (_tempDragPosition != null) {
                      _handleInteraction(_tempDragPosition!);
                    }
                    setState(() {
                      _isDragging = false;
                      _tempDragPosition = null;
                    });
                  },
                  onTapDown: (details) {
                    _handleInteraction(_transformationController.toScene(details.localPosition));
                  },
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    boundaryMargin: const EdgeInsets.all(500),
                    minScale: 0.1,
                    maxScale: 20.0,
                    child: Stack(
                      children: [
                        Image.file(
                          File(widget.imagePath),
                          fit: BoxFit.contain,
                        ),
                        // Render Shots
                        ..._session.shots.map((shot) => Positioned(
                              left: shot.position.dx - 12,
                              top: shot.position.dy - 12,
                              child: const _ShotMarker(color: Colors.redAccent),
                            )),
                        // Render Ref Points
                        if (_session.refStart != null)
                          Positioned(
                            left: _session.refStart!.dx - 8,
                            top: _session.refStart!.dy - 8,
                            child: const Icon(Icons.add_circle, color: Colors.blueAccent, size: 16),
                          ),
                        if (_session.refEnd != null)
                          Positioned(
                            left: _session.refEnd!.dx - 8,
                            top: _session.refEnd!.dy - 8,
                            child: const Icon(Icons.add_circle, color: Colors.blueAccent, size: 16),
                          ),
                        if (_session.refStart != null && _session.refEnd != null)
                           CustomPaint(
                             painter: _LinePainter(_session.refStart!, _session.refEnd!, Colors.blueAccent),
                           ),
                        // Render Aiming Point
                        if (_session.aimingPoint != null)
                          Positioned(
                            left: _session.aimingPoint!.dx - 15,
                            top: _session.aimingPoint!.dy - 15,
                            child: const Icon(Icons.track_changes_rounded, color: Colors.orangeAccent, size: 30),
                          ),
                      ],
                    ),
                  ),
                ),
                
                // Magnifying Glass
                if (_isDragging && _tempDragPosition != null)
                  Positioned(
                    top: 50,
                    left: size.width / 2 - 75,
                    child: _Magnifier(
                      imagePath: widget.imagePath,
                      position: _tempDragPosition!,
                    ),
                  ),
              ],
            ),
          ),
          
          // Mode Selector Bottom Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: const Border(top: BorderSide(color: Colors.white10)),
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ModeButton(
                    icon: Icons.adjust_rounded,
                    label: 'Shots',
                    isActive: _mode == DigitizerMode.shots,
                    onTap: () => setState(() => _mode = DigitizerMode.shots),
                    activeColor: Colors.redAccent,
                  ),
                  _ModeButton(
                    icon: Icons.straighten_rounded,
                    label: 'Ref',
                    isActive: _mode == DigitizerMode.reference,
                    onTap: () => setState(() => _mode = DigitizerMode.reference),
                    activeColor: Colors.blueAccent,
                  ),
                  _ModeButton(
                    icon: Icons.track_changes_rounded,
                    label: 'Aim',
                    isActive: _mode == DigitizerMode.aiming,
                    onTap: () => setState(() => _mode = DigitizerMode.aiming),
                    activeColor: Colors.orangeAccent,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? activeColor : Colors.grey, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? activeColor : Colors.grey,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;

  _LinePainter(this.start, this.end, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// ... _ShotMarker, _Magnifier, _CrosshairPainter Classes same as before ...
class _ShotMarker extends StatelessWidget {
  final Color color;
  const _ShotMarker({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ),
    );
  }
}

class _Magnifier extends StatelessWidget {
  final String imagePath;
  final Offset position;

  const _Magnifier({required this.imagePath, required this.position});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Transform.scale(
            scale: 5,
            alignment: Alignment.center,
            child: Transform.translate(
              offset: Offset(-position.dx, -position.dy),
              child: Image.file(
                File(imagePath),
                fit: BoxFit.none,
                alignment: Alignment.topLeft,
              ),
            ),
          ),
          Center(
            child: Container(
              width: 150,
              height: 150,
              child: CustomPaint(painter: _CrosshairPainter()),
            ),
          ),
        ],
      ),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 2, Paint()..color = Colors.redAccent);
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
