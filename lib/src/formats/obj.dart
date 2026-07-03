import 'dart:developer';

import 'package:vector_math/vector_math_64.dart';

import '../geometry/face.dart';

import '../scene/figure.dart';

import '../transform/transform.dart';

/// Wavefront OBJ parser.
abstract final class OBJ {

  /// Parses raw OBJ file content into a renderable [Figure].
  ///
  /// ---
  ///
  /// ### Parameters:
  ///
  /// - [content]: Raw OBJ file string.
  ///
  /// ---
  ///
  /// ### Throws:
  ///
  /// - [FormatException] if numeric parsing fails.
  static Figure parse(String content) {
    final vertices = <Vector3> [];
    final faces = <Face> [];
    final normals = <Vector3> [];

    List<Vector2> uvs = [];

    final lines = content.split('\n');

    for (final rawLine in lines) {
      final line = rawLine.trim();

      // Skips empty spaces and comment headers early according to the OBJ specification.
      if (line.isEmpty || line.startsWith('#')) continue;

      if (line.startsWith('v ')) {
        vertices.add(_OBJ.vertex(line));
      }
      else if (line.startsWith('vn ')) {
        normals.add(_OBJ.normal(line));
      }
      else if (line.startsWith('vt ')) {
        uvs.add(_OBJ.uv(line));
      }
      else if (line.startsWith('f ')) {
        faces.addAll(_OBJ.faces(line));
      }
    }

    if (uvs.isEmpty) {
      log('OBJ missing UVs, generating zeroed UV buffer and mapping faces...');

      uvs = List<Vector2>.generate(vertices.length, (_) => Vector2.zero());
      
      for (int i = 0; i < faces.length; i++) {
        if (faces[i].vtIndices.isEmpty) {
          faces[i] = Face(
            vIndices: faces[i].vIndices,
            vtIndices: List<int>.from(faces[i].vIndices), // Reuse vertex indices as UV indices.
          );
        }
      }
    }

    return Figure(
      vertices: vertices,
      faces: faces,
      texCoords: uvs,
    );
  }
}

/// Internal Wavefront OBJ specification decoder.
///
/// This class implements a strict parser for the [Wavefront OBJ](https://paulbourke.net/dataformats/obj/) format,
/// which is an external, text-based 3D geometry interchange specification widely used in modeling tools such as
/// Blender, Maya, and 3ds Max.
abstract final class _OBJ {

  /// Shared whitespace tokenizer used to minimize allocation overhead during large file parsing operations.
  static final RegExp _whitespace = RegExp(r'\s+');

  /// Parses a vertex position line (`v`).
  ///
  /// ---
  ///
  /// ### Format: `v x y z`
  ///
  /// ``` txt
  ///       y
  ///       ↑
  ///       │
  ///       │
  ///       ●──────→ x
  ///      /
  ///     /
  ///    z
  /// ```
  ///
  /// Defines a geometric position in 3D space.
  static Vector3 vertex(String line) {
    final parts = line.split(_whitespace);

    return Vector3(double.parse(parts[1]), double.parse(parts[2]), double.parse(parts[3]));
  }

  /// Parses a vertex normal line (`vn`).
  ///
  /// ---
  ///
  /// ### Format: `vn x y z`
  ///
  /// ```txt
  ///         surface
  ///    ─────────────────
  ///            ↑
  ///            │ normal
  ///            │
  ///            ●
  /// ```
  ///
  /// Defines a surface direction vector typically used for lighting calculations.
  static Vector3 normal(String line) {
    final parts = line.split(_whitespace);

    return Vector3(double.parse(parts[1]), double.parse(parts[2]), double.parse(parts[3]));
  }

  /// Parses a texture coordinate line (`vt`).
  ///
  /// ---
  ///
  /// ### Format: `vt u v`
  ///
  /// ``` txt
  /// (0,0) ┌───────────→ U
  ///       │
  ///       │
  ///       │
  ///       ↓
  ///       V
  /// ```
  ///
  /// ---
  ///
  /// ### Notes:
  ///
  /// - The V coordinate is inverted to match Flutter's top-left coordinate system.
  static Vector2 uv(String line) {
    final parts = line.split(_whitespace);

    final u = double.parse(parts[1]);
    final v = 1.0 - double.parse(parts[2]);

    return Vector2(u, v);
  }

  /// Parses a polygon face definition line (`f`).
  ///
  /// ---
  ///
  /// ### Formats:
  ///
  /// Triangle: `f v1/vt1/vn1 v2/vt2/vn2 v3/vt3/vn3`
  /// 
  /// ``` txt
  ///         v1
  ///        /  \
  ///       /    \
  ///     v2------v3
  /// ```
  ///
  /// Quadrilateral: `f v1 v2 v3 v4`
  /// 
  /// ``` txt
  ///    v1--------v2
  ///    |          |
  ///    |          |
  ///    v4--------v3
  /// ```
  ///
  /// N-gon: `f v1 v2 v3 v4 v5 ...`
  /// 
  /// ``` txt
  ///         v1
  ///      .-''''-.
  ///    v6        v2
  ///    |          |
  ///    v5        v3
  ///      '-.__.-'
  ///         v4
  /// ```
  /// 
  /// ---
  ///
  /// ### Notes:
  ///
  /// - Vertex indices are converted from OBJ 1-based indexing to 0-based runtime indexing.
  /// - UV indices are preserved independently from vertex indices.
  /// - Faces containing more than 3 vertices are automatically triangulated using a triangle-fan algorithm.
  /// - Invalid faces containing fewer than 3 vertices are ignored.
  static List<Face> faces(String line) {
    final parts = line.split(_whitespace).sublist(1);

    final vIndices = <int> [];
    final vtIndices = <int> [];

    for (final part in parts) {
      if (part.isEmpty) continue;

      final tokens = part.split('/');

      vIndices.add(int.parse(tokens[0]) - 1);

      if (tokens.length > 1 && tokens[1].isNotEmpty) {
        vtIndices.add(int.parse(tokens[1]) - 1);
      }
    }

    // Skip invalid faces.
    if (vIndices.length < 3) return const [];

    // Perfect triangle, this skips the triangle-fan algorithm.
    if (vIndices.length == 3) {
      final triangle = Face(
        vIndices: vIndices,
        vtIndices: vtIndices,
      );

      return [triangle];
    }

    return _triangulate(vIndices, vtIndices);
  }

  /// Triangulates polygon geometry using the triangle-fan algorithm.
  ///
  /// The algorithm converts an arbitrary N-gon into `(N - 2)` triangles by reusing the first polygon vertex as a
  /// shared pivot.
  ///
  /// ---
  ///
  /// ### Example:
  ///
  /// ```txt
  ///         v0
  ///      .-''''-.
  ///    v5        v1
  ///    |          |
  ///    v4        v2
  ///      '-.__.-'
  ///         v3
  /// ```
  ///
  /// The N-gon above (`f v0 v1 v2 v3 v4 v5`) is decomposed into 4 triangles:
  ///
  /// ```txt
  ///        v0                  v0                  v0                  v0
  ///       /  \                /  \                /  \                /  \
  ///      /    \              /    \              /    \              /    \
  ///    v1------v2          v2------v3          v3------v4          v4------v5
  /// ```
  ///
  /// UV indices follow the exact same triangulation topology as the generated vertex triangles.
  static List<Face> _triangulate(List<int> vtIndices, List<int> uvIndices) {
    final hasUVs = uvIndices.length == vtIndices.length;
    final faces = <Face> [];

    for (int i = 1; i < vtIndices.length - 1; i++) {
      final triVertices = [vtIndices[0], vtIndices[i], vtIndices[i + 1]];

      List<int> triUvs = [];

      if (hasUVs) {
        triUvs = [uvIndices[0], uvIndices[i], uvIndices[i + 1]];
      }

      faces.add(Face(
        vIndices: triVertices,
        vtIndices: triUvs,
      ));
    }

    return faces;
  }
}
