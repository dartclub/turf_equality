import 'dart:convert';
import 'dart:io';

import 'package:geojson_equality/geojson_equality.dart';
import 'package:test/test.dart';
import 'package:turf/helpers.dart';

void main() {
  group(
    'GeoJSONEquality',
    () {
      test('{direction, shiftedPolygon} in Polygons', () {
        var poly = Polygon(coordinates: [
          [
            Position(1, 1),
            Position(2, 2),
            Position(3, 3),
            Position(4, 4),
            Position(1, 1),
          ]
        ]);
        var poly2 = Polygon(coordinates: [
          [
            Position(2, 2),
            Position(3, 3),
            Position(4, 4),
            Position(1, 1),
            Position(2, 2),
          ]
        ]);

        var poly3 = Polygon(coordinates: [
          [
            Position(4, 4),
            Position(3, 3),
            Position(2, 2),
            Position(1, 1),
            Position(4, 4),
          ]
        ]);

        var poly4 = Polygon(coordinates: [
          [
            Position(3, 3),
            Position(2, 2),
            Position(1, 1),
            Position(4, 4),
            Position(3, 3),
          ]
        ]);

        // normal comparison
        Equality eq = Equality();
        expect(eq.compare(poly, poly2), false);

        // shifted positions
        Equality eq1 = Equality(shiftedPolygon: true);
        expect(eq1.compare(poly, poly2), true);

        // direction is reversed
        var eq2 = Equality(direction: true);
        expect(eq2.compare(poly, poly3), true);

        // direction is reserved and positions are shifted
        var eq3 = Equality(direction: true, shiftedPolygon: true);
        expect(eq3.compare(poly, poly4), true);
      });

      var inDir = Directory("./test/in");
      for (var inFile in inDir.listSync(recursive: true)) {
        if (inFile is File && inFile.path.endsWith('.geojson')) {
          GeoJSONObject inGeom =
              GeoJSONObject.fromJson(jsonDecode(inFile.readAsStringSync()));
          test(
            'precision ${inFile.uri.pathSegments.last}',
            () {
              Equality eq = Equality(precision: 5);
              var outDir = Directory('./test/out');
              for (var outFile in outDir.listSync(recursive: true)) {
                if (outFile is File && outFile.path.endsWith('.geojson')) {
                  if (outFile.uri.pathSegments.last ==
                      inFile.uri.pathSegments.last) {
                    GeoJSONObject outGeom = GeoJSONObject.fromJson(
                        jsonDecode(outFile.readAsStringSync()));
                    expect(eq.compare(inGeom, outGeom), true);
                  }
                }
              }
            },
          );
          test(
            'without precision ${inFile.uri.pathSegments.last}',
            () {
              Equality eq = Equality();
              var outDir = Directory('./test/out');
              for (var outFile in outDir.listSync(recursive: true)) {
                if (outFile is File && outFile.path.endsWith('.geojson')) {
                  if (outFile.uri.pathSegments.last ==
                      inFile.uri.pathSegments.last) {
                    GeoJSONObject outGeom = GeoJSONObject.fromJson(
                        jsonDecode(outFile.readAsStringSync()));
                    expect(eq.compare(inGeom, outGeom), true);
                  }
                }
              }
            },
          );
        }
      }
    },
  );
}
