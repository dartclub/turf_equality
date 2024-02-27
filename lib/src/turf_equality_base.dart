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

  final int Function(GeoJSONObject obj1, GeoJSONObject obj2)? objectComparator;

  Equality({
    this.objectComparator,
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
      for (final g1Feature in g1.features) {
        final hasMatch = g2.features.any(
          (g2Feature) => compare(g1Feature, g2Feature),
        );
        if (!hasMatch) {
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
      if (!reversedGeometries) {
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

  bool _comparePolygon(Polygon polygon1, Polygon polygon2) {
    List<List<Position>> reverse(Polygon polygon) {
      return polygon
          .clone()
          .coordinates
          .map((e) => e.sublist(0, e.length - 1))
          .toList()
          .map((e) => e.reversed.toList())
          .toList();
    }

    Position shift(Position first, List<Position> coords, int index) {
      int diff = coords.indexOf(first);
      final iShifted = (coords.length + index + diff) % coords.length;
      return coords[iShifted];
    }

    List<List<Position>> deconstruct(Polygon polygon) {
      // ToDo: last and first position of polygons are the same. Do we really
      // want to remove the last position? We didn't detect any difference
      // of the last position here.
      return polygon
          .clone()
          .coordinates
          .map((e) => e.sublist(0, e.length - 1))
          .toList();
    }

    List<List<Position>> linearRings1 = deconstruct(polygon1);
    List<List<Position>> linearRings2 = deconstruct(polygon2);

    if (linearRings1.length != linearRings2.length) return false;

    for (var iRing = 0; iRing < linearRings1.length; iRing++) {
      final coords1 = linearRings1[iRing];
      final coords2 = linearRings2[iRing];

      if (coords1.length != coords2.length) return false;

      for (var iPosition = 0; iPosition < coords1.length; iPosition++) {
        final position1 = coords1[iPosition];
        final position2 = coords2[iPosition];

        if (!_compareCoords(position1, position2)) {
          if (!reversedGeometries && !shiftedPolygons) {
            return false;
          }

          if (!reversedGeometries && shiftedPolygons) {
            final shifted = shift(coords1.first, coords2, iPosition);
            if (!_compareCoords(position1, shifted)) {
              return false;
            }
          }

          if (reversedGeometries && shiftedPolygons) {
            final reversed = reverse(polygon2)[iRing];
            final shifted = shift(coords1.first, reversed, iPosition);
            if (!_compareCoords(position1, shifted)) {
              return false;
            }
          }

          if (reversedGeometries && !shiftedPolygons) {
            final reversed = reverse(polygon2)[iRing][iPosition];
            if (!_compareCoords(position1, reversed)) {
              return false;
            }
          }
        }
      }
    }
    return true;
  }
}
