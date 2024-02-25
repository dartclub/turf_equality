import 'package:turf/turf.dart';
import 'package:turf/helpers.dart' as rounder;

typedef EqualityObjectComparator = bool Function(
  GeoJSONObject obj1,
  GeoJSONObject obj2,
);

class Equality {
  /// Decides the number of fraction digits in a [double]
  final int precision;

  /// Even if the [LineStrings] are reverse versions of each other but the have similar
  /// [Position]s, they will be considered the same.
  final bool reversedGeometries;

  /// If true, consider two [Polygon]s with shifted [Position]s as the same.
  final bool shiftedPolygons;
  // final EqualityObjectComparator objectComparator;

  Equality({
    this.precision = 17,
    this.reversedGeometries = false,
    this.shiftedPolygons = false,

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
      if ((g1 as FeatureCollection).features.length !=
          (g2 as FeatureCollection).features.length) {
        return false;
      }
      for (var i = 0; i < g1.features.length; i++) {
        if (!compare(g1.features[i], g2.features[i])) {
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
    }
    //
    else if (_compareTypes<MultiPoint>(g1, g2)) {
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
    }
    //
    else if (_compareTypes<MultiLineString>(g1, g2)) {
      if ((g1 as MultiLineString).coordinates.length !=
          (g2 as MultiLineString).coordinates.length) {
        return false;
      }
      for (var line = 0; line < g1.coordinates.length; line++) {
        if (!compare(LineString(coordinates: g1.coordinates[line]),
            LineString(coordinates: g2.coordinates[line]))) {
          return false;
        }
      }
      return true;
    }
    //
    else if (_compareTypes<MultiPolygon>(g1, g2)) {
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
    }
    //
    else {
      return false;
    }
  }

  bool _compareLine(LineString line1, LineString line2) {
    if (!_compareCoords(line1.coordinates.first, line2.coordinates.first)) {
      if (reversedGeometries) {
        return false;
      } else {
        var newLine = LineString(
          coordinates: line2.coordinates.reversed.toList(),
        );
        if (!_compareCoords(
            line1.coordinates.first, newLine.coordinates.first)) {
          return false;
        } else {
          return _compareLine(line1, newLine);
        }
      }
    } else {
      for (var i = 0; i < line1.coordinates.length; i++) {
        if (!_compareCoords(line1.coordinates[i], line2.coordinates[i])) {
          return false;
        }
      }
    }
    return true;
  }

  bool _compareCoords(Position one, Position two) {
    if (precision != 17) {
      one = Position.of(
          one.toList().map((e) => rounder.round(e, precision)).toList());
      two = Position.of(
          two.toList().map((e) => rounder.round(e, precision)).toList());
    }

    return one == two;
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
        if (reversedGeometries) {
          if (shiftedPolygons) {
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
                (listReversed[i][
                    (listReversed[i].length + positionIndex + diff) %
                        listReversed[i].length]))) {
              return false;
            }
          } else {
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
          }
        } else {
          if (shiftedPolygons) {
            int diff = list2[i].indexOf(list1[i][0]);
            if (!_compareCoords(
                list1[i][positionIndex],
                (list2[i][(list2[i].length + positionIndex + diff) %
                    list2[i].length]))) {
              return false;
            }
          } else {
            if (!_compareCoords(
                list1[i][positionIndex], list2[i][positionIndex])) {
              return false;
            }
          }
        }
      }
    }
    return true;
  }
}
