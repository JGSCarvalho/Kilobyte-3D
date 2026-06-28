import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../scene/node.dart';
import 'figure.dart';

/// A structural node used to group multiple scene nodes.
///
/// Groups do not contain geometry themselves, but allow hierarchical transformations to be applied collectively to all
/// descendants.
class Group extends Node {

  Group({super.transform});

  void center() {
    if (children.isEmpty) return;

    double minX =  double.infinity; double minY =  double.infinity; double minZ =  double.infinity;
    double maxX = -double.infinity; double maxY = -double.infinity; double maxZ = -double.infinity;

    for (final child in children) {
      if (child is Figure) {
        final world = child.worldMatrix;

        for (final v in child.vertices) {
          final p = world.transform3(v.clone());

          minX = math.min(minX, p.x); minY = math.min(minY, p.y); minZ = math.min(minZ, p.z);
          maxX = math.max(maxX, p.x); maxY = math.max(maxY, p.y); maxZ = math.max(maxZ, p.z);
        }
      }
    }

    final center = Vector3((minX + maxX) * 0.5, (minY + maxY) * 0.5, (minZ + maxZ) * 0.5);

    transform.setTranslation(transform.translation - center);
  }
}
