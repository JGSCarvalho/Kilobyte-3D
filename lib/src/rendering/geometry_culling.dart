import 'dart:ui';

import '../geometry/face.dart';
import '../geometry/render_geometry.dart';

/// Provides visibility filtering operations for projected screen-space geometry.
///
/// Culling is a geometric optimization stage that discards faces that cannot contribute visible pixels to the final
/// frame.
///
/// This extension performs viewport-space rejection tests directly against the projected 2D coordinates produced by
/// the projection pipeline.
extension GeometryCulling on RenderGeometry {

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
  RenderGeometry cullOffscreen(Size size) {
    final List<Face> visibleFaces = [];

    for (int i = 0; i < faces.length; i++) {
      final face = faces[i];
      final indices = face.vertexIndices;

      if (indices.isEmpty) continue;

      bool isBehindCamera = false;
      bool isEntirelyLeft = true;
      bool isEntirelyRight = true;
      bool isEntirelyAbove = true;
      bool isEntirelyBelow = true;

      for (int j = 0; j < indices.length; j++) {
        final vertex = vertices[indices[j]];

        // Discard faces positioned behind the camera.
        if (vertex.depth < 0) {
          isBehindCamera = true;

          break;
        }

        final position = vertex.position;

        if (position.dx >= 0) {
          isEntirelyLeft = false;
        }

        if (position.dx <= size.width) {
          isEntirelyRight = false;
        }

        if (position.dy >= 0) {
          isEntirelyAbove = false;
        }

        if (position.dy <= size.height) {
          isEntirelyBelow = false;
        }
      }

      // Face is completely outside the viewport.
      if (isBehindCamera || isEntirelyLeft || isEntirelyRight || isEntirelyAbove || isEntirelyBelow) {
        continue;
      }

      visibleFaces.add(face);
    }

    return RenderGeometry(
      vertices: vertices,
      faces: visibleFaces,
    );
  }
}
