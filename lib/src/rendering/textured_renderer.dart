import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../geometry/geometry_2d.dart';
import '../geometry/mesh.dart';

abstract final class TexturedRenderer {

  static void render({
    required Canvas canvas,
    required Geometry2D geometry,
    required Mesh mesh,
    required Uint16List tris,
    required ui.Paint paint,
  }) {
    final positions = mesh.cachePositions;

    for (int i = 0; i < mesh.vertexCount; i++) {
      final source = i * 2;

      positions[i] = Offset(
        geometry.screenVertices[source],
        geometry.screenVertices[source + 1],
      );
    }

    final ui.Vertices vertices = ui.Vertices(
      ui.VertexMode.triangles,
      positions,
      textureCoordinates: mesh.cacheTexCoords,
      indices: tris,
    );

    canvas.drawVertices(vertices, paint.blendMode, paint);
  }
}
