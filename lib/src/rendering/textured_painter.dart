import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../rendering/orthographic_projector.dart';

import '../scene/figure.dart';
import '../scene/node.dart';
import '../scene/scene.dart';

import 'textured_renderer.dart';

class TexturedPainter extends CustomPainter {

  final Scene scene;

  TexturedPainter({
    required super.repaint,
    required this.scene,
  });

  static const int _bucketCount = 1024;

  @override
  void paint(Canvas canvas, Size size) {
    final camera = scene.camera;

    assert(camera != null, 'The scene must have a camera!');

    void render(Node node) {
      if (node is Figure) {
        final geometry = node.geometry;

        OrthographicProjector.project(
          mesh: node.mesh,
          geometry: geometry,
          worldMatrix: node.worldMatrix,
          camera: camera!,
          size: size,
        );

        final visibility = geometry.triangleVisibility;
        final depths = geometry.triangleDepths;

        double minDepth = double.infinity;
        double maxDepth = -double.infinity;

        for (int t = 0; t < node.mesh.triCount; t++) {
          if (visibility[t] == 0) continue;

          final depth = depths[t];

          if (depth < minDepth) minDepth = depth;

          if (depth > maxDepth) maxDepth = depth;
        }

        // Nothing visible.
        if (minDepth == double.infinity) return;

        final depthRange = (maxDepth - minDepth).abs() < 1e-6 ? 1.0 : (maxDepth - minDepth);

        final buckets = List.generate(
          _bucketCount,
          (_) => <int> [],
          growable: false,
        );

        // Bucket distribution.
        for (int t = 0; t < node.mesh.triCount; t++) {
          if (visibility[t] == 0) continue;

          final normalized = ((depths[t] - minDepth) / depthRange).clamp(0.0, 1.0);
          final bucket = (normalized * (_bucketCount - 1)).toInt();

          buckets[bucket].add(t);
        }

        int visibleTriangleCount = 0;

        for (int i = 0; i < _bucketCount; i++) {
          visibleTriangleCount += buckets[i].length;
        }

        final trisSorted = Uint16List(visibleTriangleCount * 3);

        int dst = 0;

        // Back-to-front Painter order.
        for (int b = _bucketCount - 1; b >= 0; b--) {
          final bucket = buckets[b];

          for (int i = 0; i < bucket.length; i++) {
            final tri = bucket[i];
            final source = tri * 3;

            trisSorted[dst++] = node.mesh.indices[source];
            trisSorted[dst++] = node.mesh.indices[source + 1];
            trisSorted[dst++] = node.mesh.indices[source + 2];
          }
        }

        TexturedRenderer.render(
          canvas: canvas,
          geometry: geometry,
          mesh: node.mesh,
          tris: trisSorted,
          paint: node.paint,
        );
      }

      for (final child in node.children) {
        render(child);
      }
    }

    render(scene);
  }

  @override
  bool shouldRepaint(_) => false;
}
