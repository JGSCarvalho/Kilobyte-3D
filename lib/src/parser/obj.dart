import 'dart:developer';

import 'package:vector_math/vector_math_64.dart';

import '../geometry/face.dart';

import '../scene/figure.dart';

import '../transform/transform.dart';

/// Wavefront OBJ parser.
///
/// Responsible for decoding OBJ geometry into engine-native structures.
/// Supports vertices (v), normals (vn), texture coordinates (vt), and faces (f).
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
        faces.add(_OBJ.face(line));
      }
    }

    // Guarantee UV buffer consistency with vertex count.
    if (uvs.isEmpty) {
      log('OBJ missing UVs, generating zeroed UV buffer...');

      uvs = List<Vector2>.generate(vertices.length, (_) => Vector2.zero());
    }

    return Figure(
      vertices: vertices,
      faces: faces,
      transform: Transform(),
      uvs: uvs,
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
  /// ### Format:
  /// 
  /// `v x y z`
  static Vector3 vertex(String line) {
    final p = line.split(_whitespace);

    return Vector3(
      double.parse(p[1]),
      double.parse(p[2]),
      double.parse(p[3]),
    );
  }

  /// Parses a vertex normal line (`vn`).
  ///
  /// ---
  /// 
  /// ### Format:
  /// 
  /// `vn x y z`
  static Vector3 normal(String line) {
    final p = line.split(_whitespace);

    return Vector3(
      double.parse(p[1]),
      double.parse(p[2]),
      double.parse(p[3]),
    );
  }

  /// Parses a texture coordinate line (`vt`).
  /// 
  /// ---
  /// 
  /// ### Format:
  /// 
  /// `vt u v`
  ///
  /// ---
  /// 
  /// ### Notes:
  /// 
  /// - The V coordinate is inverted to match Flutter's coordinate system.
  static Vector2 uv(String line) {
    final p = line.split(_whitespace);

    final u = double.parse(p[1]);
    final v = 1.0 - double.parse(p[2]);

    return Vector2(u, v);
  }

  /// Parses a face definition line (`f`).
  ///
  /// ---
  ///
  /// ### Format:
  ///
  /// `f v1/vt1/vn1 v2/vt2/vn2 v3/vt3/vn3`
  ///
  /// ---
  ///
  /// ### Notes:
  ///
  /// - Indices are converted from 1-based OBJ indexing to 0-based runtime indexing.
  /// - UV indices are preserved independently from vertex indices, matching the OBJ specification.
  static Face face(String line) {
    final p = line.split(_whitespace).sublist(1);

    final vertexIndices = <int>[];
    final uvIndices = <int>[];

    for (final part in p) {
      if (part.isEmpty) continue;

      final tokens = part.split('/');

      vertexIndices.add(int.parse(tokens[0]) - 1);

      if (tokens.length > 1 && tokens[1].isNotEmpty) {
        uvIndices.add(int.parse(tokens[1]) - 1);
      }
    }

    return Face(
      vertexIndices: vertexIndices,
      uvIndices: uvIndices,
    );
  }
}
