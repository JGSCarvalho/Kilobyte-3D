import 'dart:ui';

import '../geometry/projected_face.dart';
import '../geometry/projected_geometry.dart';

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
    required ProjectedGeometry geometry,
    required ProjectedFace face,
    required Paint paint,
  }) {
    final pjVertices = geometry.vertices;

    final polygon = face.face;
    final count = polygon.vIndices.length;

    if (count < 2) return;

    for (int i = 0; i < count; i++) {
      final v1 = pjVertices[polygon.vIndices[i]];
      final v2 = pjVertices[polygon.vIndices[(i + 1) % count]];

      canvas.drawLine(v1.position, v2.position, paint);
    }
  }
}
