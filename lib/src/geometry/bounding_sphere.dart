import 'package:vector_math/vector_math_64.dart';

/// Represents a bounding sphere in 3D space.
///
/// Bounding spheres provide fast intersection tests and are rotationally invariant, making them useful for broad-phase
/// spatial operations.
class BoundingSphere {

  /// Center position of the sphere.
  ///
  /// The coordinate space depends on the context in which the sphere is used.
  final Vector3 center;

  /// Radius of the sphere.
  ///
  /// The radius represents the maximum distance from the center to the sphere surface.
  final double radius;

  /// Creates a bounding sphere.
  ///
  /// ---
  ///
  /// ### Parameters:
  ///
  /// - [center]: Sphere center position.
  /// - [radius]: Sphere radius.
  BoundingSphere(this.center, this.radius);
}
