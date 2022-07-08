import 'dart:convert';
import 'dart:io';

import 'package:turf_equality/turf_equality.dart';
import 'package:test/test.dart';
import 'package:turf/helpers.dart';

void main() {
  group(
    'Turf GeoJSONEquality',
    () {
      var inDir1 = Directory("./test/in");
      for (var inFile in inDir1.listSync(recursive: true)) {
        if (inFile is File && inFile.path.endsWith('.geojson')) {
          GeoJSONObject inGeom =
              GeoJSONObject.fromJson(jsonDecode(inFile.readAsStringSync()));
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
                    expect(eq.compare(inGeom, inGeom), false);
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
