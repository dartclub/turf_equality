import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:geojson_equality/geojson_equality.dart';
import 'package:test/test.dart';
import 'package:turf/helpers.dart';

void main() {
  group(
    'GeoJSONEquality',
    () {
      var inDir = Directory("./test/in");
      for (var file in inDir.listSync(recursive: true)) {
        if (file is File && file.path.endsWith('.geojson')) {
          GeoJSONObject inGeom =
              GeoJSONObject.fromJson(jsonDecode(file.readAsStringSync()));
          test(
            'precision',
            () {
              Equality eq = Equality(precision: 5);
              var outDir = Directory('./test/out');
              for (var file1 in outDir.listSync(recursive: true)) {
                if (file1 is File && file1.path.endsWith('.geojson')) {
                  if (file1.uri.pathSegments.last ==
                      file.uri.pathSegments.last) {
                    GeoJSONObject outGeom = GeoJSONObject.fromJson(
                        jsonDecode(file.readAsStringSync()));

                    expect(eq.compare(inGeom, outGeom), true);
                  }
                }
              }
            },
          );
          test(
            'multiPolygon with precision',
            () {
              Equality eq = Equality();
              var outDir = Directory('./test/out');
              for (var file1 in outDir.listSync(recursive: true)) {
                if (file1 is File && file1.path.endsWith('.geojson')) {
                  if (file1.uri.pathSegments.last ==
                      file.uri.pathSegments.last) {
                    GeoJSONObject outGeom = GeoJSONObject.fromJson(
                        jsonDecode(file.readAsStringSync()));
                    expect(eq.compare(inGeom, outGeom), true);
                  }
                }
              }
            },
          );

          test(
            'multiLineString',
            () {
              Equality eq = Equality();
              var outDir = Directory('./test/out');
              for (var file1 in outDir.listSync(recursive: true)) {
                if (file1 is File && file1.path.endsWith('.geojson')) {
                  if (file1.uri.pathSegments.last ==
                      file.uri.pathSegments.last) {
                    GeoJSONObject outGeom = GeoJSONObject.fromJson(
                        jsonDecode(file.readAsStringSync()));
                    expect(eq.compare(inGeom, outGeom), true);
                  }
                }
              }
            },
          );
          test(
            'FeatureCollection<GeometryCollection>',
            () {
              Equality eq = Equality();
              var outDir = Directory('./test/out');
              for (var file1 in outDir.listSync(recursive: true)) {
                if (file1 is File && file1.path.endsWith('.geojson')) {
                  if (file1.uri.pathSegments.last ==
                      file.uri.pathSegments.last) {
                    GeoJSONObject outGeom = GeoJSONObject.fromJson(
                        jsonDecode(file.readAsStringSync()));
                    expect(eq.compare(inGeom, outGeom), true);
                  }
                }
              }
            },
          );

          test('shifting Polygons', () {
            var poly = Polygon(coordinates: [
              [
                Position(1, 1),
                Position(2, 2),
                Position(3, 3),
                Position(1, 1),
              ]
            ]);
            var poly2 = Polygon(coordinates: [
              [
                Position(2, 2),
                Position(3, 3),
                Position(1, 1),
                Position(2, 2),
              ]
            ]);
            var poly3 = Polygon(coordinates: [
              [
                Position(3, 3),
                Position(2, 2),
                Position(1, 1),
                Position(3, 3),
              ]
            ]);
            Equality eq = Equality(shiftedPolygon: true);
            expect(eq.compare(poly, poly2), true);
            expect(eq.compare(poly, poly3), true);
          });
        }
      }
    },
  );
}
