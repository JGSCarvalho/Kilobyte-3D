import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../geometry/projected_geometry.dart';

import '../rendering/orthographic_projector.dart';
import '../rendering/perspective_projector.dart';
import '../rendering/projection_mode.dart';
import '../rendering/textured_renderer.dart';

import '../scene/camera.dart';
import '../scene/figure.dart';
import '../scene/node.dart';
import '../scene/scene.dart';

/// Renders a scene using textured polygon surfaces.
///
/// The [TexturedPainter] traverses the scene graph, projects visible figures into screen-space, performs optional
/// back-face culling, and rasterizes textured polygons through Flutter's vertex rendering API.
///
/// Figures rendered by this painter must provide valid UV coordinates.
class TexturedPainter extends CustomPainter {

  /// The scene to be rendered.
  final Scene scene;

  TexturedPainter({
    required super.repaint,
    required this.scene,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final camera = scene.camera;

    if (camera == null) return;

    _render(
      node: scene,
      canvas: canvas,
      size: size,
      camera: camera,
    );
  }

  /// Recursively traverses the scene graph and renders all textured figures.
  void _render({
    required Node node,
    required Canvas canvas,
    required Size size,
    required Camera camera,
  }) {
    if (node is Figure) {
      late final ProjectedGeometry geometry;

      if (camera.projectionMode == ProjectionMode.orthographic) {
        geometry = OrthographicProjector.project(
          camera: camera,
          figure: node,
          size: size,
        ).cullBackfaces().cullOffscreen(size);
      }
      else {
        geometry = PerspectiveProjector.project(
          camera: camera,
          figure: node,
          size: size,
        ).cullBackfaces().cullOffscreen(size);
      }

      assert(node.texture != null, 'Figures must have a texture, provide a texture or change to wireframe mode!');
      
      if (node.texture == null) return;
      
      final paint = Paint()
        ..shader = ui.ImageShader(
          node.texture!,
          ui.TileMode.clamp,
          ui.TileMode.clamp,
          Matrix4.identity().storage,
        )
        ..style = PaintingStyle.fill;
      
      TexturedRenderer.draw(
        canvas: canvas,
        geometry: geometry,
        uvs: node.uvs,
        texture: node.texture!,
        paint: paint,
      );
    }

    for (final child in node.children) {
      _render(
        node: child,
        canvas: canvas,
        size: size,
        camera: camera,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
