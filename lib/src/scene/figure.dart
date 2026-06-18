import 'dart:ui' as ui;

import 'package:vector_math/vector_math_64.dart';

import '../geometry/face.dart';

import '../scene/node.dart';

/// Represents a geometric figure within the scene graph.
///
/// A [Figure] stores the geometric data required to render a visible shape in 3D space.
///
/// As a [Node], it inherits hierarchical transformations and can be positioned, rotated, and scaled relative to its
/// parent.
class Figure extends Node {

  /// The faces that define the surface topology of the figure.
  ///
  /// Each [Face] contains indices referencing vertices from the [vertices] collection.
  final List<Face> faces;

  ui.Image? texture;

  /// Optional texture coordinates associated with the geometry.
  ///
  /// Each [Vector2] represents a UV coordinate in texture space.
  final List<Vector2>? uvs;

  /// The vertices that define the geometry of the figure.
  ///
  /// Vertices are expressed in the figure's local coordinate space before any world-space transformations are applied.
  final List<Vector3> vertices;

  Figure({
    super.transform,
    required this.vertices,
    required this.faces,
    this.texture,
    this.uvs,
  });

  /// Re-centers the figure's pivot using the center of its Axis-Aligned Bounding Box (AABB).
  ///
  /// All vertices are translated so that the AABB center becomes the local origin (0, 0, 0).
  ///
  /// To preserve the figure's visual position in world space, the same offset is applied to the node's local position.
  void centerPivot() {
    if (vertices.isEmpty) return;

    double minX =   double.infinity; double minY =   double.infinity; double minZ =   double.infinity;
    double maxX = - double.infinity; double maxY = - double.infinity; double maxZ = - double.infinity;

    for (final vertex in vertices) {
      if (vertex.x < minX) minX = vertex.x;
      if (vertex.x > maxX) maxX = vertex.x;

      if (vertex.y < minY) minY = vertex.y;
      if (vertex.y > maxY) maxY = vertex.y;

      if (vertex.z < minZ) minZ = vertex.z;
      if (vertex.z > maxZ) maxZ = vertex.z;
    }

    final center = Vector3((minX + maxX) / 2.0, (minY + maxY) / 2.0, (minZ + maxZ) / 2.0);

    // Move the geometry so the AABB center becomes the local origin.
    for (final vertex in vertices) {
      vertex.sub(center);
    }

    // Preserve the figure's world-space position.
    final translation = transform.translation..add(center);

    transform.setTranslation(translation);
  }
}
