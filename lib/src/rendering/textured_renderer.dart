import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import '../geometry/render_geometry.dart';

/// Rasterizes geometry using textured triangle rendering.
///
/// This renderer converts indexed geometry into GPU-friendly vertex buffers,
/// mapping UV coordinates into texture space before issuing a draw call through
/// Flutter's [Canvas.drawVertices].
abstract final class TexturedRenderer {

  /// Renders textured polygon geometry.
  ///
  /// Supports triangles, quads, and general polygons by performing on-the-fly 
  /// fan triangulation. Safely handles missing or out-of-bounds UV/vertex indices.
  static void draw({
    required Canvas canvas,
    required RenderGeometry geometry,
    required List<Vector2> uvs,
    required ui.Image texture,
    required Paint paint,
  }) {
    final points = geometry.vertices;
    final faces = geometry.faces;

    if (points.isEmpty || faces.isEmpty || uvs.isEmpty) {
      return;
    }

    final positions = <Offset> [];
    final textureCoordinates = <Offset> [];
    final indices = <int> [];

    // Maps a unique (vertexIndex, uvIndex) pair to a runtime vertex buffer index.
    final indexMap = <String, int>{};

    final texWidth = texture.width.toDouble();
    final texHeight = texture.height.toDouble();

    for (final face in faces) {
      final numVertices = face.vertexIndices.length;
      
      // A valid polygon face needs at least 3 vertices
      if (numVertices < 3) continue;

      // Helper function to process and push a vertex safely into the Flutter buffers
      void processVertex(int localIndex) {
        if (localIndex >= face.vertexIndices.length) return;

        final vertexIndex = face.vertexIndices[localIndex];
        
        // Defend against incomplete UV streams within the face definition
        final uvIndex = (localIndex < face.uvIndices.length) 
            ? face.uvIndices[localIndex] 
            : 0;

        // CRITICAL PROTECTION 1: Prevent RangeError on global vertices buffer
        if (vertexIndex < 0 || vertexIndex >= points.length) return;

        final key = '$vertexIndex:$uvIndex';

        if (!indexMap.containsKey(key)) {
          indexMap[key] = positions.length;

          positions.add(points[vertexIndex].position);

          // CRITICAL PROTECTION 2: Prevent RangeError on global UV buffer
          final uv = (uvIndex >= 0 && uvIndex < uvs.length)
              ? uvs[uvIndex]
              : Vector2.zero();

          // Convert normalized UV coordinates into texture pixel coordinates.
          // The V axis is flipped to match Flutter's top-left coordinate system.
          textureCoordinates.add(
            Offset(
              uv.x * texWidth,
              uv.y * texHeight,
            ),
          );
        }

        indices.add(indexMap[key]!);
      }

      // Fan Triangulation: Decomposes any n-gon (Triangles = 1 iteration, Quads = 2 iterations)
      // into a series of independent triangles perfectly aligned for the GPU buffer.
      for (int i = 1; i < numVertices - 1; i++) {
        processVertex(0);
        processVertex(i);
        processVertex(i + 1);
      }
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
      ui.BlendMode.srcOver,
      paint,
    );
  }
}
