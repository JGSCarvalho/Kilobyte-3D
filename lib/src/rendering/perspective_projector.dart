import 'dart:math' as math;
import 'dart:ui';

import '../geometry/render_geometry.dart';
import '../geometry/render_vertex.dart';

import '../scene/camera.dart';
import '../scene/figure.dart';

/// Projects geometry using perspective projection.
///
/// Perspective projection applies depth-based scaling: objects farther from the camera appear smaller.
abstract final class PerspectiveProjector {

  /// Projects a figure into 2D screen-space using perspective projection.
  ///
  /// ---
  ///
  /// ### Parameters:
  ///
  /// - [camera]: Camera providing FOV and view transform.
  /// - [figure]: Mesh to be projected.
  /// - [size]: Viewport dimensions.
  static RenderGeometry project({
    required Camera camera,
    required Figure figure,
    required Size size,
  }) {
    final vertices = List<RenderVertex>.filled(figure.vertices.length, const RenderVertex());
    final focalDistance = size.height / (2 * math.tan(camera.fov * math.pi / 360));
    final worldMatrix = figure.worldMatrix;

    for (int i = 0; i < figure.vertices.length; i++) {
      final local = figure.vertices[i];
      final world = worldMatrix.transform3(local.clone());
      final view = camera.toViewSpace(world);

      // Discard vertices located behind the camera or too close to the projection plane.
      if (view.z <= 0.1) continue;

      // Perspective division.
      // As depth increases, the scale factor decreases, causing distant objects to appear smaller on screen.
      final scale = focalDistance / view.z;

      vertices[i] = RenderVertex(
        position: Offset(
          size.width / 2 + view.x * scale,
          size.height / 2 - view.y * scale,
        ),
        depth: view.z,
      );
    }

    return RenderGeometry(
      vertices: vertices,
      faces: figure.faces,
    );
  }
}
