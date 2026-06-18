import 'package:vector_math/vector_math_64.dart';

/// Encapsulates the affine transformation properties of an entity in 3D space.
///
/// A [Transform] stores the local position, rotation, and scale of an entity relative to its parent coordinate system.
///
/// These properties are combined into a model matrix used throughout the rendering pipeline to transform vertices from
/// local space into world space.
class Transform {

  /// Local orientation expressed as Euler angles (pitch, yaw, roll) in radians.
  Vector3 _rotation;

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
  /// - [rotation]: Initial local rotation expressed in radians.
  /// - [scale]: Initial local scale factors.
  ///
  /// Any omitted parameter falls back to its identity value.
  factory Transform({
    Vector3? position,
    Vector3? rotation,
    Vector3? scale,
  }) {
    return Transform._(
      position ?? Vector3.zero(),
      rotation ?? Vector3.zero(),
      scale ?? Vector3.all(1),
    );
  }

  /// Returns a copy of the current local rotation in radians.
  Vector3 get rotation => Vector3.copy(_rotation);

  /// Returns a copy of the current local scale.
  Vector3 get scale => Vector3.copy(_scale);

  /// Returns a copy of the current local translation.
  Vector3 get translation => Vector3.copy(_translation);

  /// Replaces the current local translation.
  /// 
  /// ---
  ///
  /// ### Parameters:
  ///
  /// - [translation]: The local translation of the entity relative to its parent coordinate system.
  void setTranslation(Vector3 translation) => _translation = translation;

  /// Replaces the current local rotation.
  /// 
  /// ---
  ///
  /// ### Parameters:
  ///
  /// - [rotation]: The local rotation expressed as Euler angles (pitch, yaw, roll) in radians.
  void setRotation(Vector3 rotation) => _rotation = rotation;

  /// Sets the local pitch rotation around the X axis.
  /// 
  /// ---
  ///
  /// ### Parameters:
  ///
  /// - [pitch]: The rotation angle around the local X axis in radians.
  void setPitch(double pitch) => _rotation.x = pitch;

  /// Sets the local yaw rotation around the Y axis.
  /// 
  /// ---
  ///
  /// ### Parameters:
  ///
  /// - [yaw]: The rotation angle around the local Y axis in radians.
  void setYaw(double yaw) => _rotation.y = yaw;

  /// Sets the local roll rotation around the Z axis.
  /// 
  /// ---
  ///
  /// ### Parameters:
  ///
  /// - [roll]: The rotation angle around the local Z axis in radians.
  void setRoll(double roll) => _rotation.z = roll;

  /// Replaces the current local scale.
  /// 
  /// ---
  ///
  /// ### Parameters:
  ///
  /// - [scale]: The local scale factors applied along each axis.
  void setScale(Vector3 scale) => _scale = scale;

  /// Builds the local model matrix from position, rotation, and scale.
  ///
  /// The resulting matrix follows:
  ///
  ///   T * Rx * Ry * Rz * S
  ///
  /// This preserves local scaling and rotation before positioning the entity in world space.
  Matrix4 get matrix {
    final matrix = Matrix4.identity();

    matrix.translateByVector3(_translation);

    matrix.rotateX(_rotation.x);
    matrix.rotateY(_rotation.y);
    matrix.rotateZ(_rotation.z);

    matrix.scaleByVector3(_scale);

    return matrix;
  }
}
