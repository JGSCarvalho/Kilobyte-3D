import '../scene/camera.dart';
import '../scene/node.dart';

import '../transform/transform.dart';

/// Represents the root node of a 3D scene graph.
///
/// The scene acts as the top-level container for all nodes participating in the rendering process.
///
/// It also manages the active camera used to observe and render the scene.
class Scene extends Node {

  /// The active camera used during rendering.
  Camera? camera;

  Scene._({
    required super.transform,
    this.camera,
  });

  /// Creates a new scene.
  /// 
  /// ---
  ///
  /// ### Parameters:
  ///
  /// - [camera]: The active camera used for rendering.
  factory Scene({
    Camera? camera,
  }) {
    return Scene._(
      transform: Transform(),
      camera: camera,
    );
  }
}
