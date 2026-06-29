import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../geometry/projected_geometry.dart';

import '../geometry/render_polygon.dart';
import '../rendering/orthographic_projector.dart';
import '../rendering/perspective_projector.dart';
import '../rendering/projection_mode.dart';
import '../rendering/textured_renderer.dart';

import '../scene/camera.dart';
import '../scene/figure.dart';
import '../scene/node.dart';
import '../scene/scene.dart';

import 'wireframe_renderer.dart';

/// Renders a scene using textured polygon surfaces.
///
/// The [TexturedPainter] traverses the scene graph, projects visible figures
/// into screen-space, collects all projected polygons into a global render
/// queue, sorts them using Painter's Algorithm, and rasterizes them in
/// back-to-front order.
///
/// Figures rendered by this painter must provide valid UV coordinates.
class TexturedPainter extends CustomPainter {

  /// The scene to be rendered.
  final Scene scene;

  final bool backfaceCulling;

  TexturedPainter({
    required super.repaint,
    required this.scene,
    this.backfaceCulling = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final camera = scene.camera;

    if (camera == null) return;

    final queue = <RenderPolygon> [];

    _collect(
      node: scene,
      size: size,
      camera: camera,
      queue: queue,
    );

    // Global Painter's Algorithm sorting.
    queue.sort(
      (a, b) => b.projectedFace.depth.compareTo(a.projectedFace.depth),
    );

    for (final polygon in queue) {
      final figure = polygon.figure;
      final geometry = polygon.geometry;
      final face = polygon.projectedFace;

      if (figure.texture != null) {
        final paint = Paint()
          ..shader = ui.ImageShader(
            figure.texture!,
            ui.TileMode.repeated,
            ui.TileMode.repeated,
            Matrix4.identity().storage,
          )
          ..blendMode = figure.blendMode
          ..isAntiAlias = false;

        TexturedRenderer.draw(
          canvas: canvas,
          geometry: geometry,
          face: face,
          texCoords: figure.texCoords,
          texture: figure.texture!,
          paint: paint,
        );
      }
      else {
        final paint = Paint()
          ..color = const Color(0xFF607D8B)
          ..strokeWidth = 1.0
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;

        WireframeRenderer.draw(
          canvas: canvas,
          geometry: geometry,
          face: face,
          paint: paint,
        );
      }
    }
  }

  /// Traverses the scene graph and collects projected polygons into the global
  /// render queue.
  void _collect({
    required Node node,
    required Size size,
    required Camera camera,
    required List<RenderPolygon> queue,
  }) {
    if (node is Figure) {
      ProjectedGeometry geometry;

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

      for (final face in geometry.faces) {
        queue.add(
          RenderPolygon(
            figure: node,
            geometry: geometry,
            projectedFace: face,
          ),
        );
      }
    }

    for (final child in node.children) {
      _collect(
        node: child,
        size: size,
        camera: camera,
        queue: queue,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}