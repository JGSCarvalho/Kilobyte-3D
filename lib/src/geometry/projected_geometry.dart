import 'dart:ui';

import 'package:vector_math/vector_math_64.dart';

import '../geometry/projected_face.dart';
import '../geometry/projected_vertex.dart';

/// Represents fully projected geometry inside viewport space.
///
/// A projected geometry contains the final 2D projection data produced by the projection pipeline and ready to be
/// consumed by the rendering stage.
///
/// Unlike source scene geometry, viewport geometry exists entirely in screen coordinates after camera and projection
/// transformations have already been applied.
class ProjectedGeometry {

  /// The projected screen-space vertices.
  ///
  /// Each vertex contains:
  ///
  /// - Its final viewport position;
  /// - Its camera-space depth.
  final List<ProjectedVertex> vertices;

  /// The texture coordinate buffer (UV map) for the geometry.
  ///
  /// Each [Vector2] represents a normalized position in texture space (typically ranging from `0.0` to `1.0`) where:
  ///
  /// - `x` corresponds to the horizontal texture axis (U);
  /// - `y` corresponds to the vertical texture axis (V), pre-inverted to align with Flutter's top-left canvas origin.
  ///
  /// Projected faces reference indices within this list to correctly map image textures onto 2D screen fragments.
  final List<Vector2> uvs;

  /// The projected faces prepared for rendering.
  ///
  /// Faces may contain additional viewport-specific metadata such as precomputed depth values used by the painter
  /// algorithm.
  final List<ProjectedFace> faces;

  const ProjectedGeometry({
    required this.faces,
    required this.vertices,
    required this.uvs,
  });

  /// Removes faces that are completely outside the viewport or positioned behind the camera.
  ///
  /// Faces are discarded when any vertex is located outside the viewport (`x < 0 || x > width || y < 0 || y > height`),
  /// or positioned behind the camera (`z < 0`).
  ///
  /// The algorithm performs a trivial reject test similar to classic software rendering pipelines.
  /// 
  /// ---
  /// 
  /// ### Parameters:
  ///
  /// - [size]: The viewport dimensions used for visibility testing.
  ///
  /// ---
  ///
  /// ### Notes:
  ///
  /// - Faces that are partially intersecting the viewport remain visible, needing a separate cliping step.
  ProjectedGeometry cullOffscreen(Size size) {
    final pjFaces = <ProjectedFace> [];

    for (int i = 0; i < faces.length; i++) {
      final pjFace = faces[i];
      final indices = pjFace.face.vIndices;

      if (indices.isEmpty) {
        continue;
      }

      bool isBehindCamera = false;

      bool isLeftOutside = true;
      bool isRightOutside = true;
      bool isTopOutside = true;
      bool isBottomOutside = true;

      for (int j = 0; j < indices.length; j++) {
        final vertex = vertices[indices[j]];

        // Discard faces positioned behind the camera.
        if (vertex.depth < 0) {
          isBehindCamera = true;

          break;
        }

        final position = vertex.position;

        if (position.dx >= 0) {
          isLeftOutside = false;
        }

        if (position.dx <= size.width) {
          isRightOutside = false;
        }

        if (position.dy >= 0) {
          isTopOutside = false;
        }

        if (position.dy <= size.height) {
          isBottomOutside = false;
        }
      }

      // Face is completely outside the viewport.
      if (isBehindCamera || isLeftOutside || isRightOutside || isTopOutside || isBottomOutside) {
        continue;
      }

      pjFaces.add(pjFace);
    }

    return ProjectedGeometry(
      faces: pjFaces,
      uvs: uvs,
      vertices: vertices,
    );
  }

  /// Removes back-facing polygons from the geometry.
  ///
  /// ---
  ///
  /// ### Parameters:
  ///
  /// - [isClockwiseFrontFace]: Defines which winding order is considered front-facing.
  ProjectedGeometry cullBackfaces([bool isClockwiseFrontFace = true]) {
    final pjVertices = vertices;
    final pjFaces = <ProjectedFace> [];

    for (int i = 0; i < faces.length; i++) {
      final pjFace = faces[i];
      final face = pjFace.face;

      // A face requires at least three vertices to establish a valid winding order.
      if (face.vIndices.length < 3) {
        pjFaces.add(pjFace);

        continue;
      }

      final p0 = pjVertices[face.vIndices[0]];
      final p1 = pjVertices[face.vIndices[1]];
      final p2 = pjVertices[face.vIndices[2]];

      // Screen-space signed area (2D cross product).
      // The sign indicates the screen-space winding order.
      final cross = (p1.position.dx - p0.position.dx) * (p2.position.dy - p0.position.dy) -
                    (p1.position.dy - p0.position.dy) * (p2.position.dx - p0.position.dx);

      // Flutter uses a downward-positive Y axis, which inverts the traditional Cartesian winding convention.
      final isFrontFace = isClockwiseFrontFace ? cross > 0.0 : cross < 0.0;

      if (isFrontFace) pjFaces.add(pjFace);
    }

    return ProjectedGeometry(
      faces: pjFaces,
      uvs: uvs,
      vertices: vertices,
    );
  }
}
