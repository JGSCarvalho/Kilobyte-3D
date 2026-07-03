import 'dart:typed_data';

class Geometry2D {

  final Float32List screenVertices;

  final Float32List vertexDepths;

  final Float32List triangleDepths;

  final Uint8List triangleVisibility;

  Geometry2D._({
    required this.screenVertices,
    required this.vertexDepths,
    required this.triangleDepths,
    required this.triangleVisibility,
  });

  factory Geometry2D.allocate({
    required int vertexCount,
    required int triCount,
  }) {

    return Geometry2D._(
      screenVertices: Float32List(vertexCount * 2),
      vertexDepths: Float32List(vertexCount),
      triangleDepths: Float32List(triCount),
      triangleVisibility: Uint8List(triCount),
    );
  }
}
