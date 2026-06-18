import 'face.dart';
import 'render_vertex.dart';

/// Represents projected geometry in screen space.
///
/// A render geometry contains the final 2D data produced by the projection stage and ready to be consumed by the
/// rendering pipeline.
class RenderGeometry {

  final List<RenderVertex> vertices;

  final List<Face> faces;

  const RenderGeometry({
    required this.vertices,
    required this.faces,
  });
}
