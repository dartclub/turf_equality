import 'dart:io';

import 'package:test/test.dart';

void main() {
  group(
    'GeoJSONEquality',
    () {
      var inDir = Directory("./test/in");
      for (var file in inDir.listSync(recursive: true)) {
        if (file is File && file.path.endsWith('.geojson')) {
          test(
            'precision',
            () {},
          );
        }
      }
    },
  );
}
