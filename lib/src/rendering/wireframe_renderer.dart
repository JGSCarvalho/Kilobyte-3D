import 'dart:ui';

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
    required Paint paint,
  }) {
    final vpVertices = geometry.vertices;
    final vpFaces = geometry.faces;

    for (final vpFace in vpFaces) {
      final face = vpFace.face;
      final count = face.vIndices.length;

      if (count < 2) continue;

      for (int i = 0; i < count; i++) {
        final vt1 = vpVertices[face.vIndices[i]];
        final vt2 = vpVertices[face.vIndices[(i + 1) % count]];

        canvas.drawLine(vt1.position, vt2.position, paint);
      }
    }
  }
}
