import 'package:vector_math/vector_math_64.dart';

import '../transform/transform.dart';

/// Represents a node within a 3D scene graph.
///
/// Nodes can be organized hierarchically, allowing transformations to propagate from parent nodes to their descendants.
///
/// A node may act as a pivot, grouping container, or base class for scene elements such as cameras and figures.
class Node {

  /// The local transformation of this node.
  ///
  /// Defines the position, rotation, and scale of the node relative to its parent coordinate system.
  final Transform transform;

  Node({Transform? transform}) : transform = transform ?? Transform();

  /// The direct parent of this node in the scene graph.
  ///
  /// If null, the node is considered a root node and its local transform is evaluated directly in world space.
  Node? parent;

  /// The direct descendants of this node.
  ///
  /// Child nodes inherit this node's transformation hierarchy when computing their world-space transform.
  final children = <Node> [];

  /// Adds a child node to this node.
  ///
  /// If the child already belongs to another parent, it is automatically detached before being re-parented.
  ///
  /// ### Parameters:
  ///
  /// - [child]: The node to be attached as a direct descendant.
  void addChild(Node child) {
    child.parent?.children.remove(child);

    child.parent = this;

    children.add(child);
  }

  /// Removes a child node from this node.
  ///
  /// ### Parameters:
  ///
  /// - [child]: The node to remove from the hierarchy.
  void removeChild(Node child) {
    if (children.remove(child)) child.parent = null;
  }

  /// Detaches this node from its current parent.
  ///
  /// If the node has no parent, this operation has no effect.
  void detach() {
    parent?.removeChild(this);
  }

  /// Computes the world-space transformation matrix of this node.
  ///
  /// The resulting matrix is obtained by recursively combining the local transforms of all ancestors with this node's
  /// local transform.
  ///
  /// The multiplication order follows:
  ///
  /// Parent World Matrix * Local Matrix
  Matrix4 get worldMatrix {
    if (parent == null) return transform.matrix;

    return parent!.worldMatrix * transform.matrix;
  }
}
