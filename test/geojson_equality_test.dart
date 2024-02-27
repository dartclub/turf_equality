import 'dart:convert';
import 'dart:io';

import 'package:turf_equality/turf_equality.dart';
import 'package:test/test.dart';
import 'package:turf/helpers.dart';

import 'context/helper.dart';

void main() {
  group('LineString Equality', () {
    Equality eq = Equality();
    test('two points, different values', () {
      final result = eq.compare(
        lineString([
          [125, -30],
          [135, -30],
        ]),
        lineString([
          [115, -35],
          [125, -30],
        ]),
      );
      expect(result, false);
    });

    test('two points, same value', () {
      final result = eq.compare(
        lineString([
          [115, -35],
          [125, -30],
        ]),
        lineString([
          [115, -35],
          [125, -30],
        ]),
      );
      expect(result, true);
    });

    // ToDo: I would expect this to be false, but it could be argued, that
    // the line is the same, just the amount of points is different.
    test('same line, different amount of points (additional middle point)', () {
      final result = eq.compare(
        lineString([
          [100, -30],
          [120, -30],
        ]),
        lineString([
          [100, -30],
          [110, -30],
          [120, -30],
        ]),
      );
      expect(result, false);
    });

    // ToDo: If the last test case is false, I would expect, that this test
    // should also be false. Actually it is true.
    test('same line, different amount of points (end point duplicated)', () {
      final result = eq.compare(
        lineString([
          [100, -30],
          [120, -30],
        ]),
        lineString([
          [100, -30],
          [120, -30],
          [120, -30],
        ]),
      );
      expect(result, true);
    });

    // ToDo: Another test case where the lines have the same shape but not the
    // same structure. Here with reversedGeometries, that behaves exactly the
    // opposite way as I would expect.
    test('same line, different orientation', () {
      final line1 = lineString([
        [100, -30],
        [120, -30],
      ]);
      final line2 = lineString([
        [120, -30],
        [100, -30],
      ]);
      final line3 = lineString([
        [0, 0],
        [0, 5],
        [5, 5],
        [5, 0]
      ]);
      final line4 = lineString([
        [5, 0],
        [5, 5],
        [0, 5],
        [0, 0]
      ]);

      final defaultParam = Equality();
      expect(defaultParam.compare(line1, line1), true);
      expect(defaultParam.compare(line1, line2), false);
      expect(defaultParam.compare(line3, line4), false);

      final reversedFalse = Equality(reversedGeometries: false);
      expect(reversedFalse.compare(line1, line1), true);
      expect(reversedFalse.compare(line1, line2), false);
      expect(reversedFalse.compare(line3, line4), false);

      final reversedTrue = Equality(reversedGeometries: true);
      expect(reversedTrue.compare(line1, line1), true);
      expect(reversedTrue.compare(line1, line2), true);
      expect(reversedTrue.compare(line3, line4), true);
    });

    test('detect modification on lat, long, start and end point', () {
      final original = [
        [100, -30],
        [120, -30],
      ];
      for (var point = 0; point < 2; point++) {
        for (var coordinate = 0; coordinate < 2; coordinate++) {
          final modified = original.clone();
          modified[point][coordinate] = 0;
          final result = eq.compare(lineString(original), lineString(modified));
          expect(result, false);
        }
      }
    });

    test('detect difference in altitude', () {
      expect(
        eq.compare(
          lineString([
            [100, -30, 100],
            [120, -30],
          ]),
          lineString([
            [100, -30],
            [120, -30],
          ]),
        ),
        false,
      );

      expect(
        eq.compare(
          lineString([
            [100, -30],
            [120, -30, 100],
          ]),
          lineString([
            [100, -30],
            [120, -30, 120],
          ]),
        ),
        false,
      );
    });

    test('same line with altitude', () {
      expect(
        eq.compare(
          lineString([
            [100, -30, 100],
            [120, -30, 40],
          ]),
          lineString([
            [100, -30, 100],
            [120, -30, 40],
          ]),
        ),
        true,
      );
    });
  });

  group('FeatureCollection Equality', () {
    final eq = Equality();
    test('collections with different length are not equal', () {
      expect(
        eq.compare(
          FeatureCollection(),
          FeatureCollection(features: [Feature()]),
        ),
        false,
      );

      expect(
        eq.compare(
          FeatureCollection(features: [Feature()]),
          FeatureCollection(),
        ),
        false,
      );

      expect(
        eq.compare(
          FeatureCollection(features: [Feature()]),
          FeatureCollection(features: [Feature(), Feature()]),
        ),
        false,
      );

      expect(
        eq.compare(
          FeatureCollection(features: [Feature(), Feature()]),
          FeatureCollection(features: [Feature()]),
        ),
        false,
      );
    });

    test('collections with same length are equal', () {
      expect(
        eq.compare(
          FeatureCollection(),
          FeatureCollection(),
        ),
        true,
      );

      expect(
        eq.compare(
          FeatureCollection(features: [Feature()]),
          FeatureCollection(features: [Feature()]),
        ),
        true,
      );

      expect(
        eq.compare(
          FeatureCollection(features: [Feature(), Feature()]),
          FeatureCollection(features: [Feature(), Feature()]),
        ),
        true,
      );

      expect(
        eq.compare(
          FeatureCollection(features: [
            Feature(geometry: Point(coordinates: Position(1, 1)))
          ]),
          FeatureCollection(features: [
            Feature(geometry: Point(coordinates: Position(1, 1)))
          ]),
        ),
        true,
      );
    });

    test('order does matter', () {
      expect(
        eq.compare(
          FeatureCollection(features: [
            Feature(id: '1'),
            Feature(id: '2'),
          ]),
          FeatureCollection(features: [
            Feature(id: '2'),
            Feature(id: '1'),
          ]),
        ),
        false,
      );
    });

    test('different ids affect equality', () {
      expect(
        eq.compare(
          FeatureCollection(features: [
            Feature(id: '1'),
          ]),
          FeatureCollection(features: [
            Feature(id: '2'),
          ]),
        ),
        false,
      );
    });
  });

  group('LineString Equality', () {});

  group(
    'Turf GeoJSONEquality',
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
        Equality eq1 = Equality(shiftedPolygons: true);
        expect(eq1.compare(poly, poly2), true);

        // direction is reversed
        var eq2 = Equality(reversedGeometries: true);
        expect(eq2.compare(poly, poly3), true);

        // direction is reserved and positions are shifted
        var eq3 = Equality(reversedGeometries: true, shiftedPolygons: true);
        expect(eq3.compare(poly, poly4), true);
      });

      var inDir = Directory("./test/examples/in");
      for (var inFile in inDir.listSync(recursive: true)) {
        if (inFile is File && inFile.path.endsWith('.geojson')) {
          GeoJSONObject inGeom =
              GeoJSONObject.fromJson(jsonDecode(inFile.readAsStringSync()));
          test(
            'precision ${inFile.uri.pathSegments.last}',
            () {
              Equality eq = Equality(precision: 5, reversedGeometries: true);
              var outDir = Directory('./test/examples/out');
              for (var outFile in outDir.listSync(recursive: true)) {
                if (outFile is File && outFile.path.endsWith('.geojson')) {
                  if (outFile.uri.pathSegments.last ==
                      inFile.uri.pathSegments.last) {
                    GeoJSONObject outGeom = GeoJSONObject.fromJson(
                        jsonDecode(outFile.readAsStringSync()));
                    expect(eq.compare(inGeom, outGeom), true,
                        reason: inFile.uri.pathSegments.last);
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
