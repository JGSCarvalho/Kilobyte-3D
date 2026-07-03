import 'dart:math' as math;
import 'dart:ui';

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
///
/// The engine uses a right-handed coordinate system:
///
/// - `+X`: Right;
/// - `+Y`: Up;
/// - `+Z`: Forward.
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
  /// - [out]: An optional target vector to store the result and avoid memory allocation.
  Vector3 toViewSpace(Vector3 worldPoint, [Vector3? out]) {
    return viewMatrix.transformed3(worldPoint, out);
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
  /// - [size]: The viewport dimensions in pixels.
  ///
  /// Nodes with a zero-radius bounding sphere are ignored.
  void frame(Node node, Size size) {
    final sphere = node.worldBoundingSphere;

    // Ignores empty bounding volumes.
    if (sphere.radius == 0.0) {
      return;
    }

    // Current camera forward direction in world space.
    //
    // In the engine coordinate system the third matrix column already represents the forward axis (+Z).
    final forward = transform.matrix.getColumn(2).xyz.normalized();

    if (projectionMode == ProjectionMode.perspective) {
      final halfFovV = (fov / 2.0) * math.pi / 180.0;
      final aspect = size.width / size.height;
      final halfFovH = math.atan(math.tan(halfFovV) * aspect);

      // Uses the most restrictive visible angle to ensure that the entire sphere remains inside the viewport.
      final minFov = math.min(halfFovV, halfFovH);
      final distance = sphere.radius / math.sin(minFov);
      final position = sphere.center - (forward * distance);

      transform.setTranslation(position);
    }
    else {
      // Computes the required visible diameter in world-space units.
      final requiredWorldSize = sphere.radius * 2.0;

      // Converts viewport resolution into orthographic scale density.
      //
      // The smallest viewport dimension is used to preserve aspect ratio while ensuring the entire sphere remains
      // visible inside the screen boundaries.
      final ppu = math.min(size.width, size.height) / requiredWorldSize;

      // Applies a small framing margin to avoid edge clipping.
      pixelsPerUnit = ppu * 0.9;

      // Orthographic projection is scale-independent from camera depth.
      //
      // The camera is repositioned only to keep the target volume inside the visible view region.
      final position = Vector3(sphere.center.x, sphere.center.y, sphere.radius);

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
  /// - `+Z`: Forward.
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

    // Prevents the `lookAt` operation when the target position becomes too close to the camera position.
    if ((target - eye).length2 < 1e-8) {
      return;
    }

    // Computes the forward viewing direction.
    final forward = (target - eye).normalized();

    // Builds the orthonormal basis horizontal axis.
    Vector3 right = upAxis.cross(forward);

    // Prevents basis degeneration when the forward direction becomes parallel to the up axis.
    if (right.length2 < 1e-8) {
      right = Vector3(1, 0, 0).cross(forward);
    }

    right.normalize();

    // Recomputes the orthogonal up vector.
    final up = forward.cross(right).normalized();

    // Builds the orthonormal lookAt basis.
    final lookAtBasis = Matrix3.columns(right, up, forward);

    // Converts the lookAt basis into a world transform.
    final lookAtWorldMatrix = Matrix4.compose(
      eye,
      Quaternion.fromRotation(lookAtBasis).normalized(),
      transform.scale,
    );

    // Converts the world transform into local space.
    if (parent != null) {
      final parentInverseMatrix = parent!.worldMatrix.clone()..invert();
      final localMatrix = parentInverseMatrix * lookAtWorldMatrix;

      transform.matrix = localMatrix;
    }
    else {
      transform.matrix = lookAtWorldMatrix;
    }
  }
}
