import 'package:geotypes/geotypes.dart';
import 'round.dart' as rounder;

class Equality {
  /// Decides the number of fraction digits in a [double]
  final int precision;

  /// Even if the [LineStrings] are reverse versions of each other but the have similar
  /// [Position]s, they will be considered the same.
  final bool reversedGeometries;

  /// If true, consider two [Polygon]s with shifted [Position]s as the same.
  final bool shiftedPolygons;

  final int Function(GeoJSONObject obj1, GeoJSONObject obj2)? objectComparator;

  Equality({
    this.objectComparator,
    this.precision = 17,
    this.reversedGeometries = false,
    this.shiftedPolygons = false,
  });

  bool compare(GeoJSONObject? g1, GeoJSONObject? g2) {
    if (g1 == null || g2 == null) {
      return g1 == g2;
    } else if (g1 is Point && g2 is Point) {
      return _comparePoint(g1, g2);
    } else if (g1 is LineString && g2 is LineString) {
      return _compareLineString(g1, g2);
    } else if (g1 is Polygon && g2 is Polygon) {
      return _comparePolygon(g1, g2);
    } else if (g1 is Feature && g2 is Feature) {
      return _compareFeature(g1, g2);
    } else if (g1 is FeatureCollection && g2 is FeatureCollection) {
      return _compareFeatureCollection(g1, g2);
    } else if (g1 is GeometryCollection && g2 is GeometryCollection) {
      return _compareGeometryCollection(g1, g2);
    } else if (g1 is MultiPoint && g2 is MultiPoint) {
      return _compareMultiPoint(g1, g2);
    } else if (g1 is MultiLineString && g2 is MultiLineString) {
      return _compareMultiLineString(g1, g2);
    } else if (g1 is MultiPolygon && g2 is MultiPolygon) {
      return _compareMultiPolygon(g1, g2);
    } else {
      return false;
    }
  }

  bool _compareFeatureCollection(
    FeatureCollection first,
    FeatureCollection second,
  ) {
    if (first.features.length != second.features.length) {
      return false;
    }
    for (var i = 0; i < first.features.length; i++) {
      if (!compare(first.features[i], second.features[i])) {
        return false;
      }
    }
    return true;
  }

  bool _compareGeometryCollection(
    GeometryCollection first,
    GeometryCollection second,
  ) {
    if (first.geometries.length != second.geometries.length) {
      return false;
    }
    for (var i = 0; i < first.geometries.length; i++) {
      if (!compare(first.geometries[i], second.geometries[i])) {
        return false;
      }
    }
    return true;
  }

  bool _compareFeature(Feature feature1, Feature feature2) {
    return feature1.id == feature2.id &&
        compare(feature1.geometry, feature2.geometry);
  }

  bool _comparePoint(Point point1, Point point2) {
    return _compareCoords(point1.coordinates, point2.coordinates);
  }

  bool _compareMultiPoint(MultiPoint first, MultiPoint second) {
    if (first.coordinates.length != second.coordinates.length) {
      return false;
    }
    for (var i = 0; i < first.coordinates.length; i++) {
      if (!_compareCoords(first.coordinates[i], second.coordinates[i])) {
        return false;
      }
    }
    return true;
  }

  bool _compareLineString(LineString line1, LineString line2) {
    if (line1.coordinates.length != line2.coordinates.length) return false;

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
          return _compareLineString(line1, newLine);
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

  bool _compareMultiLineString(MultiLineString first, MultiLineString second) {
    if (first.coordinates.length != second.coordinates.length) {
      return false;
    }

    for (var i = 0; i < first.coordinates.length; i++) {
      final firstLineString = LineString(coordinates: first.coordinates[i]);
      final secondLineString = LineString(coordinates: second.coordinates[i]);
      if (!compare(firstLineString, secondLineString)) {
        return false;
      }
    }

    return true;
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

  bool _compareMultiPolygon(MultiPolygon first, MultiPolygon second) {
    if (first.coordinates.length != second.coordinates.length) {
      return false;
    }

    for (var i = 0; i < first.coordinates.length; i++) {
      final firstPolygon = Polygon(coordinates: first.coordinates[i]);
      final secondPolygon = Polygon(coordinates: second.coordinates[i]);
      if (!compare(firstPolygon, secondPolygon)) {
        return false;
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
}
