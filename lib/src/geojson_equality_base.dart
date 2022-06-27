import 'package:turf/explode.dart';
import 'package:turf/helpers.dart';
import 'package:turf/meta.dart';

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

  compare(GeoJSONObject g1, GeoJSONObject g2) {
    if (g1.type != g2.type || !_sameLength(g1, g2)) return false;

    switch (g1.type) {
      case GeoJSONObjectType.point:
        return g1 == g2;
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
        if (_isMultiType(g1) && coordAll(g1).isNotEmpty) {
          FeatureCollection<Point> g1s = explode(g1);
          FeatureCollection<Point> g2s = explode(g2);
          return g1s.features.every(
            (g1part) {
              return g2s.features.any(
                (g2part) {
                  return compare(
                      Point(coordinates: g1part.geometry!.coordinates),
                      Point(coordinates: g2part.geometry!.coordinates));
                },
              );
            },
          );
        }
    }
    return false;
  }

  static bool _deepEqual(dynamic obj1, dynamic obj2) {
    throw UnimplementedError();
  }

  bool _isMultiType(GeoJSONObject g1) {
    return g1.type == GeoJSONObjectType.multiLineString ||
        g1.type == GeoJSONObjectType.multiPoint ||
        g1.type == GeoJSONObjectType.multiPolygon;
  }

//compare length of coordinates/array
  bool _sameLength(GeoJSONObject g1, GeoJSONObject g2) =>
      g1 is GeometryType &&
      g2 is GeometryType &&
      g1.coordinates.length == g2.coordinates.length;

  /// Compares the two [Position]s
  bool _compareCoords(Position p1, Position p2) {
    if (p1.length != p2.length) {
      return false;
    }
    if (p1.lng.toStringAsFixed(precision) !=
            p2.lng.toStringAsFixed(precision) &&
        p1.lat.toStringAsFixed(precision) !=
            p2.lat.toStringAsFixed(precision) &&
        p1.alt?.toStringAsFixed(precision) !=
            p2.alt?.toStringAsFixed(precision)) {
      return false;
    }
    return true;
  }

  LineString? _fixStartIndex(GeometryType sourcePath, GeometryType targetPath) {
    //make sourcePath first point same as of targetPath
    var correctPositions = <Position>[], ind = -1;
    for (var i = 0; i < sourcePath.coordinates.length; i++) {
      if (_compareCoords(
          sourcePath.coordinates[i], targetPath.coordinates[0])) {
        ind = i;
        break;
      }
    }
    if (ind >= 0) {
      correctPositions.addAll((sourcePath.coordinates as List<Position>)
          .sublist(ind, sourcePath.coordinates.length));
      correctPositions.addAll(
          (sourcePath.coordinates as List<Position>).sublist(1, ind + 1));
      return LineString(coordinates: correctPositions);
    }
    return null;
  }

  bool _comparePath(LineString p1, LineString p2) {
    if (p1.coordinates.isEmpty || p2.coordinates.isEmpty) return false;
    bool areEqualPaths = true;
    coordEach(p1, ((currentCoord, coordIndex, featureIndex, multiFeatureIndex,
        geometryIndex) {
      if (!_compareCoords(currentCoord!, p2.coordinates[coordIndex!])) {
        areEqualPaths = false;
      }
    }));
    return areEqualPaths;
  }

  _comparePolygon(Polygon g1, Polygon g2) {
    if (_compareLine(
      LineString(coordinates: g1.coordinates[0]),
      LineString(coordinates: g2.coordinates[0]),
      1,
      true,
    )) {
      var holes1 = g1.coordinates;
      var holes2 = g2.coordinates;
      for (var i = 0; i < holes1.length; i++) {
        if (!_compareLine(LineString(coordinates: holes1[i]),
            LineString(coordinates: holes2[i]), 1, true)) {
          return holes1.every((h1) {
            return holes2.any((h2) {
              return _compareLine(LineString(coordinates: h1),
                  LineString(coordinates: h2), 1, true);
            });
          });
        } else {
          return false;
        }
      }
    }
  }

  bool _compareBBox(g1, g2) {
    if ((!g1.bbox && !g2.bbox) ||
        (g1.bbox && g2.bbox && _compareCoords(g1.bbox, g2.bbox))) {
      return true;
    }
    return false;
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

  removePseudo(path) {
    //TODO to be implement
    return path;
  }

  bool _compareLine(LineString path1, LineString path2, int ind,
      [bool isPoly = false]) {
    if (!_sameLength(path1, path2)) return false;
    var p1 = pseudoNode ? path1 : removePseudo(path1);
    var p2 = pseudoNode ? path2 : removePseudo(path2);

    // Todo: figure out the usage and impl. in a separate comparePolygonLine fn.
    if (isPoly && !_compareCoords(p1.coordinates[0], p2.coordinates[0])) {
      // fix start index of both to same point
      p2 = _fixStartIndex(p2, p1);
      if (p2 == null) return false;
    }

    // for linestring ind =0 and for polygon ind =1
    var sameDirection =
        _compareCoords(p1.coordinates[ind], p2.coordinates[ind]);
    if (direction || sameDirection) {
      return _comparePath(p1, p2);
    } else {
      if (_compareCoords(p1[ind], p2[p2.length - (1 + ind)])) {
        return _comparePath(p1.reverse(), p2);
      }
      return false;
    }
  }
}

/*
//index.js
var deepEqual = require('deep-equal');

var Equality = function(opt) {
  this.precision = opt && opt.precision ? opt.precision : 17;
  this.direction = opt && opt.direction ? opt.direction : false;
  this.pseudoNode = opt && opt.pseudoNode ? opt.pseudoNode : false;
  this.objectComparator = opt && opt.objectComparator ? opt.objectComparator : objectComparator;
};

Equality.prototype.compare = function(g1,g2) {
  if (g1.type !== g2.type || !sameLength(g1,g2)) return false;

  switch(g1.type) {
  case 'Point':
    return this.compareCoord(g1.coordinates, g2.coordinates);
    break;
  case 'LineString':
    return this.compareLine(g1.coordinates, g2.coordinates,0,false);
    break;
  case 'Polygon':
    return this.comparePolygon(g1,g2);
    break;
  case 'GeometryCollection':
    return this.compareGeometryCollection(g1, g2);
  case 'Feature':
    return this.compareFeature(g1, g2);
  case 'FeatureCollection':
    return this.compareFeatureCollection(g1, g2);
  default:
    if (g1.type.indexOf('Multi') === 0) {
      var context = this;
      var g1s = explode(g1);
      var g2s = explode(g2);
      return g1s.every(function(g1part) {
        return this.some(function(g2part) {
          return context.compare(g1part,g2part);
        });
      },g2s);
    }
  }
  return false;
};

function explode(g) {
  return g.coordinates.map(function(part) {
    return {
      type: g.type.replace('Multi', ''),
      coordinates: part}
  });
}
//compare length of coordinates/array
function sameLength(g1,g2) {
   return g1.hasOwnProperty('coordinates') ?
    g1.coordinates.length === g2.coordinates.length
    : g1.length === g2.length;
}

// compare the two coordinates [x,y]
Equality.prototype.compareCoord = function(c1,c2) {
  if (c1.length !== c2.length) {
    return false;
  }

  for (var i=0; i < c1.length; i++) {
    if (c1[i].toFixed(this.precision) !== c2[i].toFixed(this.precision)) {
      return false;
    }
  }
  return true;
};

Equality.prototype.compareLine = function(path1,path2,ind,isPoly) {
  if (!sameLength(path1,path2)) return false;
  var p1 = this.pseudoNode ? path1 : this.removePseudo(path1);
  var p2 = this.pseudoNode ? path2 : this.removePseudo(path2);
  if (isPoly && !this.compareCoord(p1[0],p2[0])) {
    // fix start index of both to same point
    p2 = this.fixStartIndex(p2,p1);
    if(!p2) return;
  }
  // for linestring ind =0 and for polygon ind =1
  var sameDirection = this.compareCoord(p1[ind],p2[ind]);
  if (this.direction || sameDirection
  ) {
    return this.comparePath(p1, p2);
  } else {
    if (this.compareCoord(p1[ind],p2[p2.length - (1+ind)])
    ) {
      return this.comparePath(p1.slice().reverse(), p2);
    }
    return false;
  }
};
Equality.prototype.fixStartIndex = function(sourcePath,targetPath) {
  //make sourcePath first point same as of targetPath
  var correctPath,ind = -1;
  for (var i=0; i< sourcePath.length; i++) {
    if(this.compareCoord(sourcePath[i],targetPath[0])) {
      ind = i;
      break;
    }
  }
  if (ind >= 0) {
    correctPath = [].concat(
      sourcePath.slice(ind,sourcePath.length),
      sourcePath.slice(1,ind+1));
  }
  return correctPath;
};
Equality.prototype.comparePath = function (p1,p2) {
  var cont = this;
  return p1.every(function(c,i) {
    return cont.compareCoord(c,this[i]);
  },p2);
};

Equality.prototype.comparePolygon = function(g1,g2) {
  if (this.compareLine(g1.coordinates[0],g2.coordinates[0],1,true)) {
    var holes1 = g1.coordinates.slice(1,g1.coordinates.length);
    var holes2 = g2.coordinates.slice(1,g2.coordinates.length);
    var cont = this;
    return holes1.every(function(h1) {
      return this.some(function(h2) {
        return cont.compareLine(h1,h2,1,true);
      });
    },holes2);
  } else {
    return false;
  }
};

Equality.prototype.compareGeometryCollection= function(g1,g2) {
  if (
    !sameLength(g1.geometries, g2.geometries) ||
    !this.compareBBox(g1,g2)
  ) {
    return false;
  }
  for (var i=0; i < g1.geometries.length; i++) {
    if (!this.compare(g1.geometries[i], g2.geometries[i])) {
      return false;
    }
  }
  return true
};

Equality.prototype.compareFeature = function(g1,g2) {
  if (
    g1.id !== g2.id ||
    !this.objectComparator(g1.properties, g2.properties) ||
    !this.compareBBox(g1,g2)
  ) {
    return false;
  }
  return this.compare(g1.geometry, g2.geometry);
};

Equality.prototype.compareFeatureCollection = function(g1,g2) {
  if (
    !sameLength(g1.features, g2.features) ||
    !this.compareBBox(g1,g2)
  ) {
    return false;
  }
  for (var i=0; i < g1.features.length; i++) {
    if (!this.compare(g1.features[i], g2.features[i])) {
      return false;
    }
  }
  return true
};

Equality.prototype.compareBBox = function(g1,g2) {
  if (
    (!g1.bbox && !g2.bbox) || 
    (
      g1.bbox && g2.bbox &&
      this.compareCoord(g1.bbox, g2.bbox)
    )
  )  {
    return true;
  }
  return false;
};
Equality.prototype.removePseudo = function(path) {
  //TODO to be implement
  return path;
};

function objectComparator(obj1, obj2) {
  return deepEqual(obj1, obj2, {strict: true});
}

module.exports = Equality;*/