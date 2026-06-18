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
  ///   projection.
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
}
