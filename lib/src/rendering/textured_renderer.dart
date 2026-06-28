import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import '../geometry/projected_face.dart';
import '../geometry/projected_geometry.dart';

/// Rasterizes geometry using textured triangle rendering.
///
/// This renderer converts indexed geometry into GPU vertex buffers, mapping UV coordinates into texture space before
/// issuing a draw call through Flutter's [Canvas.drawVertices].
abstract final class TexturedRenderer {

  /// Renders a single projected polygon face.
  static void draw({
    required Canvas canvas,
    required ProjectedGeometry geometry,
    required ProjectedFace face,
    required List<Vector2> texCoords,
    required ui.Image texture,
    required Paint paint,
  }) {
    final vpVertices = geometry.vertices;

    final positions = <Offset> [];
    final textureCoordinates = <Offset> [];
    final indices = <int> [];

    final indexMap = <String, int> {};

    final texWidth = texture.width.toDouble();
    final texHeight = texture.height.toDouble();

    final polygon = face.face;
    final nVertices = polygon.vIndices.length;

    if (nVertices < 3) return;

    void processVertex(int localIndex) {
      if (localIndex >= polygon.vIndices.length) {
        return;
      }

      final vertexIndex = polygon.vIndices[localIndex];

      final uvIndex = (localIndex < polygon.vtIndices.length)
          ? polygon.vtIndices[localIndex]
          : 0;

      if (vertexIndex < 0 || vertexIndex >= vpVertices.length) {
        return;
      }

      final key = '$vertexIndex:$uvIndex';

      if (!indexMap.containsKey(key)) {
        indexMap[key] = positions.length;

        positions.add(
          vpVertices[vertexIndex].position,
        );

        final uv = (uvIndex >= 0 && uvIndex < texCoords.length)
            ? texCoords[uvIndex]
            : Vector2.zero();

        textureCoordinates.add(
          Offset(
            uv.x * texWidth,
            uv.y * texHeight,
          ),
        );
      }

      indices.add(indexMap[key]!);
    }

    // Fan triangulation.
    for (int i = 1; i < nVertices - 1; i++) {
      processVertex(0);
      processVertex(i);
      processVertex(i + 1);
    }

    if (positions.isEmpty || indices.isEmpty) {
      return;
    }

    final vertices = ui.Vertices(
      ui.VertexMode.triangles,
      positions,
      textureCoordinates: textureCoordinates,
      indices: indices,
    );

    canvas.drawVertices(
      vertices,
      paint.blendMode,
      paint,
    );
  }
}
