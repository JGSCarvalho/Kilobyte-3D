import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../scene/node.dart';

import '../scene/figure.dart';

/// A structural node used to group multiple scene nodes.
///
/// Groups do not contain geometry themselves, but allow hierarchical transformations to be applied collectively to all
/// descendants.
class Group extends Node {

  Group({super.transform});

  /// Re-centers the group's local pivot using the world-space center of all descendant [Figure] geometry.
  ///
  /// The method computes a world-space Axis-Aligned Bounding Box (AABB) encompassing every vertex belonging to direct
  /// child figures and then repositions the group so the bounding box center becomes the new local origin.
  ///
  /// Unlike [Figure.center], this operation does not modify geometry data.
  ///
  /// Instead, only the group's local transformation is adjusted.
  void center() {
    if (children.isEmpty) return;

    double minX =  double.infinity; double minY =  double.infinity; double minZ =  double.infinity;
    double maxX = -double.infinity; double maxY = -double.infinity; double maxZ = -double.infinity;

    for (final child in children) {
      if (child is Figure) {
        final world = child.worldMatrix;

        for (final vertex in child.vertices) {
          final point = world.transform3(vertex.clone());

          minX = math.min(minX, point.x); minY = math.min(minY, point.y); minZ = math.min(minZ, point.z);
          maxX = math.max(maxX, point.x); maxY = math.max(maxY, point.y); maxZ = math.max(maxZ, point.z);
        }
      }
    }

    final center = Vector3((minX + maxX) * 0.5, (minY + maxY) * 0.5, (minZ + maxZ) * 0.5);

    transform.setTranslation(transform.translation - center);
  }
}
