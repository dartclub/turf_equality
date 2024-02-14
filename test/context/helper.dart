import 'package:turf/helpers.dart';

LineString lineString(List<List<num>> coordinates) {
  return LineString(coordinates: coordinates.toPositions());
}

Point point(List<num> coordinates) {
  return Point(coordinates: Position.of(coordinates));
}

Feature<Polygon> polygon(List<List<List<num>>> coordinates) {
  return Feature(
    geometry: Polygon(coordinates: coordinates.toPositions()),
  );
}

extension PointsExtension on List<List<num>> {
  List<Position> toPositions() =>
      map((position) => Position.of(position)).toList(growable: false);
}

extension PolygonPointsExtensions on List<List<List<num>>> {
  List<List<Position>> toPositions() =>
      map((element) => element.toPositions()).toList(growable: false);
}

extension LineListExtension on List<List<num>> {
  List<List<num>> clone() => map((element) => List<num>.from(element)).toList();
}
