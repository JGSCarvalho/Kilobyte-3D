import 'package:flutter/material.dart';

import '../rendering/render_clock.dart';
import '../rendering/render_mode.dart';
import '../rendering/textured_painter.dart';
import '../rendering/wireframe_painter.dart';

import '../scene/scene.dart';

class Kilobyte3D extends StatefulWidget {

  /// The scene to be rendered.
  final Scene scene;

  /// The rendering mode.
  final RenderMode mode;

  /// The target rendering frame rate.
  final int fps;

  /// The desired viewport size.
  final Size size;

  /// Creates a 3D viewport.
  ///
  /// ---
  ///
  /// ### Parameters:
  ///
  /// - [scene]: The scene to render.
  /// - [mode]: The rendering mode.
  /// - [fps]: The target frame rate.
  /// - [size]: The viewport size.
  const Kilobyte3D({
    super.key,
    required this.scene,
    required this.mode,
    this.fps = 30,
    this.size = Size.zero,
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
        size: widget.size,
        painter: TexturedPainter(
          repaint: _clock,
          scene: widget.scene,
        ),
      );
    }
    else {
      _painter = CustomPaint(
        size: widget.size,
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
