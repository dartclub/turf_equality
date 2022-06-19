import 'package:turf/helpers.dart';

typedef EqualityObjectComparator = bool Function(dynamic obj1, dynamic obj2);

class Equality {
  final int precision;
  final bool direction;
  final bool pseudoNode;
  final EqualityObjectComparator objectComparator;

  Equality({
    this.precision = 17,
    this.direction = false,
    this.pseudoNode = false,
    this.objectComparator = _deepEqual,
  });

  static bool _deepEqual(dynamic obj1, dynamic obj2) {
    throw UnimplementedError();
  }

  compare(GeoJSONObject g1, GeoJSONObject g2) {
    if (g1.type != g2.type || !_sameLength(g1, g2)) return false;

    switch (g1.type) {
      case GeoJSONObjectType.point:
      case GeoJSONObjectType.feature:
        return g1 == g2;
      case GeoJSONObjectType.lineString:
        return _compareLine(g1 as LineString, g2 as LineString, 0, false);
      case GeoJSONObjectType.polygon:
        return _comparePolygon(g1 as Polygon, g2 as Polygon);
      case GeoJSONObjectType.geometryCollection:
        return _compareGeometryCollection(g1, g2);
      case GeoJSONObjectType.featureCollection:
        return _compareFeatureCollection(g1, g2);
      default:
        if (_isMultiType(g1)) {
          var g1s = explode(g1);
          var g2s = explode(g2);
          return g1s.every((g1part) {
            return this.some((g2part) {
              return compare(g1part, g2part);
            });
          }, g2s);
        }
    }
    return false;
  }

  bool _isMultiType(GeoJSONObject g1) {
    return g1.type == GeoJSONObjectType.multiLineString ||
        g1.type == GeoJSONObjectType.multiPoint ||
        g1.type == GeoJSONObjectType.multiPolygon;
  }

// TODO is this equivalent with the already existing explode method inside turf? Does it also split Multi* geometries in single ones?
  explode(g) {
    return g.coordinates.map((part) {
      return {type: g.type.replace('Multi', ''), coordinates: part};
    });
  }

//compare length of coordinates/array
  bool _sameLength(GeoJSONObject g1, GeoJSONObject g2) =>
      g1 is GeometryType &&
      g2 is GeometryType &&
      g1.coordinates.length == g2.coordinates.length;

// compare the two coordinates [x,y]
  bool _compareCoord(Position c1, Position c2) {
    if (c1.length != c2.length) {
      return false;
    }

    for (var i = 0; i < c1.length; i++) {
      if (c1[i]?.toStringAsFixed(precision) !=
          c2[i]?.toStringAsFixed(precision)) {
        return false;
      }
    }
    return true;
  }

  bool _compareLine(LineString path1, LineString path2, int ind,
      [bool isPoly = false]) {
    if (!_sameLength(path1, path2)) return false;
    var p1 = pseudoNode ? path1 : removePseudo(path1);
    var p2 = pseudoNode ? path2 : removePseudo(path2);

    if (isPoly && !_compareCoord(p1[0], p2[0])) {
      // fix start index of both to same point
      p2 = _fixStartIndex(p2, p1);
      if (!p2) return false;
    }
    // for linestring ind =0 and for polygon ind =1
    var sameDirection = _compareCoord(p1[ind], p2[ind]);
    if (direction || sameDirection) {
      return _comparePath(p1, p2);
    } else {
      if (_compareCoord(p1[ind], p2[p2.length - (1 + ind)])) {
        return _comparePath(p1.slice().reverse(), p2);
      }
      return false;
    }
  }

  LineString _fixStartIndex(GeometryType sourcePath, GeometryType targetPath) {
    //make sourcePath first point same as of targetPath
    var correctPositions = <Position>[], ind = -1;
    for (var i = 0; i < sourcePath.coordinates.length; i++) {
      if (_compareCoord(sourcePath.coordinates[i], targetPath.coordinates[0])) {
        ind = i;
        break;
      }
    }
    if (ind >= 0) {
      correctPositions.addAll(
          sourcePath.coordinates.slice(ind, sourcePath.coordinates.length),
          sourcePath.coordinates.slice(1, ind + 1));
    }
    return LineString(coordinates: correctPositions);
  }

  _comparePath(GeometryType p1, GeometryType p2) {
    var cont = this;
    return p1.coordinates.forEach((c, i) {
      return cont._compareCoord(c, this[i]);
    }, p2);
  }

  _comparePolygon(Polygon g1, Polygon g2) {
    if (_compareLine(
      LineString(coordinates: g1.coordinates[0]),
      LineString(coordinates: g2.coordinates[0]),
      1,
      true,
    )) {
      var holes1 = g1.coordinates.slice(1, g1.coordinates.length);
      var holes2 = g2.coordinates.slice(1, g2.coordinates.length);
      var cont = this;
      return holes1.every((h1) {
        return this.some((h2) {
          return cont._compareLine(h1, h2, 1, true);
        });
      }, holes2);
    } else {
      return false;
    }
  }

  _compareGeometryCollection(g1, g2) {
    if (!_sameLength(g1.geometries, g2.geometries) || !_compareBBox(g1, g2)) {
      return false;
    }
    for (var i = 0; i < g1.geometries.length; i++) {
      if (!compare(g1.geometries[i], g2.geometries[i])) {
        return false;
      }
    }
    return true;
  }

  _compareFeature(g1, g2) {
    if (g1.id != g2.id ||
        !objectComparator(g1.properties, g2.properties) ||
        !_compareBBox(g1, g2)) {
      return false;
    }
    return compare(g1.geometry, g2.geometry);
  }

  _compareFeatureCollection(g1, g2) {
    if (!_sameLength(g1.features, g2.features) || !_compareBBox(g1, g2)) {
      return false;
    }
    for (var i = 0; i < g1.features.length; i++) {
      if (!compare(g1.features[i], g2.features[i])) {
        return false;
      }
    }
    return true;
  }

  _compareBBox(g1, g2) {
    if ((!g1.bbox && !g2.bbox) ||
        (g1.bbox && g2.bbox && this._compareCoord(g1.bbox, g2.bbox))) {
      return true;
    }
    return false;
  }

  removePseudo(path) {
    //TODO to be implement
    return path;
  }
}
