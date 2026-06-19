import '../geometry/face.dart';

/// Represents a projected face inside viewport space.
///
/// A viewport face wraps the original geometric [Face] together with precomputed viewport metadata required during
/// rendering.
class ProjectedFace {

  /// The source geometric face.
  final Face face;

  /// The average camera-space depth of the face.
  ///
  /// Used by painter-style rendering algorithms to sort polygons from back-to-front before rasterization.
  final double depth;

  const ProjectedFace(this.face, this.depth);
}
