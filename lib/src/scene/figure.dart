import 'dart:ui' as ui;

import 'package:vector_math/vector_math_64.dart';

import '../geometry/aabb.dart';
import '../geometry/face.dart';

import '../scene/node.dart';

/// Represents a geometric figure within the scene graph.
///
/// A figure stores the geometric data required to render a visible shape in 3D space.
///
/// As a [Node], it inherits hierarchical transformations and can be positioned, rotated, and scaled relative to its
/// parent.
class Figure extends Node {

  /// The faces that define the surface topology of the figure.
  ///
  /// Each [Face] contains indices referencing vertices from the [vertices] collection.
  List<Face> faces;

  /// The diffuse texture applied to the surface of the figure.
  ui.Image? texture;

  /// The texture coordinate buffer (UV map) for the geometry.
  ///
  /// Each [Vector2] represents a normalized position in texture space (typically ranging from `0.0` to `1.0`) where:
  ///
  /// - `x` corresponds to the horizontal texture axis (U);
  /// - `y` corresponds to the vertical texture axis (V), pre-inverted to align with Flutter's top-left canvas origin.
  ///
  /// Projected faces reference indices within this list to correctly map image textures onto 2D screen fragments.
  List<Vector2> uvs;

  /// The vertices that define the geometry of the figure.
  ///
  /// Vertices are expressed in the figure's local coordinate space before any world-space transformations are applied.
  List<Vector3> vertices;

  Figure({
    super.transform,
    required this.vertices,
    required this.faces,
    required this.uvs,
    this.texture,
  });

  /// Computes the local-space Axis-Aligned Bounding Box (AABB) of the figure.
  ///
  /// The returned bounds are derived directly from the figure's vertex positions without applying any node or parent
  /// transformations.
  ///
  /// This means the resulting AABB is expressed entirely in the figure's local coordinate space.
  AABB get bounds {
    if (vertices.isEmpty) return AABB.zero();

    double minX = double.infinity; double maxX = -double.infinity;
    double minY = double.infinity; double maxY = -double.infinity;
    double minZ = double.infinity; double maxZ = -double.infinity;

    for (final vertex in vertices) {
      if (vertex.x < minX) minX = vertex.x;
      if (vertex.y < minY) minY = vertex.y;
      if (vertex.z < minZ) minZ = vertex.z;

      if (vertex.x > maxX) maxX = vertex.x;
      if (vertex.y > maxY) maxY = vertex.y;
      if (vertex.z > maxZ) maxZ = vertex.z;
    }

    return AABB(
      min: Vector3(minX, minY, minZ),
      max: Vector3(maxX, maxY, maxZ),
    );
  }

  /// Re-centers the figure's local pivot using the center of its Axis-Aligned Bounding Box (AABB). All vertices are
  /// translated so that the AABB center becomes the local origin `(0, 0, 0)`.
  /// 
  /// Optionally, the figure's local translation can be compensated to preserve its visual position in world space.
  /// 
  /// ---
  /// 
  /// ### Parameters:
  /// 
  /// - [keepWorldPosition]: When enabled, the figure's local translation is adjusted by the same pivot offset so the
  /// figure remains visually stationary in world space.
  void centerPivot([bool keepWorldPosition = false]) {
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

    if (keepWorldPosition) {
      final translation = transform.translation..add(center);

      transform.setTranslation(translation);
    }
  }

  /// Subdivides triangle geometry to increase mesh density and reduce rendering artifacts.
  ///
  /// This operation performs a uniform mesh refinement by splitting each triangle into four smaller triangles using
  /// midpoint subdivision on both vertex positions and UV coordinates.
  ///
  /// The process preserves surface topology while increasing geometric resolution.
  /// 
  /// UV coordinates are subdivided using linear interpolation between corresponding triangle UVs, maintaining texture
  /// continuity across subdivided faces.
  ///
  /// ---
  ///
  /// ### Algorithm:
  ///
  /// Each triangle is split as follows:
  ///
  /// ``` txt
  ///        v0
  ///       /  \
  ///      m2--m1
  ///     / \  / \
  ///   v2---m3---v1
  /// ```
  ///
  /// Where:
  /// 
  /// - `mA` is the midpoint of (v0, v1).
  /// - `mB` is the midpoint of (v1, v2).
  /// - `mC` is the midpoint of (v2, v0).
  ///
  /// This produces 4 new triangles:
  /// 
  /// ```txt
  ///        v0                  m1                  m2                  m1
  ///       /  \                /  \                /  \                /  \
  ///      /    \              /    \              /    \              /    \
  ///    m2------m1          m2------v1          v2------m3          m2------m3
  /// ```
  ///
  /// ---
  ///
  /// ### Parameters:
  ///
  /// - [depth]: Number of subdivision iterations to apply.
  ///
  /// ---
  ///
  /// ### Notes:
  ///
  /// - Complexity grows as O(4^n), where n is the subdivision depth, use carefully.
  void subdivide([int depth = 1]) {
    assert(depth > 0 || depth <= 3, 'Subdivision depth must be greater than 0 and less than or equal to 3!');

    for (int i = 0; i < depth; i++) {
      final subVertices = List<Vector3>.from(vertices);
      final subUVs = List<Vector2>.from(uvs);
      final subFaces = <Face> [];
  
      for (final face in faces) {
        if (face.vIndices.length != 3) {
          subFaces.add(face);
  
          continue;
        }
  
        final p0 = face.vIndices[0];
        final p1 = face.vIndices[1];
        final p2 = face.vIndices[2];
  
        final uv0 = face.vtIndices[0];
        final uv1 = face.vtIndices[1];
        final uv2 = face.vtIndices[2];
  
        subVertices.add((vertices[p0] + vertices[p1]) * 0.5);
        final pMidpoint0 = subVertices.length - 1;
  
        subVertices.add((vertices[p1] + vertices[p2]) * 0.5);
        final pMidpoint1 = subVertices.length - 1;
  
        subVertices.add((vertices[p2] + vertices[p0]) * 0.5);
        final pMidpoint2 = subVertices.length - 1;
  
        subUVs.add((uvs[uv0] + uvs[uv1]) * 0.5);
        final uvMidpoint0 = subUVs.length - 1;
  
        subUVs.add((uvs[uv1] + uvs[uv2]) * 0.5);
        final uvMidpoint1 = subUVs.length - 1;
  
        subUVs.add((uvs[uv2] + uvs[uv0]) * 0.5);
        final uvMidpoint2 = subUVs.length - 1;
  
        subFaces.addAll([
          Face(
            vIndices: [p0, pMidpoint0, pMidpoint2],
            vtIndices: [uv0, uvMidpoint0, uvMidpoint2],
          ),
          Face(
            vIndices: [pMidpoint0, p1, pMidpoint1],
            vtIndices: [uvMidpoint0, uv1, uvMidpoint1],
          ),
          Face(
            vIndices: [pMidpoint2, pMidpoint1, p2],
            vtIndices: [uvMidpoint2, uvMidpoint1, uv2],
          ),
          Face(
            vIndices: [pMidpoint0, pMidpoint1, pMidpoint2],
            vtIndices: [uvMidpoint0, uvMidpoint1, uvMidpoint2],
          ),
        ]);
      }

      vertices = subVertices;
      uvs = subUVs;
      faces = subFaces;
    }
  }
}
