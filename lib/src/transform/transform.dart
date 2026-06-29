import 'package:vector_math/vector_math_64.dart';

/// Encapsulates the affine transformation properties of an entity in 3D space.
///
/// A [Transform] stores the local translation, orientation, and scale of an entity relative to its parent coordinate
/// system.
///
/// The engine uses a right-handed coordinate system:
///
/// - `+X`: Right;
/// - `+Y`: Up;
/// - `+Z`: Forward.
///
/// Rotations are internally represented using unit quaternions in order to avoid gimbal lock and provide stable
/// interpolation behavior.
class Transform {

  /// Local orientation represented as a quaternion.
  Quaternion _rotation;

  /// Local scaling factors applied along each axis.
  Vector3 _scale;

  /// Local position of the entity relative to its parent coordinate system.
  Vector3 _translation;

  Transform._(
    this._translation,
    this._rotation,
    this._scale,
  );

  /// Creates a new transform.
  ///
  /// ---
  ///
  /// ### Parameters:
  ///
  /// - [position]: Initial local position relative to the parent.
  /// - [rotation]: Initial local orientation represented as a quaternion.
  /// - [scale]: Initial local scale factors.
  ///
  /// Any omitted parameter falls back to its identity value.
  factory Transform({
    Vector3? position,
    Quaternion? rotation,
    Vector3? scale,
  }) {
    return Transform._(
      position ?? Vector3.zero(),
      rotation ?? Quaternion.identity(),
      scale ?? Vector3.all(1),
    );
  }

  /// Returns a copy of the current local orientation.
  Quaternion get rotation => _rotation.clone();

  /// Returns a copy of the current local scale.
  Vector3 get scale => Vector3.copy(_scale);

  /// Returns a copy of the current local translation.
  Vector3 get translation => Vector3.copy(_translation);

  /// Returns the local forward direction.
  ///
  /// The engine defines forward as the positive Z axis.
  Vector3 get forward {
    return _rotation.rotated(Vector3(0, 0, 1)).normalized();
  }

  /// Returns the local right direction.
  Vector3 get right {
    return _rotation.rotated(Vector3(1, 0, 0)).normalized();
  }

  /// Returns the local up direction.
  Vector3 get up {
    return _rotation.rotated(Vector3(0, 1, 0)).normalized();
  }

  /// Replaces the current local translation.
  ///
  /// ---
  ///
  /// ### Parameters:
  ///
  /// - [translation]: The local translation of the entity relative to its parent coordinate system.
  void setTranslation(Vector3 translation) {
    _translation = translation;
  }

  /// Replaces the current local orientation.
  ///
  /// ---
  ///
  /// ### Parameters:
  ///
  /// - [rotation]: The local orientation represented as a quaternion.
  void setRotation(Quaternion rotation) {
    _rotation = rotation.normalized();
  }

  /// Replaces the current local orientation using Euler angles in radians.
  ///
  /// ---
  ///
  /// ### Parameters:
  ///
  /// - [euler]: Rotation expressed as pitch, yaw, and roll in radians.
  void setEulerRotation(Vector3 euler) {
    final qx = Quaternion.axisAngle(Vector3(1, 0, 0), euler.x);
    final qy = Quaternion.axisAngle(Vector3(0, 1, 0), euler.y);
    final qz = Quaternion.axisAngle(Vector3(0, 0, 1), euler.z);

    _rotation = (qy * qx * qz).normalized();
  }

  /// Rotates the transform around the local X axis.
  ///
  /// ---
  ///
  /// ### Parameters:
  ///
  /// - [radians]: Rotation angle in radians.
  void rotateX(double radians) {
    final delta = Quaternion.axisAngle(Vector3(1, 0, 0), radians);

    _rotation = (_rotation * delta).normalized();
  }

  /// Rotates the transform around the local Y axis.
  ///
  /// ---
  ///
  /// ### Parameters:
  ///
  /// - [radians]: Rotation angle in radians.
  void rotateY(double radians) {
    final delta = Quaternion.axisAngle(Vector3(0, 1, 0), radians);

    _rotation = (_rotation * delta).normalized();
  }

  /// Rotates the transform around the local Z axis.
  ///
  /// ---
  ///
  /// ### Parameters:
  ///
  /// - [radians]: Rotation angle in radians.
  void rotateZ(double radians) {
    final delta = Quaternion.axisAngle(Vector3(0, 0, 1), radians);

    _rotation = (_rotation * delta).normalized();
  }

  /// Reorients the transform so that its forward direction points toward the specified target position.
  ///
  /// The generated orientation follows the engine's right-handed coordinate system where:
  ///
  /// - `+X`: Right;
  /// - `+Y`: Up;
  /// - `+Z`: Forward.
  ///
  /// The resulting basis is orthonormalized before conversion into a quaternion.
  ///
  /// ---
  ///
  /// ### Parameters:
  ///
  /// - [target]: The target position expressed in world space.
  /// - [worldUp]: The global up direction used to construct the orientation.
  void lookAt(
    Vector3 target,
    {
      Vector3? worldUp,
    }
  ) {
    final upAxis = worldUp ?? Vector3(0, 1, 0);

    // Computes the forward direction toward the target.
    final forward = (target - _translation).normalized();

    // Builds the horizontal axis of the orthonormal basis.
    Vector3 right = upAxis.cross(forward);

    // Prevents basis degeneration when the forward direction becomes parallel to the up axis.
    if (right.length2 < 1e-8) {
      right = Vector3(1, 0, 0).cross(forward);
    }

    right.normalize();

    // Recomputes the orthogonal up vector.
    final up = forward.cross(right).normalized();

    // Builds the rotation basis matrix.
    final rotationMatrix = Matrix3.columns(right, up, forward);

    _rotation = Quaternion.fromRotation(rotationMatrix).normalized();
  }

  /// Replaces the current local scale.
  ///
  /// ---
  ///
  /// ### Parameters:
  ///
  /// - [scale]: The local scale factors applied along each axis.
  void setScale(Vector3 scale) {
    _scale = scale;
  }

  /// Builds the local transformation matrix.
  ///
  /// The resulting matrix follows:
  ///
  ///   T * R * S
  ///
  /// This preserves local scaling and orientation before positioning the entity in world space.
  Matrix4 get matrix {
    return Matrix4.compose(
      _translation,
      _rotation,
      _scale,
    );
  }

  /// Replaces the current transform by decomposing a transformation matrix.
  ///
  /// The matrix is decomposed into translation, rotation, and scale components, which are then stored as the local
  /// transform state.
  ///
  /// Rotation is normalized to ensure a valid unit quaternion after decomposition.
  set matrix(Matrix4 value) {
    final translation = Vector3.zero();
    final rotation = Quaternion.identity();
    final scale = Vector3.all(1);

    value.decompose(
      translation,
      rotation,
      scale,
    );

    _translation = translation;
    _rotation = rotation.normalized();
    _scale = scale;
  }
}
