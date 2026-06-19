import 'package:flutter/material.dart';

import '../geometry/projected_geometry.dart';

import '../rendering/orthographic_projector.dart';
import '../rendering/perspective_projector.dart';
import '../rendering/projection_mode.dart';

import '../scene/camera.dart';
import '../scene/figure.dart';
import '../scene/node.dart';
import '../scene/scene.dart';

import '../rendering/wireframe_renderer.dart';

/// Renders a scene using wireframe geometry.
///
/// The [WireframePainter] traverses the scene graph, projects visible figures into screen-space, and draws the edges
/// of their faces as line segments.
///
/// This painter is useful for debugging geometry, validating transformations, inspecting mesh topology, and
/// visualizing scene structure without textures.
class WireframePainter extends CustomPainter {

  /// The scene to be rendered.
  final Scene scene;

  WireframePainter({
    required super.repaint,
    required this.scene,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final camera = scene.camera;

    if (camera == null) return;

    final paint = Paint()
      ..color = const Color(0xFF607D8B)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    _render(
      node: scene,
      canvas: canvas,
      size: size,
      camera: camera,
      paint: paint,
    );
  }

  /// Recursively traverses the scene graph and renders all figures.
  void _render({
    required Node node,
    required Canvas canvas,
    required Size size,
    required Camera camera,
    required Paint paint,
  }) {
    if (node is Figure) {
      late final ProjectedGeometry geometry;

      if (camera.projectionMode == ProjectionMode.orthographic) {
        geometry = OrthographicProjector.project(
          camera: camera,
          figure: node,
          size: size,
        ).cullOffscreen(size);
      }
      else {
        geometry = PerspectiveProjector.project(
          camera: camera,
          figure: node,
          size: size,
        ).cullOffscreen(size);
      }

      WireframeRenderer.draw(
        canvas: canvas,
        geometry: geometry,
        paint: paint,
      );
    }

    for (final child in node.children) {
      _render(
        node: child,
        canvas: canvas,
        size: size,
        camera: camera,
        paint: paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
