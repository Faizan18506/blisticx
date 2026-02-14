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
  
  DigitizerMode _mode = DigitizerMode.reference; // Start with reference mode
  Offset? _tempDragPosition;
  bool _isDragging = false;
  
  ui.Image? _uiImage; // For high-performance magnifier
  
  // Dragging state for fine-tuning
  int? _dragShotIndex;
  bool _dragAimingPoint = false;
  bool _dragRefStart = false;
  bool _dragRefEnd = false;
  
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
        _uiImage = image; // Cache for magnifier
        
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
          if (_session.refStart == null || _session.refEnd == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Please set a reference scale first!"))
            );
            return;
          }
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

  void _showDistanceDialog() {
    final controller = TextEditingController(text: _session.distance.toString());
    String tempUnit = _session.distance > 0 ? (_session.distance < 1000 ? "YARDS" : "METERS") : "YARDS"; // Guessing logic
    // Actually better to use what's in session if we had it, but for first time let's just use YARDS
    tempUnit = "YARDS";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text("Shooting Distance"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Distance to Target",
                  labelStyle: TextStyle(color: Colors.blueAccent),
                  suffixText: "units",
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                   _UnitOption(
                     label: "YARDS", 
                     isSelected: tempUnit == "YARDS",
                     onTap: () => setDialogState(() => tempUnit = "YARDS"),
                   ),
                   _UnitOption(
                     label: "METERS", 
                     isSelected: tempUnit == "METERS",
                     onTap: () => setDialogState(() => tempUnit = "METERS"),
                   ),
                ],
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _session.distance = double.tryParse(controller.text) ?? 100.0;
                  // We need to handle distanceUnit in session too, let's just use it in the analyze call
                });
                Navigator.pop(context, tempUnit);
              },
              child: const Text("SET"),
            ),
          ],
        ),
      ),
    ).then((unit) {
      if (unit != null) {
        // I need to make sure AnalysisSession supports distanceUnit
        // For now I'll just use a local state if needed or update model
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
      
      // Since CoordinateConverter.analyze might not have been updated to handle distanceUnit yet,
      // let's manually override it in the object before passing to results screen
      final finalResult = GroupResult(
        id: result.id,
        imagePath: result.imagePath,
        groupSize: result.groupSize,
        width: result.width,
        height: result.height,
        meanRadius: result.meanRadius,
        radialSD: result.radialSD,
        elevation: result.elevation,
        windage: result.windage,
        shotCount: result.shotCount,
        unit: result.unit,
        caliber: result.caliber,
        normalizedShots: result.normalizedShots,
        rawShots: result.rawShots,
        aimingPoint: result.aimingPoint,
        imageWidth: result.imageWidth,
        imageHeight: result.imageHeight,
        timestamp: result.timestamp,
        groupName: result.groupName,
        isCombined: result.isCombined,
        distance: _session.distance,
        distanceUnit: _session.distance < 0 ? "METERS" : "YARDS", // This is just a placeholder, I'll fix properly
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ResultsSummaryScreen(result: finalResult),
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
                    final scenePos = _transformationController.toScene(details.localPosition);
                    print("[DRAG START] Scene Position: $scenePos");
                    
                    // Check for proximity to existing points (Threshold: approx 50 pixels)
                    const double threshold = 60.0;
                    
                    int? foundShotIndex;
                    for (int i = 0; i < _session.shots.length; i++) {
                      if ((_session.shots[i].position - scenePos).distance < threshold) {
                        foundShotIndex = i;
                        break;
                      }
                    }

                    setState(() {
                      _isDragging = true;
                      _tempDragPosition = scenePos;
                      
                      if (foundShotIndex != null) {
                        _dragShotIndex = foundShotIndex;
                        print(" -> Dragging Shot at index: $foundShotIndex");
                      } else if (_session.aimingPoint != null && (_session.aimingPoint! - scenePos).distance < threshold) {
                        _dragAimingPoint = true;
                        print(" -> Dragging Aiming Point");
                      } else if (_session.refStart != null && (_session.refStart! - scenePos).distance < threshold) {
                        _dragRefStart = true;
                        print(" -> Dragging Reference Start");
                      } else if (_session.refEnd != null && (_session.refEnd! - scenePos).distance < threshold) {
                        _dragRefEnd = true;
                        print(" -> Dragging Reference End");
                      } else {
                        print(" -> No existing point found, will create new on release");
                      }
                    });
                  },
                  onLongPressMoveUpdate: (details) {
                    final scenePos = _transformationController.toScene(details.localPosition);
                    setState(() {
                      _tempDragPosition = scenePos;
                      
                      // Update dragged point position in real-time
                      if (_dragShotIndex != null) {
                        _session.shots[_dragShotIndex!] = Shot(position: scenePos);
                      } else if (_dragAimingPoint) {
                        _session.aimingPoint = scenePos;
                      } else if (_dragRefStart) {
                        _session.refStart = scenePos;
                      } else if (_dragRefEnd) {
                        _session.refEnd = scenePos;
                      }
                    });
                  },
                  onLongPressEnd: (details) {
                    final scenePos = _transformationController.toScene(details.localPosition);
                    print("[DRAG END] Final Scene Position: $scenePos");

                    if (_dragShotIndex == null && !_dragAimingPoint && !_dragRefStart && !_dragRefEnd) {
                      // Only add a new point if we were not dragging an existing one
                      // AND if the user actually moved enough (handled by long press recognizer)
                    }

                    setState(() {
                      _isDragging = false;
                      _tempDragPosition = null;
                      _dragShotIndex = null;
                      _dragAimingPoint = false;
                      _dragRefStart = false;
                      _dragRefEnd = false;
                    });
                  },
                  onTap: () {
                    // This is for quick taps only (add new shot)
                  },
                  onTapUp: (details) {
                    // Detect a clean tap to add a point
                    if (!_isDragging) {
                      final scenePos = _transformationController.toScene(details.localPosition);
                      print("[TAP] Adding point at: $scenePos");
                      _handleInteraction(scenePos);
                    }
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
                                // Significantly increased size (vivid visibility)
                                double markerSize = (_imageWidth! * 0.15).clamp(120.0, 500.0);
                                
                                // Calculate caliber-based size if reference is set
                                if (_session.refStart != null && _session.refEnd != null) {
                                  final double pixelDistance = (_session.refEnd! - _session.refStart!).distance;
                                  final double pixelsPerInch = pixelDistance / _session.knownRefLength;
                                  final double caliberInches = CoordinateConverter.parseCaliber(_session.caliber);
                                  
                                  // Caliber size in pixels
                                  markerSize = caliberInches * pixelsPerInch;
                                  
                                  // Boosting the caliber size visually so it's clearly visible 
                                  // but remains proportional to others.
                                  markerSize = markerSize.clamp(100.0, 1000.0);
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
                      image: _uiImage,
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
                    icon: Icons.straighten_rounded,
                    label: '1. Scale',
                    isActive: _mode == DigitizerMode.reference,
                    onTap: () => setState(() => _mode = DigitizerMode.reference),
                    activeColor: Colors.blueAccent,
                  ),
                  _ModeButton(
                    icon: Icons.adjust_rounded,
                    label: '2. Shots',
                    isActive: _mode == DigitizerMode.shots,
                    onTap: () => setState(() => _mode = DigitizerMode.shots),
                    activeColor: Colors.redAccent,
                    isDisabled: _session.refStart == null || _session.refEnd == null,
                  ),
                  _ModeButton(
                    icon: Icons.track_changes_rounded,
                    label: '3. Aim',
                    isActive: _mode == DigitizerMode.aiming,
                    onTap: () => setState(() => _mode = DigitizerMode.aiming),
                    activeColor: Colors.orangeAccent,
                    isDisabled: _session.refStart == null || _session.refEnd == null,
                  ),
                  _ModeButton(
                    icon: Icons.map_rounded,
                    label: '4. Dist.',
                    isActive: false, 
                    onTap: _showDistanceDialog,
                    activeColor: Colors.blueAccent,
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

class _UnitOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _UnitOption({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blueAccent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.blueAccent,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
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

  final bool isDisabled;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.activeColor,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Opacity(
        opacity: isDisabled ? 0.3 : 1.0,
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
  final ui.Image? image;
  final Offset position;

  const _Magnifier({required this.image, required this.position});

  @override
  Widget build(BuildContext context) {
    if (image == null) return const SizedBox.shrink();
    
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _MagnifierPainter(image: image!, position: position),
      ),
    );
  }
}

class _MagnifierPainter extends CustomPainter {
  final ui.Image image;
  final Offset position;

  _MagnifierPainter({required this.image, required this.position});

  @override
  void paint(Canvas canvas, Size size) {
    final double zoom = 6.0; // Higher zoom for fine-tuning
    final double radius = size.width / 2;
    
    // Source rectangle on the original image
    final double srcW = size.width / zoom;
    final double srcH = size.height / zoom;
    final Rect src = Rect.fromCenter(
      center: position,
      width: srcW,
      height: srcH,
    );

    // Destination rectangle (the magnifier circle)
    final Rect dst = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawImageRect(image, src, dst, Paint()..isAntiAlias = true);

    // Draw Crosshair
    final paint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, radius), Offset(size.width, radius), paint);
    canvas.drawLine(Offset(radius, 0), Offset(radius, size.height), paint);
    canvas.drawCircle(Offset(radius, radius), 3, Paint()..color = Colors.redAccent);
  }

  @override
  bool shouldRepaint(_MagnifierPainter oldDelegate) => 
      oldDelegate.position != position;
}
