import 'dart:ui';

import 'package:vector_math/vector_math_64.dart';

import '../../kilobyte_3d.dart';

import '../geometry/geometry_2d.dart';

/// Projects 3D geometry into 2D screen-space.
abstract final class OrthographicProjector {

  /// Projects a runtime [Mesh] into reusable screen-space geometry buffers.
  ///
  /// The projection result is written directly into [geometry], avoiding per-frame allocations during rendering.
  ///
  /// ---
  ///
  /// ## Parameters
  ///
  /// - [camera]: Camera used to convert world-space into view-space.
  /// - [mesh]: Runtime-oriented indexed geometry to project.
  /// - [size]: Target viewport size in screen-space pixels.
  /// - [worldMatrix]: World transformation applied to the mesh.
  /// - [geometry]: Mutable output geometry buffer.
  /// - [backfaceCulling]: Enables screen-space backface rejection.
  /// - [nearPlane]: Minimum visible depth threshold.
  static void project({
    required Camera camera,
    required Mesh mesh,
    required Size size,
    required Matrix4 worldMatrix,
    required Geometry2D geometry,
    bool backfaceCulling = true,
    double nearPlane = 0.01,
  }) {
    final projectedVertices = geometry.screenVertices;

    final vertexDepths = geometry.vertexDepths;
    final triDepths = geometry.triangleDepths;

    final triVisibility = geometry.triangleVisibility;

    final halfWidth = size.width * 0.5;
    final halfHeight = size.height * 0.5;

    final ppu = camera.pixelsPerUnit;

    final localPosition = Vector3.zero();
    final worldPosition = Vector3.zero();

    // The actual vertex projection to 2D screen-space happens here.
    for (int i = 0; i < mesh.vertexCount; i++) {
      final inputOffset = i * 5;
      final outputOffset = i * 2;

      localPosition.x = mesh.vertices[inputOffset];
      localPosition.y = mesh.vertices[inputOffset + 1];
      localPosition.z = mesh.vertices[inputOffset + 2];

      worldMatrix.transformed3(localPosition, worldPosition);

      final viewPosition = camera.toViewSpace(worldPosition);

      vertexDepths[i] = viewPosition.z;

      projectedVertices[outputOffset] = halfWidth + (viewPosition.x * ppu);
      projectedVertices[outputOffset + 1] = halfHeight - (viewPosition.y * ppu);
    }

    for (int t = 0; t < mesh.triCount; t++) {
      final base = t * 3;

      final i0 = mesh.indices[base];
      final i1 = mesh.indices[base + 1];
      final i2 = mesh.indices[base + 2];

      final z0 = vertexDepths[i0];
      final z1 = vertexDepths[i1];
      final z2 = vertexDepths[i2];

      // Skip triangles that are behind the camera.
      if (z0 <= nearPlane && z1 <= nearPlane && z2 <= nearPlane) {
        triVisibility[t] = 0;

        continue;
      }

      triDepths[t] = (z0 + z1 + z2) / 3.0;

      // Screen-space winding becomes unstable when crossing the near plane.
      //
      // In this case we skip backface culling.
      if (z0 <= nearPlane || z1 <= nearPlane || z2 <= nearPlane) {

        triVisibility[t] = 1;

        continue;
      }

      // TODO: Implement backface culling by Figure material.
      if (false) {
        final v0 = i0 * 2;
        final v1 = i1 * 2;
        final v2 = i2 * 2;

        final x0 = projectedVertices[v0];     final x1 = projectedVertices[v1];     final x2 = projectedVertices[v2];
        final y0 = projectedVertices[v0 + 1]; final y1 = projectedVertices[v1 + 1]; final y2 = projectedVertices[v2 + 1];

        final cross = (x1 - x0) * (y2 - y0) - (y1 - y0) * (x2 - x0);

        // Avoid division by zero, which can happen when the triangle is degenerate.
        if (cross.abs() < 1e-6) {
          triVisibility[t] = 0;

          continue;
        }

        // Flutter screen-space uses inverted Y, so clockwise winding is front-facing.
        triVisibility[t] = cross > 0.0 ? 1 : 0;
      }

      else {
        triVisibility[t] = 1;
      }
    }
  }
}
