import 'package:vector_math/vector_math_64.dart';

/// Represents an Axis-Aligned Bounding Box (AABB) in 3D space.
///
/// An AABB is a rectangular bounding volume whose faces remain aligned with the coordinate axes.
class AABB {

  /// The minimum corner of the box.
  final Vector3 min;

  /// The maximum corner of the box.
  final Vector3 max;

  const AABB({
    required this.min,
    required this.max,
  });

  /// Creates a zero-sized AABB at the origin.
  factory AABB.zero() {
    return AABB(
      min: Vector3.zero(),
      max: Vector3.zero(),
    );
  }

  /// The dimensions of the box along each axis.
  Vector3 get size => max - min;

  /// The geometric center of the box.
  Vector3 get center => (min + max) * 0.5;

  /// The extent along the X axis.
  double get width => max.x - min.x;

  /// The extent along the Y axis.
  double get height => max.y - min.y;

  /// The extent along the Z axis.
  double get depth => max.z - min.z;
}
