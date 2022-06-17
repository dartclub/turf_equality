import 'package:turf/helpers.dart';

class Equality {
final int precision;
final bool direction;
final bool pseudoNode;
 Function? objectComparator;

  Equality({this.precision = 17, this.direction = false, this.pseudoNode = false, this.objectComparator}){
objectComparator = objectComparator ??  () {return deepEqual(obj1, obj2, {strict: true});};

  }

compare (GeoJSONObject g1, GeoJSONObject g2) {
  if (g1.type != g2.type || !sameLength(g1,g2)) return false;

  switch(g1.type) {

  case GeoJSONObjectType.lineString:
    return compareLine((g1 as LineString).coordinates, (g2 as LineString).coordinates,0,false);
  case GeoJSONObjectType.polygon:
    return comparePolygon(g1,g2);
  case GeoJSONObjectType.geometryCollection:
    return compareGeometryCollection(g1, g2);
  case GeoJSONObjectType.featureCollection:
    return compareFeatureCollection(g1, g2);
  default:
    if (g1.type == GeoJSONObjectType.multiLineString || g1.type == GeoJSONObjectType.multiPoint || g1.type == GeoJSONObjectType.multiPolygon) {
      var g1s = explode(g1);
      var g2s = explode(g2);
      return g1s.every((g1part) {
        return this.some((g2part) {
          return compare(g1part,g2part);
        });
      },g2s);
    }
  }
  return false;
}

explode(g) {
  return g.coordinates.map((part) {
    return {
      type: g.type.replace('Multi', ''),
      coordinates: part}
  });
}
//compare length of coordinates/array
sameLength(g1,g2) {
   return g1.hasOwnProperty('coordinates') ?
    g1.coordinates.length == g2.coordinates.length
    : g1.length == g2.length;
}

// compare the two coordinates [x,y]
compareCoord (c1,c2) {
  if (c1.length != c2.length) {
    return false;
  }

  for (var i=0; i < c1.length; i++) {
    if (c1[i].toFixed(precision) != c2[i].toFixed(precision)) {
      return false;
    }
  }
  return true;
}

compareLine (path1,path2,ind,isPoly) {
  if (!sameLength(path1,path2)) return false;
  var p1 = pseudoNode ? path1 : removePseudo(path1);
  var p2 = pseudoNode ? path2 : removePseudo(path2);
  if (isPoly && !compareCoord(p1[0],p2[0])) {
    // fix start index of both to same point
    p2 = fixStartIndex(p2,p1);
    if(!p2) return;
  }
  // for linestring ind =0 and for polygon ind =1
  var sameDirection = compareCoord(p1[ind],p2[ind]);
  if (direction || sameDirection
  ) {
    return comparePath(p1, p2);
  } else {
    if (compareCoord(p1[ind],p2[p2.length - (1+ind)])
    ) {
      return comparePath(p1.slice().reverse(), p2);
    }
    return false;
  }
}

fixStartIndex (sourcePath,targetPath) {
  //make sourcePath first point same as of targetPath
  var correctPath,ind = -1;
  for (var i=0; i< sourcePath.length; i++) {
    if(compareCoord(sourcePath[i],targetPath[0])) {
      ind = i;
      break;
    }
  }
  if (ind >= 0) {
    correctPath = []..addAll(
      sourcePath.slice(ind,sourcePath.length),
      sourcePath.slice(1,ind+1));
  }
  return correctPath;
}

comparePath  (p1,p2) {
  var cont = this;
  return p1.every((c,i) {
    return cont.compareCoord(c,this[i]);
  },p2);
}

comparePolygon (g1,g2) {
  if (compareLine(g1.coordinates[0],g2.coordinates[0],1,true)) {
    var holes1 = g1.coordinates.slice(1,g1.coordinates.length);
    var holes2 = g2.coordinates.slice(1,g2.coordinates.length);
    var cont = this;
    return holes1.every((h1) {
      return this.some((h2) {
        return cont.compareLine(h1,h2,1,true);
      });
    },holes2);
  } else {
    return false;
  }
}

compareGeometryCollection(g1,g2) {
  if (
    !sameLength(g1.geometries, g2.geometries) ||
    !compareBBox(g1,g2)
  ) {
    return false;
  }
  for (var i=0; i < g1.geometries.length; i++) {
    if (!compare(g1.geometries[i], g2.geometries[i])) {
      return false;
    }
  }
  return true;
}

compareFeature (g1,g2) {
  if (
    g1.id != g2.id ||
    !objectComparator(g1.properties, g2.properties) ||
    !compareBBox(g1,g2)
  ) {
    return false;
  }
  return compare(g1.geometry, g2.geometry);
}

compareFeatureCollection (g1,g2) {
  if (
    !sameLength(g1.features, g2.features) ||
    !compareBBox(g1,g2)
  ) {
    return false;
  }
  for (var i=0; i < g1.features.length; i++) {
    if (!compare(g1.features[i], g2.features[i])) {
      return false;
    }
  }
  return true;
}

compareBBox (g1,g2) {
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
}

removePseudo (path) {
  //TODO to be implement
  return path;
}

}