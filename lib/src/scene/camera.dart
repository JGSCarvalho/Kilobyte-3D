import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../rendering/projection_mode.dart';

import '../scene/node.dart';

import '../transform/transform.dart';

/// Represents a camera within the 3D scene.
///
/// A camera defines the position and orientation from which the scene is viewed.
///
/// It provides the view transformation required to convert world-space coordinates into view-space coordinates before
/// projection onto the screen.
class Camera extends Node {

  /// Vertical field of view expressed in degrees.
  ///
  /// Smaller values produce a zoomed-in view, while larger values increase the visible area and exaggerate perspective
  /// distortion.
  ///
  /// This property is only used when [projectionMode] is set to [ProjectionMode.perspective].
  double fov;

  /// The number of screen pixels that represent one world-space unit.
  ///
  /// Higher values make objects appear larger, while lower values make them appear smaller.
  ///
  /// This property is only used when [projectionMode] is set to [ProjectionMode.orthographic].
  double pixelsPerUnit;

  /// The projection model used by this camera.
  ProjectionMode projectionMode;

  Camera._({
    required super.transform,
    required this.fov,
    required this.projectionMode,
    required this.pixelsPerUnit,
  });

  /// Creates a camera.
  ///
  /// ---
  ///
  /// ### Parameters:
  ///
  /// - [transform]: The local transform of the camera.
  /// - [fov]: The vertical field of view expressed in degrees.
  /// - [projectionMode]: The projection model used by the camera.
  /// - [pixelsPerUnit]: The number of screen pixels that represent one world-space unit when using orthographic
  /// projection.
  factory Camera({
    Transform? transform,
    double? fov,
    ProjectionMode? projectionMode,
    double? pixelsPerUnit,
  }) {
    return Camera._(
      transform: transform ?? Transform(),
      fov: fov ?? 60,
      projectionMode: projectionMode ?? ProjectionMode.perspective,
      pixelsPerUnit: pixelsPerUnit ?? 300,
    );
  }

  /// Computes the view matrix of the camera.
  ///
  /// The view matrix is obtained by inverting the camera's world transformation matrix.
  Matrix4 get viewMatrix {
    return worldMatrix.clone()..invert();
  }

  /// Converts a world-space coordinate into view-space.
  /// 
  /// ---
  ///
  /// ### Parameters:
  ///
  /// - [worldPoint]: The coordinate expressed in world space.
  Vector3 toViewSpace(Vector3 worldPoint) {
    return viewMatrix.transform3(worldPoint.clone());
  }

  /// Positions the camera so that the specified node fits entirely within the viewport.
  ///
  /// The framing operation uses the node's world-space bounding sphere to compute a camera position that fully
  /// encloses the object.
  ///
  /// ---
  ///
  /// ### Parameters:
  ///
  /// - [node]: The node to frame.
  /// - [viewportWidth]: Viewport width in screen pixels.
  /// - [viewportHeight]: Viewport height in screen pixels.
  ///
  /// Nodes with a zero-radius bounding sphere are ignored.
  void frame({
    required Node node,
    required double viewportWidth,
    required double viewportHeight,
  }) {
    final sphere = node.worldBoundingSphere;

    // Ignores empty bounding volumes.
    if (sphere.radius == 0.0) {
      return;
    }

    // Current camera forward direction in world space.
    //
    // The engine uses -Z as forward, therefore the third matrix column represents the backward axis and must be
    // negated.
    final forward = -(transform.matrix.getColumn(2).xyz)..normalize();

    if (projectionMode == ProjectionMode.perspective) {
      final halfFovV = (fov / 2.0) * math.pi / 180.0;
      final halfFovH = math.atan(math.tan(halfFovV) * viewportWidth);

      // Uses the most restrictive visible angle to ensure that the entire sphere remains inside the viewport.
      final minFov = math.min(halfFovV, halfFovH);
      final distance = sphere.radius / math.sin(minFov);
      final position = sphere.center - (forward * distance);

      transform.setTranslation(position);
    }
    else {
      final requiredWorldHeight = sphere.radius * 2.0;

      // Adjusts the orthographic scale factor.
      pixelsPerUnit = viewportHeight / requiredWorldHeight;

      // Orthographic projection does not depend on distance for scale, therefore the camera is simply offset for
      // stable visibility.
      final distance = sphere.radius + 10.0;
      final position = sphere.center - (forward * distance);

      transform.setTranslation(position);
    }

    lookAt(node);
  }

  /// Reorients the node so that its forward direction points toward the target node.
  ///
  /// The resulting orientation is computed in world space and then converted back into local space relative to the
  /// parent transform.
  ///
  /// The engine uses a right-handed coordinate system:
  ///
  /// - `+X`: Right;
  /// - `+Y`: Up;
  /// - `-Z`: Forward.
  ///
  /// ---
  ///
  /// ### Parameters:
  ///
  /// - [node]: The target node to face.
  ///
  /// If the node has a parent, the computed world transform is converted into the parent's local space before being
  /// applied.
  void lookAt(Node node) {
    final target = node.worldBoundingSphere.center;
    final eye = worldMatrix.getTranslation();

    final upAxis = Vector3(0, 1, 0);

    // Prevents the `lookAt` operation when the target position is extremely close to the current position.
    //
    // In this situation the direction vector becomes nearly zero:
    //
    //   target - eye ~= (0, 0, 0)
    //
    // Normalizing a zero-length vector would produce an invalid orientation containing NaN values.
    if ((target - eye).length2 < 1e-8) {
      return;
    }

    final forward = (target - eye).normalized();

    Vector3 right = upAxis.cross(forward);

    // Prevents basis degeneration when the forward direction becomes parallel to the up axis.
    if (right.length2 < 1e-8) {
      right = Vector3(1, 0, 0).cross(forward);
    }

    right.normalize();

    final up = forward.cross(right).normalized();

    final lookAtBasis = Matrix3.columns(right, up, -forward);
    final worldRotation = Quaternion.fromRotation(lookAtBasis);
    final lookAtWorldMatrix = Matrix4.compose(eye, worldRotation, transform.scale);

    // Converts the world transform into local space.
    if (parent != null) {
      final parentInverse = parent!.worldMatrix.clone()..invert();
      final localMatrix = parentInverse * lookAtWorldMatrix;

      transform.matrix = localMatrix;
    }
    else {
      transform.matrix = lookAtWorldMatrix;
    }
  }
}
