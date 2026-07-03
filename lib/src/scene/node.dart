import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../geometry/bounding_sphere.dart';

import '../transform/transform.dart';

import '../scene/figure.dart';

/// Represents a node within a 3D scene graph.
///
/// Nodes can be organized hierarchically, allowing transformations to propagate from parent nodes to their descendants.
///
/// A node may act as a pivot, grouping container, or base class for scene elements such as cameras and figures.
abstract class Node {

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
  
  /// Returns all vertices of this node hierarchy transformed into world space.
  ///
  /// If the node is a [Figure], its local vertices are transformed using the
  /// world matrix. Child nodes are recursively included.
  ///
  /// This is primarily used for bounding volume computation and spatial queries.
  List<Vector3> get worldVertices {
    final points = <Vector3> [];
  
    if (this is Figure) {
      final figure = this as Figure;
      final matrix = worldMatrix;
  
      for (final vertex in figure.vertices) {
        points.add(matrix.transform3(vertex.clone()));
      }
    }
  
    for (final child in children) {
      points.addAll(child.worldVertices);
    }
  
    return points;
  }

  /// Computes a world-space bounding sphere that encloses this node and all its children.
  /// 
  /// The sphere is derived from transformed world-space vertices and provides a fast approximation for culling,
  /// collision detection, and camera framing.
  /// 
  /// If no vertices exist, returns a zero-radius sphere at the node's position.
  BoundingSphere get worldBoundingSphere {
    final points = worldVertices;

    if (points.isEmpty) {
      return BoundingSphere(transform.translation, 0.0);
    }

    // Computes AABB bounds to estimate a stable center point.
    final minV = Vector3.all(double.infinity);
    final maxV = Vector3.all(-double.infinity);

    for (final point in points) {
      if (point.x < minV.x) minV.x = point.x;
      if (point.y < minV.y) minV.y = point.y;
      if (point.z < minV.z) minV.z = point.z;

      if (point.x > maxV.x) maxV.x = point.x;
      if (point.y > maxV.y) maxV.y = point.y;
      if (point.z > maxV.z) maxV.z = point.z;
    }

    final center = (minV + maxV) * 0.5;

    double maxSquareRadius = 0.0;

    for (final point in points) {
      final squareDistance = point.distanceToSquared(center);

      if (squareDistance > maxSquareRadius) maxSquareRadius = squareDistance;
    }

    return BoundingSphere(center, math.sqrt(maxSquareRadius));
  }
}
