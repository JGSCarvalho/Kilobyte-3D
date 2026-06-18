/// Represents a face of a geometric figure.
///
/// A face is defined by a collection of vertex indices that reference vertices belonging to the parent geometry.
///
/// The order of the indices determines the vertex winding of the face, which may be used by rendering systems for
/// operations such as backface culling.
class Face {

  /// The vertex indices that define this face.
  ///
  /// Each index references a vertex in the parent geometry.
  final List<int> vertexIndices;

  /// The UV indices associated with the face vertices.
  ///
  /// Each index references a UV coordinate in the parent geometry UV buffer.
  ///
  /// Wavefront OBJ files maintain independent index streams for vertices and UVs, therefore these values are not
  /// guaranteed to match [vertexIndices].
  final List<int> uvIndices;

  const Face({
    required this.vertexIndices,
    required this.uvIndices,
  });
}
