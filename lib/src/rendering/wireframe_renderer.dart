import 'dart:ui';

import '../geometry/render_geometry.dart';

/// Rasterizes geometry as wireframe lines.
///
/// This renderer draws only polygon edges, ignoring surface data.
/// It is primarily used for debugging, visualization of topology, and lightweight scene inspection.
abstract final class WireframeRenderer {

  /// Draws all polygon edges defined by the geometry faces.
  ///
  /// Each face is rendered as a closed loop of line segments.
  ///
  /// ---
  ///
  /// ### Parameters:
  ///
  /// - [canvas]: The target canvas receiving draw calls.
  /// - [geometry]: Screen-space projected geometry.
  /// - [paint]: Stroke configuration used for line rendering.
  static void draw({
    required Canvas canvas,
    required RenderGeometry geometry,
    required Paint paint,
  }) {
    final points = geometry.vertices;
    final faces = geometry.faces;

    for (final face in faces) {
      final count = face.vertexIndices.length;

      if (count < 2) continue;

      for (int i = 0; i < count; i++) {
        final p1 = points[face.vertexIndices[i]];
        final p2 = points[face.vertexIndices[(i + 1) % count]];

        canvas.drawLine(p1.position, p2.position, paint);
      }
    }
  }
}
