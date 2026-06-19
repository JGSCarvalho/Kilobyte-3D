import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kilobyte_3d/kilobyte_3d.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

void main() {
  runApp(const MaterialApp(
    home: Example(),
  ));
}

class Example extends StatefulWidget {

  const Example({super.key});

  @override
  State<Example> createState() => _ExampleState();
}

class _ExampleState extends State<Example> {
  final Camera camera = Camera();
  final Scene scene = Scene();

  double _yaw = 0;

  @override
  void initState() {
    super.initState();

    camera.transform.setTranslation(Vector3(0, 0, -5));
    camera.projectionMode = ProjectionMode.orthographic;

    scene.camera = camera;

    addModel();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        _yaw += details.delta.dx * -0.01;
    
        scene.transform.setYaw(_yaw);
      },
      child: Kilobyte3D(
        size: Size(
          MediaQuery.sizeOf(context).width,
          MediaQuery.sizeOf(context).height,
        ),
        fps: 30,
        scene: scene,
        mode: RenderMode.textured,
      ),
    );
  }

  Future<void> addModel() async {
    final content = await rootBundle.loadString('assets/a.obj');

    final figure = OBJ.parse(content);
    figure.texture = await loadTexture('assets/a.bmp');

    figure.centerPivot();
    figure.transform.setTranslation(Vector3(0, 0, 0));
    figure.transform.setYaw(pi);
    figure.transform.setScale(Vector3.all(0.75));

    scene.addChild(figure);
    scene.addChild(figure);
  }

  Future<ui.Image> loadTexture(String asset) async {
    final byteData = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(byteData.buffer.asUint8List());
    final frame = await codec.getNextFrame();

    return frame.image;
  }
}
