import 'package:turf/helpers.dart';

LineString lineString(List<List<int>> coordinates) {
  return LineString(coordinates: coordinates.toPositions());
}

Point point(List<double> coordinates) {
  return Point(coordinates: Position.of(coordinates));
}

Feature<Polygon> polygon(List<List<List<int>>> coordinates) {
  return Feature(
    geometry: Polygon(coordinates: coordinates.toPositions()),
  );
}

extension PointsExtension on List<List<int>> {
  List<Position> toPositions() =>
      map((position) => Position.of(position)).toList(growable: false);
}

extension PolygonPointsExtensions on List<List<List<int>>> {
  List<List<Position>> toPositions() =>
      map((element) => element.toPositions()).toList(growable: false);
}
