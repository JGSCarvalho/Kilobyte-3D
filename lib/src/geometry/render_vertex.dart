import 'dart:ui';

class RenderVertex {

  final Offset position;
  
  final double depth;

  const RenderVertex({
    this.position = Offset.zero,
    this.depth = 0.0,
  });
}
