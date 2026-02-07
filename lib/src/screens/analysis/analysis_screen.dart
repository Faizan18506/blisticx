import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blisticx/src/models/analysis_models.dart';
import 'package:blisticx/src/providers/settings_provider.dart';
import 'package:blisticx/src/services/coordinate_converter.dart';
import 'package:blisticx/src/screens/analysis/results_summary_screen.dart';

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
  
  double? _imageWidth;
  double? _imageHeight;

  @override
  void initState() {
    super.initState();
    _loadImageDimensions();
    // Initialize session with current settings
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _session = AnalysisSession(
      imagePath: widget.imagePath,
      unit: settings.isImperial ? "INCH" : "CM",
      caliber: settings.selectedCaliber,
      knownRefLength: 1.0, 
    );
  }

  Future<void> _loadImageDimensions() async {
    final data = await File(widget.imagePath).readAsBytes();
    final ui.Image image = await decodeImageFromList(data);
    if (mounted) {
      setState(() {
        _imageWidth = image.width.toDouble();
        _imageHeight = image.height.toDouble();
        
        // Initial scale to fit the image on screen
        final size = MediaQuery.of(context).size;
        final double initialScale = min(
          size.width / _imageWidth!, 
          (size.height - 200) / _imageHeight!
        );
        _transformationController.value = Matrix4.identity() * (Matrix4.diagonal3Values(initialScale, initialScale, 1.0));
      });
    }
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

  Future<void> _finishAnalysis() async {
    if (_session.shots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mark at least one shot')));
      return;
    }
    if (_session.refStart == null || _session.refEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Set a reference length')));
      return;
    }
    if (_session.aimingPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mark an aiming point (POA)')));
      return;
    }

    try {
      final GroupResult result = CoordinateConverter.analyze(
        _session, 
        imageWidth: _imageWidth!, 
        imageHeight: _imageHeight!
      );
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ResultsSummaryScreen(result: result),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
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
            onPressed: _finishAnalysis,
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
                    boundaryMargin: const EdgeInsets.all(2000),
                    minScale: 0.05,
                    maxScale: 20.0,
                    constrained: false, // Essential to allow the child to be its true size
                    child: _imageWidth == null 
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          width: _imageWidth,
                          height: _imageHeight,
                          child: Stack(
                            children: [
                              Image.file(
                                File(widget.imagePath),
                                width: _imageWidth,
                                height: _imageHeight,
                                fit: BoxFit.fill,
                              ),
                              // Render Shots
                              ..._session.shots.map((shot) {
                                // Default larger visual size for high-res images
                                double markerSize = (_imageWidth! * 0.05).clamp(40.0, 150.0);
                                
                                // Calculate caliber-based size if reference is set
                                if (_session.refStart != null && _session.refEnd != null) {
                                  final double pixelDistance = (_session.refEnd! - _session.refStart!).distance;
                                  final double pixelsPerInch = pixelDistance / _session.knownRefLength;
                                  final double caliberInches = CoordinateConverter.parseCaliber(_session.caliber);
                                  
                                  // Caliber size in pixels
                                  markerSize = caliberInches * pixelsPerInch;
                                  
                                  // If the literal caliber is too tiny to see/tap, we boost it slightly 
                                  // but keep it proportional. Visual minimum of 30px.
                                  markerSize = markerSize.clamp(30.0, 500.0);
                                }

                                return Positioned(
                                  left: shot.position.dx - markerSize / 2,
                                  top: shot.position.dy - markerSize / 2,
                                  child: _ShotMarker(color: Colors.redAccent, size: markerSize),
                                );
                              }),
                              // Render Ref Points
                              if (_session.refStart != null)
                                Positioned(
                                  left: _session.refStart!.dx - (_imageWidth! * 0.03).clamp(15.0, 60.0),
                                  top: _session.refStart!.dy - (_imageWidth! * 0.03).clamp(15.0, 60.0),
                                  child: Icon(Icons.add_circle, color: Colors.blueAccent, size: (_imageWidth! * 0.06).clamp(30.0, 120.0)),
                                ),
                              if (_session.refEnd != null)
                                Positioned(
                                  left: _session.refEnd!.dx - (_imageWidth! * 0.03).clamp(15.0, 60.0),
                                  top: _session.refEnd!.dy - (_imageWidth! * 0.03).clamp(15.0, 60.0),
                                  child: Icon(Icons.add_circle, color: Colors.blueAccent, size: (_imageWidth! * 0.06).clamp(30.0, 120.0)),
                                ),
                              if (_session.refStart != null && _session.refEnd != null)
                                CustomPaint(
                                  painter: _LinePainter(
                                    _session.refStart!, 
                                    _session.refEnd!, 
                                    Colors.blueAccent,
                                    thickness: (_imageWidth! * 0.01).clamp(4.0, 20.0),
                                  ),
                                ),
                              // Render Aiming Point
                              if (_session.aimingPoint != null)
                                Positioned(
                                  left: _session.aimingPoint!.dx - (_imageWidth! * 0.06).clamp(30.0, 100.0),
                                  top: _session.aimingPoint!.dy - (_imageWidth! * 0.06).clamp(30.0, 100.0),
                                  child: Icon(Icons.track_changes_rounded, color: Colors.orangeAccent, size: (_imageWidth! * 0.12).clamp(60.0, 200.0)),
                                ),


                            ],
                          ),
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
  final double thickness;

  _LinePainter(this.start, this.end, this.color, {this.thickness = 2.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;
    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class _ShotMarker extends StatelessWidget {
  final Color color;
  final double size;
  const _ShotMarker({required this.color, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: (size * 0.1).clamp(2.0, 8.0)),
      ),
      child: Center(
        child: Container(
          width: (size * 0.2).clamp(4.0, 20.0),
          height: (size * 0.2).clamp(4.0, 20.0),
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
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
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
            child: SizedBox(
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
