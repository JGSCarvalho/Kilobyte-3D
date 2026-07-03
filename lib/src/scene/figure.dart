import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:vector_math/vector_math_64.dart';

import '../geometry/aabb.dart';
import '../geometry/face.dart';
import '../geometry/geometry_2d.dart';
import '../geometry/mesh.dart';

import '../scene/node.dart';

/// Represents a geometric figure within the scene graph.
///
/// A figure stores the geometric data required to render a visible shape in 3D space.
///
/// As a [Node], it inherits hierarchical transformations and can be positioned, rotated, and scaled relative to its
/// parent.
class Figure extends Node {

  /// Compact runtime-oriented mesh optimized for rendering. 
  /// 
  /// This mesh stores geometry using tightly packed typed buffers for fast projection and rasterization.
  /// 
  /// Unlike [faces], [vertices], and [texCoords], which preserve editable high-level geometry data, [mesh] is intended
  /// for direct consumption by the rendering pipeline.
  /// 
  /// The runtime mesh should be rebuilt whenever geometric topology or vertex data changes.
  Mesh mesh;

  /// The faces that define the surface topology of the figure.
  ///
  /// Each [Face] contains indices referencing vertices from the [vertices] collection.
  List<Face> faces;

  /// The texture coordinate buffer (UV map) for the geometry.
  ///
  /// Each [Vector2] represents a normalized position in texture space (typically ranging from `0.0` to `1.0`) where:
  ///
  /// - `x` corresponds to the horizontal texture axis (U);
  /// - `y` corresponds to the vertical texture axis (V), pre-inverted to align with Flutter's top-left canvas origin.
  ///
  /// Projected faces reference indices within this list to correctly map image textures onto 2D screen fragments.
  List<Vector2> texCoords;

  /// The vertices that define the geometry of the figure.
  ///
  /// Vertices are expressed in the figure's local coordinate space before any world-space transformations are applied.
  List<Vector3> vertices;

  /// The texture applied to the surface of the figure.
  /// 
  /// If no texture is provided, the figure will be rendered as a wireframe.
  ui.Image? texture;

  /// The blend mode used when rendering the figure.
  /// 
  /// Defaults to [ui.BlendMode.srcOver].
  ui.BlendMode blendMode;

  Figure._({
    required this.faces,
    required this.texCoords,
    required this.vertices,
    required this.mesh,
    this.blendMode = ui.BlendMode.srcOver,
    this.texture,
  });

  factory Figure({
    required List<Face> faces,
    required List<Vector2> texCoords,
    required List<Vector3> vertices,
    ui.Image? texture,
    ui.BlendMode blendMode = ui.BlendMode.srcOver,
  }) {
    return Figure._(
      faces: faces,
      texCoords: texCoords,
      vertices: vertices,
      mesh: Mesh.fromFigure(faces, texCoords, vertices),
      texture: texture,
      blendMode: blendMode,
    );
  }

  late Geometry2D geometry = Geometry2D.allocate(
    vertexCount: mesh.vertexCount,
    triCount: mesh.triCount,
  );

  ui.Paint? _paint;

  ui.Paint get paint {
    return _paint ??= ui.Paint()
      ..shader = ui.ImageShader(
        texture!,
        ui.TileMode.repeated,
        ui.TileMode.repeated,
        Float64List.fromList([
          1, 0, 0, 0,
          0, 1, 0, 0,
          0, 0, 1, 0,
          0, 0, 0, 1,
        ])
      )
      ..blendMode = blendMode;
  }

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
  void center([bool keepWorldPosition = false]) {
    if (vertices.isEmpty) return;

    double minX =  double.infinity; double minY =  double.infinity; double minZ =  double.infinity;
    double maxX = -double.infinity; double maxY = -double.infinity; double maxZ = -double.infinity;

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
  /// ``` txt
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
    if (depth <= 0) return;

    for (int i = 0; i < depth; i++) {
      final subdividedVertices = List<Vector3>.from(vertices);
      final subdividedTexCoords = List<Vector2>.from(texCoords);
      final subdividedFaces = <Face> [];
  
      for (final face in faces) {
        if (face.vIndices.length != 3) {
          subdividedFaces.add(face);
  
          continue;
        }
  
        final vertex0 = face.vIndices[0]; final texCoord0 = face.vtIndices[0];
        final vertex1 = face.vIndices[1]; final texCoord1 = face.vtIndices[1];
        final vertex2 = face.vIndices[2]; final texCoord2 = face.vtIndices[2];
  
        subdividedVertices.add((vertices[vertex0] + vertices[vertex1]) * 0.5); final vertexMidpoint0 = subdividedVertices.length - 1;
        subdividedVertices.add((vertices[vertex1] + vertices[vertex2]) * 0.5); final vertexMidpoint1 = subdividedVertices.length - 1;
        subdividedVertices.add((vertices[vertex2] + vertices[vertex0]) * 0.5); final vertexMidpoint2 = subdividedVertices.length - 1;
  
        subdividedTexCoords.add((texCoords[texCoord0] + texCoords[texCoord1]) * 0.5); final texCoordMidpoint0 = subdividedTexCoords.length - 1;
        subdividedTexCoords.add((texCoords[texCoord1] + texCoords[texCoord2]) * 0.5); final texCoordMidpoint1 = subdividedTexCoords.length - 1;
        subdividedTexCoords.add((texCoords[texCoord2] + texCoords[texCoord0]) * 0.5); final texCoordMidpoint2 = subdividedTexCoords.length - 1;
  
        subdividedFaces.addAll([
          Face(
            vIndices: [vertex0, vertexMidpoint0, vertexMidpoint2],
            vtIndices: [texCoord0, texCoordMidpoint0, texCoordMidpoint2],
          ),
          Face(
            vIndices: [vertexMidpoint0, vertex1, vertexMidpoint1],
            vtIndices: [texCoordMidpoint0, texCoord1, texCoordMidpoint1],
          ),
          Face(
            vIndices: [vertexMidpoint2, vertexMidpoint1, vertex2],
            vtIndices: [texCoordMidpoint2, texCoordMidpoint1, texCoord2],
          ),
          Face(
            vIndices: [vertexMidpoint0, vertexMidpoint1, vertexMidpoint2],
            vtIndices: [texCoordMidpoint0, texCoordMidpoint1, texCoordMidpoint2],
          ),
        ]);
      }

      vertices = subdividedVertices;
      texCoords = subdividedTexCoords;
      faces = subdividedFaces;
      mesh = Mesh.fromFigure(faces, texCoords, vertices);
    }
  }

  /// Subdivides triangle geometry using shared-edge midpoint caching to reduce duplicate vertices and preserve mesh
  /// continuity.
  ///
  /// Unlike [subdivide], this method performs topology-aware subdivision by reusing midpoint vertices across adjacent
  /// triangles that share the same edge.
  ///
  /// This significantly reduces vertex duplication, lowers memory overhead, improves vertex cache locality, and
  /// prevents cracks between neighboring subdivided faces.
  ///
  /// UV coordinates are subdivided using the same shared-edge interpolation strategy, preserving texture continuity
  /// across the mesh surface.
  ///
  /// ---
  ///
  /// ### Algorithm:
  ///
  /// Each triangle is subdivided into four smaller triangles using midpoint interpolation:
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
  /// - `m1` is the midpoint of edge `(v0, v1)`;
  /// - `m2` is the midpoint of edge `(v1, v2)`;
  /// - `m3` is the midpoint of edge `(v2, v0)`.
  ///
  /// This produces four new triangles:
  ///
  /// ``` txt
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
  /// - Complexity grows approximately as O(4^n), where `n` is the subdivision depth.
  /// - Compared to [subdivide], this method produces significantly fewer duplicated vertices.
  /// - Midpoints are cached using edge hashes so that adjacent triangles sharing the same edge also share the same
  /// generated midpoint vertex, avoiding generating duplicated vertices for neighboring faces and ensures
  /// topological consistency across the subdivided mesh.
  /// - Faces that collapse into zero-area triangles due to duplicated indices are automatically discarded during
  /// subdivision.
  void smartSubdivide([int depth = 1]) {
    if (depth <= 0) return;

    /// Generates a deterministic hash key for an undirected edge.
    ///
    /// The two vertex indices are normalized into ascending order before the hash is constructed, ensuring that edges
    /// `(a, b)` and `(b, a)` produce the exact same key.
    ///
    /// This allows shared triangle edges to consistently reuse the same cached midpoint vertices and UV coordinates
    /// during subdivision.
    ///
    /// ---
    ///
    /// ### Parameters:
    ///
    /// - [a]: Index of the first vertex.
    /// - [b]: Index of the second vertex.
    ///
    /// ---
    ///
    /// ### Notes:
    ///
    /// - This implementation assumes vertex indices remain within 16-bit range (`0 - 65535`).
    /// - The edge is treated as undirected, meaning edge winding order does not affect the generated hash.
    int edgeKey(int a, int b) {
      final minIndex = math.min(a, b);
      final maxIndex = math.max(a, b);

      return (minIndex << 16) | maxIndex;
    }

    for (int i = 0; i < depth; i++) {
      final vertexMidpointCache = <int, int> {};
      final texCoordsMidpointCache = <int, int> {};

      final subdividedVertices = List<Vector3>.from(vertices);
      final subdividedTexCoords = List<Vector2>.from(texCoords);
      final subdividedFaces = <Face> [];

      for (final face in faces) {
        if (face.vIndices.length != 3) {
          subdividedFaces.add(face);

          continue;
        }

        final vertex0 = face.vIndices[0]; final texCoord0 = face.vtIndices[0];
        final vertex1 = face.vIndices[1]; final texCoord1 = face.vtIndices[1];
        final vertex2 = face.vIndices[2]; final texCoord2 = face.vtIndices[2];

        /// Retrieves or creates the shared midpoint vertex for an edge.
        ///
        /// The edge is identified using a deterministic hash generated from the two vertex indices, ensuring that
        /// adjacent triangles referencing the same edge reuse the exact same midpoint vertex.
        ///
        /// If the midpoint already exists in the cache, its index is returned immediately.
        ///
        /// Otherwise, a new midpoint position is generated through linear interpolation and appended to the subdivision
        /// vertex buffer.
        ///
        /// ---
        ///
        /// ### Parameters:
        ///
        /// - [a]: Index of the first vertex.
        /// - [b]: Index of the second vertex.
        int getMidpointVertex(int a, int b) {
          final key = edgeKey(a, b);

          return vertexMidpointCache.putIfAbsent(key, () {
            subdividedVertices.add((subdividedVertices[a] + subdividedVertices[b]) * 0.5);

            return subdividedVertices.length - 1;
          });
        }

        /// Retrieves or creates the shared midpoint UV coordinate for an edge.
        ///
        /// Similar to vertex, UV midpoint coordinates are cached using the edge hash so neighboring subdivided
        /// triangles preserve continuous texture mapping across shared edges.
        ///
        /// If a midpoint UV already exists for the edge, its index is reused.
        ///
        /// Otherwise, a new UV coordinate is generated using linear interpolation between the two source texture
        /// coordinates.
        ///
        /// ---
        ///
        /// ### Parameters:
        ///
        /// - [a]: Index of the first texture coordinate.
        /// - [b]: Index of the second texture coordinate.
        int getMidpointTexCoord(int a, int b) {
          final key = edgeKey(a, b);

          return texCoordsMidpointCache.putIfAbsent(
            key,
            () {
              subdividedTexCoords.add((subdividedTexCoords[a] + subdividedTexCoords[b]) * 0.5);

              return subdividedTexCoords.length - 1;
            }
          );
        }

        final vertexMidpoint0 = getMidpointVertex(vertex0, vertex1); final texCoordMidpoint0 = getMidpointTexCoord(texCoord0, texCoord1);
        final vertexMidpoint1 = getMidpointVertex(vertex1, vertex2); final texCoordMidpoint1 = getMidpointTexCoord(texCoord1, texCoord2);
        final vertexMidpoint2 = getMidpointVertex(vertex2, vertex0); final texCoordMidpoint2 = getMidpointTexCoord(texCoord2, texCoord0);

        final newFaces = [
          Face(
            vIndices: [vertex0, vertexMidpoint0, vertexMidpoint2],
            vtIndices: [texCoord0, texCoordMidpoint0, texCoordMidpoint2]
          ),
          Face(
            vIndices: [vertexMidpoint0, vertex1, vertexMidpoint1],
            vtIndices: [texCoordMidpoint0, texCoord1, texCoordMidpoint1],
          ),
          Face(
            vIndices: [vertexMidpoint2, vertexMidpoint1, vertex2],
            vtIndices: [texCoordMidpoint2, texCoordMidpoint1, texCoord2],
          ),
          Face(
            vIndices: [vertexMidpoint0, vertexMidpoint1, vertexMidpoint2],
            vtIndices: [texCoordMidpoint0, texCoordMidpoint1, texCoordMidpoint2],
          ),
        ];

        // Cleans up faces that collapse to zero-area triangles (degenerate ones).
        for (final f in newFaces) {
          if (f.vIndices[0] != f.vIndices[1] && f.vIndices[1] != f.vIndices[2] && f.vIndices[0] != f.vIndices[2]) {
            subdividedFaces.add(f);
          }
        }
      }

      vertices = subdividedVertices;
      texCoords = subdividedTexCoords;
      faces = subdividedFaces;
      mesh = Mesh.fromFigure(faces, texCoords, vertices);
    }
  }
}
