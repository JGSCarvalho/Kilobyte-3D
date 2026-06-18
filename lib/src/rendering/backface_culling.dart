import '../geometry/face.dart';
import '../geometry/render_geometry.dart';

/// Provides back-face culling operations for projected geometry.
///
/// Back-face culling removes polygons whose projected winding order indicates that they are facing away from the
/// camera, reducing the amount of geometry that reaches the rendering stage.
///
/// The evaluation is performed entirely in screen space using the winding order of the first three vertices of each
/// face.
extension BackfaceCulling on RenderGeometry {

  /// Removes back-facing polygons from the geometry.
  ///
  /// ---
  ///
  /// ### Parameters:
  ///
  /// - [clockwiseIsFront]: Defines which winding order is considered front-facing. Defaults to `false`, meaning
  ///   counter-clockwise faces are treated as visible.
  RenderGeometry cullBackfaces({
    bool clockwiseIsFront = false,
  }) {
    final projectedVertices = vertices;
    final visibleFaces = <Face> [];

    for (int i = 0; i < faces.length; i++) {
      final face = faces[i];

      // A face requires at least three vertices to establish a valid winding order.
      if (face.vertexIndices.length < 3) {
        visibleFaces.add(face);

        continue;
      }

      final p0 = projectedVertices[face.vertexIndices[0]];
      final p1 = projectedVertices[face.vertexIndices[1]];
      final p2 = projectedVertices[face.vertexIndices[2]];

      // Signed area of the projected triangle.
      // The sign indicates the screen-space winding order.
      final cross = (p1.position.dx - p0.position.dx) * (p2.position.dy - p0.position.dy) -
                    (p1.position.dy - p0.position.dy) * (p2.position.dx - p0.position.dx);

      // Flutter uses a downward-positive Y axis, which inverts the traditional Cartesian winding convention.
      final isFrontFace = clockwiseIsFront ? cross > 0.0
                                           : cross < 0.0;

      if (isFrontFace) visibleFaces.add(face);
    }

    return RenderGeometry(
      vertices: projectedVertices,
      faces: visibleFaces,
    );
  }
}
