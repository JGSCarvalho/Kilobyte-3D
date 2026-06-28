import 'dart:ui';

import '../geometry/projected_face.dart';
import '../geometry/projected_geometry.dart';
import '../geometry/projected_vertex.dart';

import '../scene/camera.dart';
import '../scene/figure.dart';

/// Projects geometry using an orthographic projection model.
///
/// In orthographic projection, depth (Z) has no influence on scale: parallel lines remain parallel in screen-space.
abstract final class OrthographicProjector {

  /// Projects a figure into 2D screen-space using orthographic projection.
  ///
  /// ---
  ///
  /// ### Parameters:
  ///
  /// - [camera]: Camera providing view transform and scale factor.
  /// - [figure]: Mesh to be projected.
  /// - [size]: Viewport dimensions.
  static ProjectedGeometry project({
    required Camera camera,
    required Figure figure,
    required Size size,
  }) {
    final vertices = List<ProjectedVertex>.filled(figure.vertices.length, const ProjectedVertex());
    final worldMatrix = figure.worldMatrix;

    for (int i = 0; i < figure.vertices.length; i++) {
      final local = figure.vertices[i];
      final world = worldMatrix.transform3(local.clone());
      final view = camera.toViewSpace(world);

      // If the vertex is behind the camera, or too close to the camera, discard it.
      if (view.z >= -0.1) {
        vertices[i] = const ProjectedVertex(
          position: Offset.zero,
          depth: -1.0,
        );
        
        continue;
      }

      // Orthographic projection ignores depth, preserving the apparent size of objects regardless of their distance
      // from the camera.
      vertices[i] = ProjectedVertex(
        position: Offset(
          size.width / 2 + view.x * camera.pixelsPerUnit,
          size.height / 2 - view.y * camera.pixelsPerUnit,
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

    return ProjectedGeometry(
      vertices: vertices,
      faces: faces,
      uvs: figure.texCoords,
    );
  }
}
