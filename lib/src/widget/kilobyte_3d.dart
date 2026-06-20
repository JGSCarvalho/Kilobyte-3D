import 'package:flutter/material.dart';

import '../rendering/render_clock.dart';
import '../rendering/render_mode.dart';
import '../rendering/textured_painter.dart';
import '../rendering/wireframe_painter.dart';

import '../scene/scene.dart';

/// A 3D viewport widget.
/// 
/// The engine uses a right-handed coordinate system:
/// 
/// +X = right
/// +Y = up
/// -Z = forward
class Kilobyte3D extends StatefulWidget {

  /// The scene to be rendered.
  final Scene scene;

  /// The rendering mode.
  final RenderMode mode;

  /// The target rendering frame rate.
  final int fps;

  /// The desired viewport size.
  final Size size;

  final bool backfaceCulling;

  /// Creates a 3D viewport.
  ///
  /// ---
  ///
  /// ### Parameters:
  ///
  /// - [scene]: The scene graph to render.
  /// - [mode]: The active rendering mode.
  /// - [fps]: The target rendering frame rate.
  /// - [size]: Optional fixed viewport dimensions.
  const Kilobyte3D({
    super.key,
    required this.scene,
    required this.mode,
    required this.size,
    this.backfaceCulling = true,
    this.fps = 30,
  });

  @override
  State<Kilobyte3D> createState() => _Kilobyte3DState();
}

class _Kilobyte3DState extends State<Kilobyte3D> {
  late final RenderClock _clock;
  
  late CustomPaint _painter;

  @override
  void initState() {
    super.initState();

    _clock = RenderClock(widget.fps)..initialize();
  }

  @override
  void dispose() {
    _clock.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mode == RenderMode.textured) {
      _painter = CustomPaint(
        painter: TexturedPainter(
          repaint: _clock,
          scene: widget.scene,
          backfaceCulling: widget.backfaceCulling,
        ),
      );
    }
    else {
      _painter = CustomPaint(
        painter: WireframePainter(
          repaint: _clock,
          scene: widget.scene,
        ),
      );
    }

    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: widget.size.width,
        height: widget.size.height,
        child: ClipRect(
          child: _painter,
        ),
      ),
    );
  }
}
