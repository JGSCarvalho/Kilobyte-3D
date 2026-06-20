import 'dart:math' as math;
import 'dart:ui';

import '../geometry/projected_face.dart';
import '../geometry/projected_geometry.dart';
import '../geometry/projected_vertex.dart';

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
  static ProjectedGeometry project({
    required Camera camera,
    required Figure figure,
    required Size size,
  }) {
    final vertices = List<ProjectedVertex>.filled(figure.vertices.length, const ProjectedVertex());
    final focalDistance = size.height / (2 * math.tan(camera.fov * math.pi / 360));
    final worldMatrix = figure.worldMatrix;

    for (int i = 0; i < figure.vertices.length; i++) {
      final local = figure.vertices[i];
      final world = worldMatrix.transform3(local.clone());
      final view = camera.toViewSpace(world);

      // If the vertex is behind the camera, or too close to the camera, discard it.
      if (view.z >= 0.1) {
        vertices[i] = const ProjectedVertex(
          position: Offset.zero,
          depth: -1.0,
        );
        
        continue;
      }

      // Perspective division.
      // As depth increases, the scale factor decreases, causing distant objects to appear smaller on screen.
      final scale = focalDistance / view.z;

      vertices[i] = ProjectedVertex(
        position: Offset(
          size.width / 2 + view.x * scale,
          size.height / 2 - view.y * scale,
        ),
        depth: -view.z,
      );
    }

    final faces = <ProjectedFace> [];

    for (final face in figure.faces) {
      double depth = 0;
  
      for (final index in face.vIndices) {
        depth += vertices[index].depth;
      }
  
      depth /= face.vIndices.length;
  
      faces.add(ProjectedFace(face, depth));
    }
  
    // Painter algorithm (far → near)
    faces.sort((a, b) => b.depth.compareTo(a.depth));

    return ProjectedGeometry(
      uvs: figure.uvs,
      vertices: vertices,
      faces: faces,
    );
  }
}
