import 'dart:typed_data';
import 'dart:ui';

import 'package:vector_math/vector_math_64.dart';

import '../geometry/face.dart';

import '../scene/figure.dart';

/// A compact runtime-oriented indexed mesh optimized for software rendering.
///
/// [Mesh] stores geometry using tightly packed typed buffers designed for fast sequential access during projection, 
/// sorting, clipping, and rasterization.
///
/// Unlike high-level scene representations such as [Figure], this structure is intended to be consumed directly by the
/// rendering pipeline with minimal allocation overhead.
class Mesh {

  /// Packed interleaved vertex buffer.
  ///
  /// Every vertex occupies 5 consecutive `float32` values: `[X, Y, Z, U, V]`.
  final Float32List vertices;

  /// Indexed triangle buffer.
  ///
  /// Every group of 3 indices defines one triangle: `[i0, i1, i2]`.
  final Uint16List indices;

  const Mesh({
    required this.vertices,
    required this.indices,
    required this.cacheTexCoords,
    required this.cachePositions,
  });

  final List<Offset> cacheTexCoords;
  final List<Offset> cachePositions;

  /// Builds a runtime-optimized indexed mesh from high-level figure geometry.
  ///
  /// This constructor converts object-oriented geometry data into compact typed buffers suitable for real-time
  /// rendering.
  ///
  /// ---
  ///
  /// ## Parameters
  ///
  /// - [faces]: Triangle topology definitions.
  /// - [texCoords]: Texture coordinate buffer.
  /// - [vertices]: Local-space vertex positions.
  factory Mesh.fromFigure(
    List<Face> faces,
    List<Vector2> texCoords,
    List<Vector3> vertices,
  ) {
    final unrolledVertices = <double> [];
    final unrolledIndices = <int> [];

    // Cache used to deduplicate identical (position, UV) pairs.
    final uniqueVertexCache = <String, int> {};

    for (final face in faces) {
      for (int i = 0; i < 3; i++) {
        final vertexIndex = face.vIndices[i];
        final texCoordIndex = face.vtIndices[i];

        final cacheKey = '${vertexIndex}_$texCoordIndex';

        if (!uniqueVertexCache.containsKey(cacheKey)) {
          final newIndex = uniqueVertexCache.length;

          uniqueVertexCache[cacheKey] = newIndex;

          final vertex = vertices[vertexIndex];
          final texCoord = texCoords[texCoordIndex];

          // Interleaved vertex layout: `[X, Y, Z, U, V]`.
          unrolledVertices.addAll([vertex.x, vertex.y, vertex.z, texCoord.x, texCoord.y]);
        }

        unrolledIndices.add(uniqueVertexCache[cacheKey]!);
      }
    }

    final vBuffer = Float32List.fromList(unrolledVertices);
    final iBuffer = Uint16List.fromList(unrolledIndices);

    return Mesh(
      vertices: vBuffer,
      indices: iBuffer,
      cacheTexCoords: List.generate(
        vBuffer.length ~/ 5,
        (i) => Offset(vBuffer[i * 5 + 3], vBuffer[i * 5 + 4]),
        growable: false,
      ),
      cachePositions: List.generate(
        vBuffer.length ~/ 5,
        (_) => Offset.zero,
        growable: false,
      ),
    );
  }

  /// Total number of packed runtime vertices.
  ///
  /// Since every vertex occupies 5 float components (i.e. `[X, Y, Z, U, V]`), the vertex count is derived by dividing
  /// the buffer length by 5.
  int get vertexCount => vertices.length ~/ 5;

  /// Total number of triangles stored in the mesh.
  ///
  /// Since triangles are stored as indexed triplets (i.e. `[i0, i1, i2]`), the triangle count is derived by dividing
  /// the index buffer length by 3.
  int get triCount => indices.length ~/ 3;
}
