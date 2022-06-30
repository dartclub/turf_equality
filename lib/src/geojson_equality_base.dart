import 'package:turf/helpers.dart';

typedef EqualityObjectComparator = bool Function(dynamic obj1, dynamic obj2);

class Equality {
  /// Decides the number of digits after . in a double
  final int precision;

  /// Even if the LineStrings are reverse versions of each other but the have similar
  /// [Position]s, they will be considered the same.
  final bool direction;

  /// If true, consider two [Polygon]s with shifted [Position]s as the same.
  final bool shiftedPolygon;
  // final EqualityObjectComparator objectComparator;

  Equality({
    this.precision = 17,
    this.direction = false,
    this.shiftedPolygon = false,

    //  this.objectComparator = _deepEqual,
  });

  bool _compareTypes<T extends GeoJSONObject>(
      GeoJSONObject? g1, GeoJSONObject? g2) {
    return g1 is T && g2 is T;
  }

  bool compare(GeoJSONObject? g1, GeoJSONObject? g2) {
    if (g1 == null && g2 == null) {
      return true;
    } else if (_compareTypes<Point>(g1, g2)) {
      return _compareCoords(
          (g1 as Point).coordinates, (g2 as Point).coordinates);
    } else if (_compareTypes<LineString>(g1, g2)) {
      return _compareLine(g1 as LineString, g2 as LineString);
    } else if (_compareTypes<Polygon>(g1, g2)) {
      return _comparePolygon(g1 as Polygon, g2 as Polygon);
    } else if (_compareTypes<Feature>(g1, g2)) {
      return compare((g1 as Feature).geometry, (g2 as Feature).geometry) &&
          g1.id == g2.id;
    } else if (_compareTypes<FeatureCollection>(g1, g2)) {
      for (var i = 0; i < (g1 as FeatureCollection).features.length; i++) {
        if (!compare(g1.features[i], (g2 as FeatureCollection).features[i])) {
          return false;
        }
      }
      return true;
    } else if (_compareTypes<GeometryCollection>(g1, g2)) {
      return compare(
        FeatureCollection(
          features: (g1 as GeometryCollection)
              .geometries
              .map((e) => Feature(geometry: e))
              .toList(),
        ),
        FeatureCollection(
          features: (g2 as GeometryCollection)
              .geometries
              .map((e) => Feature(geometry: e))
              .toList(),
        ),
      );
    } else if (_compareTypes<MultiPoint>(g1, g2)) {
      return compare(
        FeatureCollection(
          features: (g1 as MultiPoint)
              .coordinates
              .map((e) => Feature(geometry: Point(coordinates: e)))
              .toList(),
        ),
        FeatureCollection(
            features: (g2 as MultiPoint)
                .coordinates
                .map((e) => Feature(geometry: Point(coordinates: e)))
                .toList()),
      );
    } else if (_compareTypes<MultiLineString>(g1, g2)) {
      return compare(
        FeatureCollection(
          features: (g1 as MultiLineString)
              .coordinates
              .map((e) => Feature(geometry: LineString(coordinates: e)))
              .toList(),
        ),
        FeatureCollection(
            features: (g2 as MultiLineString)
                .coordinates
                .map((e) => Feature(geometry: LineString(coordinates: e)))
                .toList()),
      );
    } else if (_compareTypes<MultiPolygon>(g1, g2)) {
      return compare(
        FeatureCollection(
          features: (g1 as MultiPolygon)
              .coordinates
              .map((e) => Feature(geometry: Polygon(coordinates: e)))
              .toList(),
        ),
        FeatureCollection(
            features: (g2 as MultiPolygon)
                .coordinates
                .map(
                  (e) => Feature(geometry: Polygon(coordinates: e)),
                )
                .toList()),
      );
    } else {
      return false;
    }
  }

  bool _compareLine(LineString line1, LineString line2) {
    for (var i = 0; i < line1.coordinates.length; i++) {
      if (!_compareCoords(line1.coordinates[i], line2.coordinates[i])) {
        if (direction) {
          return false;
        } else {
          return _compareLine(
            line1,
            LineString(
              coordinates: line2.coordinates
                  .map((e) => e.clone())
                  .toList()
                  .reversed
                  .toList(),
            ),
          );
        }
      }
    }
    return true;
  }

  bool _compareCoords(Position one, Position two) {
    return one.alt?.toStringAsFixed(precision) ==
            two.alt?.toStringAsFixed(precision) &&
        one.lng.toStringAsFixed(precision) ==
            two.lng.toStringAsFixed(precision) &&
        one.lat.toStringAsFixed(precision) ==
            two.lat.toStringAsFixed(precision);
  }

  bool _comparePolygon(Polygon poly1, Polygon poly2) {
    List<List<Position>> list1 = poly1
        .clone()
        .coordinates
        .map((e) => e.sublist(0, e.length - 1))
        .toList();
    List<List<Position>> list2 = poly2
        .clone()
        .coordinates
        .map((e) => e.sublist(0, e.length - 1))
        .toList();

    for (var i = 0; i < list1.length; i++) {
      if (list1[i].length != list2[i].length) {
        return false;
      }
      for (var positionIndex = 0;
          positionIndex < list1[i].length;
          positionIndex++) {
        if (!shiftedPolygon && !direction) {
          if (!_compareCoords(
              list1[i][positionIndex], list2[i][positionIndex])) {
            return false;
          }
        } else if (shiftedPolygon && !direction) {
          int diff = list2[i].indexOf(list1[i][0]);
          if (!_compareCoords(
              list1[i][positionIndex],
              (list2[i][(list2[i].length + positionIndex + diff) %
                  list2[i].length]))) {
            return false;
          }
        } else if (direction && !shiftedPolygon) {
          List<List<Position>> listReversed = poly2
              .clone()
              .coordinates
              .map((e) => e.sublist(0, e.length - 1))
              .toList()
              .map((e) => e.reversed.toList())
              .toList();
          if (!_compareCoords(
              list1[i][positionIndex], listReversed[i][positionIndex])) {
            return false;
          }
        } else if (direction && shiftedPolygon) {
          List<List<Position>> listReversed = poly2
              .clone()
              .coordinates
              .map((e) => e.sublist(0, e.length - 1))
              .toList()
              .map((e) => e.reversed.toList())
              .toList();
          int diff = listReversed[i].indexOf(list1[i][0]);
          if (!_compareCoords(
              list1[i][positionIndex],
              (listReversed[i][(listReversed[i].length + positionIndex + diff) %
                  listReversed[i].length]))) {
            return false;
          }
        }
      }
    }
    return true;
  }
}
