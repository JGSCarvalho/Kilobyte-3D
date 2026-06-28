import '../scene/figure.dart';
import 'projected_face.dart';
import 'projected_geometry.dart';

class RenderPolygon {
  final ProjectedGeometry geometry;
  final ProjectedFace projectedFace;
  final Figure figure;

  RenderPolygon({
    required this.geometry,
    required this.projectedFace,
    required this.figure,
  });
}
