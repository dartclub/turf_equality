import 'package:geojson_equality/geojson_equality.dart';
import 'package:test/test.dart';
import 'package:turf/helpers.dart';

void main() {
  group(
    'GeoJSONEquality',
    () {
      var g1 = Point(coordinates: Position.of([30, 10])),
          g2 = Point(coordinates: Position.of([30, 10])),
          g3 = Point(coordinates: Position.of([30, 11])),
          g4 = Point(coordinates: Position.of([30, 10, 5])),
          g5 = Point(coordinates: Position.of([30, 10, 5])),
          eq = Equality();
      setUp(() {});
      test(
        '',
        () {
          expect(eq.compare(g1, g2), true);
          expect(eq.compare(g1, g3), false);
          expect(eq.compare(g1, g4), false);
          expect(eq.compare(g5, g4), true);
        },
      );

      //
      test(
        'geojson-equality for LineStrings',
        () {
          var gl1 = LineString(coordinates: [
                Position.of([30, 10]),
                Position.of([10, 30]),
                Position.of([40, 40])
              ]),
              gl2 = LineString(coordinates: [
                Position.of([30, 10]),
                Position.of([10, 30]),
                Position.of([40, 40])
              ]),
              gl3 = LineString(coordinates: [
                Position.of([31, 10]),
                Position.of([10, 30]),
                Position.of([40, 40])
              ]),
              gl4 = LineString(coordinates: [
                Position.of([40, 40]),
                Position.of([10, 30]),
                Position.of([30, 10])
              ]);

          expect(eq.compare(gl1, gl2), true);
          expect(eq.compare(gl1, gl3), false);

//'reverse direction, direction is not matched, so both are equal'
          expect(eq.compare(gl1, gl4), true);

//'reverse direction, direction is matched, so both are not equal'
          eq = Equality(direction: true);
          expect(eq.compare(gl1, gl4), false);
        },
      );

      test('geojson-equality for Polygons', () {
        var gp1 = Polygon(coordinates: [
          [
            Position.of([40, 40]),
            Position.of([20, 40]),
            Position.of([30, 10]),
            Position.of([10, 20]),
            Position.of([30, 10])
          ]
        ]);
        var gp2 = Polygon(coordinates: [
          [
            Position.of([30, 10]),
            Position.of([40, 40]),
            Position.of([20, 40]),
            Position.of([10, 20]),
            Position.of([30, 10])
          ]
        ]);

        var gp3 = Polygon(coordinates: [
          [
            Position.of([30, 10]),
            Position.of([41, 40]),
            Position.of([20, 40]),
            Position.of([10, 20]),
            Position.of([30, 10])
          ]
        ]);

        var gp4 = Polygon(coordinates: [
          [
            Position.of([30, 10]),
            Position.of([10, 20]),
            Position.of([20, 40]),
            Position.of([40, 40]),
            Position.of([30, 10])
          ]
        ]);

        var gp5 = Polygon(coordinates: [
          [
            Position.of([10, 20]),
            Position.of([20, 40]),
            Position.of([40, 40]),
            Position.of([30, 10]),
            Position.of([10, 20])
          ]
        ]);

        expect(eq.compare(gp1, gp2), true);
        expect(eq.compare(gp1, gp3), false);
        // reverse direction, direction is not matched, so both are equal
        expect(eq.compare(gp1, gp4), true);
        // reverse direction, direction is matched, so both are not equal
        eq = Equality(direction: true);
        expect(eq.compare(gp1, gp4), false);
        // reverse direction, diff start index, direction is not matched, so both are equal
        eq = Equality();
        expect(eq.compare(gp1, gp5), true);
// reverse direction, diff start index, direction is matched, so both are not equal

        eq = Equality(direction: true);
        expect(eq.compare(g1, g5), false);

        var gh1 = Polygon(coordinates: [
          [
            Position.of([45, 45]),
            Position.of([15, 40]),
            Position.of([10, 20]),
            Position.of([35, 10]),
            Position.of([45, 45]),
            Position.of([20, 30]),
            Position.of([35, 35]),
            Position.of([30, 20]),
            Position.of([20, 30])
          ]
        ]);

        var gh2 = Polygon(coordinates: [
          [
            Position.of([35, 10]),
            Position.of([45, 45]),
            Position.of([15, 40]),
            Position.of([10, 20]),
            Position.of([35, 10]),
            Position.of([20, 30]),
            Position.of([35, 35]),
            Position.of([30, 20]),
            Position.of([20, 30])
          ]
        ]);

// have holes too and diff start ind, direction is not matched, both are equal
        eq = Equality(direction: false);
        expect(eq.compare(gh1, gh2), true);

        // have holes too and diff start ind, direction is matched, so both are not equal
        eq = Equality(direction: true);
        expect(eq.compare(gh1, gh2), false); // Todos: original code is wrong?

        var gprecision1 = Polygon(coordinates: [
          [
            Position.of([35, 10]),
            Position.of([45, 45]),
            Position.of([40.12345, 40.12345]),
            Position.of([10, 20]),
            Position.of([35, 10]),
            Position.of([20, 30]),
            Position.of([35, 35]),
            Position.of([30, 20]),
            Position.of([20, 30])
          ]
        ]);

        var gprecision2 = Polygon(coordinates: [
          [
            Position.of([35, 10]),
            Position.of([45, 45]),
            Position.of([40.12338, 40.123378]),
            Position.of([10, 20]),
            Position.of([35, 10]),
            Position.of([20, 30]),
            Position.of([35, 35]),
            Position.of([30, 20]),
            Position.of([20, 30])
          ]
        ]);

        // after limiting precision, are equal', () {
        eq = Equality(precision: 3);
        expect(eq.compare(gprecision1, gprecision2), true);
        // with high precision, are not equal'
        eq = Equality(precision: 10);
        expect(eq.compare(gprecision1, gprecision2), false);
      });
      test('geojson-equality for Feature', () {
        //TODO remove
        // will not be equal with changed id'
        var f1 = Feature(id: "id1");
        var f2 = Feature(id: "id2");
        var eq = Equality();
        expect(eq.compare(f1, f2), false);
      });

      test('geojson-equality for FeatureCollection', () {
        //will not be equal with different number of features'
        var f1 = FeatureCollection(features: [
          Feature(geometry: Point(coordinates: Position.of([0, 0])))
        ]);
        var f2 = FeatureCollection(features: [
          Feature(geometry: Point(coordinates: Position.of([0, 0]))),
          Feature(geometry: Point(coordinates: Position.of([0, 0])))
        ]);

        var eq = Equality();
        expect(eq.compare(f1, f2), false);
        // will not be equal with different features'
        f1 = FeatureCollection(features: [
          Feature(geometry: Point(coordinates: Position.of([0, 0])))
        ]);
        f2 = FeatureCollection(features: [
          Feature(geometry: Point(coordinates: Position.of([1, 1])))
        ]);
        eq = Equality();
        expect(eq.compare(f1, f2), false);

        // will not be equal with different order of features'
        f1 = FeatureCollection(features: [
          Feature(geometry: Point(coordinates: Position.of([0, 0]))),
          Feature(geometry: Point(coordinates: Position.of([1, 1])))
        ]);
        f2 = FeatureCollection(features: [
          Feature(geometry: Point(coordinates: Position.of([1, 1]))),
          Feature(geometry: Point(coordinates: Position.of([0, 0])))
        ]);
        eq = Equality();
        expect(eq.compare(f1, f2), false);

        // will be equal with equal features
        f1 = FeatureCollection(features: [
          Feature(geometry: Point(coordinates: Position.of([1, 1])))
        ]);
        f2 = FeatureCollection(features: [
          Feature(geometry: Point(coordinates: Position.of([1, 1])))
        ]);
        eq = Equality();
        expect(eq.compare(f1, f2), true);

        // will be equal with equal with no features
        f1 = FeatureCollection(features: []);
        f2 = FeatureCollection(features: []);
        eq = Equality();
        expect(eq.compare(f1, f2), true);

        // will use a custom comparator if provided
        var f11 = FeatureCollection(features: [
          Feature(
            id: "id1",
            properties: {"foo_123": "bar"},
            geometry: Polygon(
              coordinates: [
                [
                  Position(40, 20),
                  Position(31, 10),
                  Position(30, 20),
                  Position(30, 10),
                  Position(10, 40)
                ]
              ],
            ),
          )
        ]);
        var f22 = FeatureCollection(features: [
          Feature(
            id: "id1",
            properties: {"foo_456": "bar"},
            geometry: Polygon(
              coordinates: [
                [
                  Position(40, 20),
                  Position(31, 10),
                  Position(30, 20),
                  Position(30, 10),
                  Position(10, 40)
                ]
              ],
            ),
          )
        ]);

        eq = Equality(objectComparator: (obj1, obj2) {
          return (obj1['foo_123'] != null && obj2['foo_456'] != null);
        });
        expect(eq.compare(f11, f22), true);
        // will not be equal if one has bbox and other not
        f1 = FeatureCollection(features: [], bbox: BBox(1, 2, 3, 4));
        f2 = FeatureCollection(features: []);
        eq = Equality();
        expect(eq.compare(f1, f2), false);
        // will not be equal if bboxes are not equal
        f1 = FeatureCollection(features: [], bbox: BBox(1, 2, 3, 4));
        f2 = FeatureCollection(features: [], bbox: BBox(1, 2, 3, 5));
        eq = Equality();
        expect(eq.compare(f1, f2), false);
// equal feature collections with bboxes
        f11 = FeatureCollection(features: [
          Feature(
              id: "id1",
              properties: {"foo": "bar1"},
              geometry: Polygon(coordinates: [
                [
                  Position.of([30, 10]),
                  Position.of([41, 40]),
                  Position.of([20, 40]),
                  Position.of([10, 20]),
                  Position.of([30, 10])
                ]
              ]))
        ], bbox: BBox(10, 10, 41, 40));
        f22 = FeatureCollection(features: [
          Feature(
              id: "id1",
              properties: {"foo": "bar1"},
              geometry: Polygon(coordinates: [
                [
                  Position.of([30, 10]),
                  Position.of([41, 40]),
                  Position.of([20, 40]),
                  Position.of([10, 20]),
                  Position.of([30, 10])
                ]
              ]))
        ], bbox: BBox(10, 10, 41, 40));
        eq = Equality();
        expect(eq.compare(f11, f22), true);

        // not equal features with equal bboxes
        f11 = FeatureCollection(features: [
          Feature(
              id: "id1",
              properties: {"foo": "bar1"},
              geometry: Polygon(coordinates: [
                [
                  Position.of([30, 10]),
                  Position.of([41, 40]),
                  Position.of([20, 40]),
                  Position.of([10, 20]),
                  Position.of([30, 10])
                ]
              ]))
        ], bbox: BBox(10, 10, 41, 40));
        f22 = FeatureCollection(features: [
          Feature(
              id: "id1",
              properties: {"foo": "bar1"},
              geometry: Polygon(coordinates: [
                [
                  Position.of([30, 10]),
                  Position.of([41, 40]),
                  Position.of([20, 40]),
                  Position.of([10, 20]),
                  Position.of([30, 1])
                ]
              ]))
        ], bbox: BBox(10, 10, 41, 40));
        eq = Equality();
        expect(eq.compare(f11, f22), false);
      });

      test('geojson-equality for MultiPoints', () {
        var g1 = MultiPoint(coordinates: [
          Position.of([0, 40]),
          Position.of([40, 30]),
          Position.of([20, 20]),
          Position.of([30, 10])
        ]);
        var g2 = MultiPoint(coordinates: [
          Position.of([0, 40]),
          Position.of([20, 20]),
          Position.of([40, 30]),
          Position.of([30, 10])
        ]);

        var eq = Equality();
        expect(eq.compare(g1, g2), true);
        var g3 = MultiPoint(coordinates: [
          Position.of([10, 40]),
          Position.of([20, 20]),
          Position.of([40, 30]),
          Position.of([30, 10])
        ]);
        eq = Equality();
        expect(eq.compare(g1, g3), false);
      });

      test('geojson-equality for MultiLineString', () {
        var g1 = MultiLineString(coordinates: [
          [
            Position.of([30, 10]),
            Position.of([10, 30]),
            Position.of([40, 40])
          ],
          [
            Position.of([0, 10]),
            Position.of([10, 0]),
            Position.of([40, 40])
          ]
        ]);
        var g2 = MultiLineString(coordinates: [
          [
            Position.of([40, 40]),
            Position.of([10, 30]),
            Position.of([30, 10])
          ],
          [
            Position.of([0, 10]),
            Position.of([10, 0]),
            Position.of([40, 40])
          ]
        ]);
// reverse direction, direction is not matched, so both are equal
        var eq = Equality();
        expect(eq.compare(g1, g2), true);

// reverse direction, direction is matched, so both are not equal
        eq = Equality(direction: true);
        expect(eq.compare(g1, g2), false);

        var g3 = MultiLineString(coordinates: [
          [
            Position.of([10, 10]),
            Position.of([20, 20]),
            Position.of([10, 40])
          ],
          [
            Position.of([40, 40]),
            Position.of([30, 30]),
            Position.of([40, 20]),
            Position.of([30, 10])
          ]
        ]);

        eq = Equality();
        expect(eq.compare(g1, g3), false);
      });

      test('geojson-equality for MultiPolygon', () {
        var g1 = MultiPolygon(coordinates: [
          [
            [
              Position.of([30, 20]),
              Position.of([45, 40]),
              Position.of([10, 40]),
              Position.of([30, 20])
            ]
          ],
          [
            [
              Position.of([15, 5]),
              Position.of([40, 10]),
              Position.of([10, 20]),
              Position.of([5, 10]),
              Position.of([15, 5])
            ]
          ]
        ]);
        var g2 = MultiPolygon(coordinates: [
          [
            [
              Position.of([30, 20]),
              Position.of([45, 40]),
              Position.of([10, 40]),
              Position.of([30, 20])
            ]
          ],
          [
            [
              Position.of([15, 5]),
              Position.of([40, 10]),
              Position.of([10, 20]),
              Position.of([5, 10]),
              Position.of([15, 5])
            ]
          ]
        ]);
        var eq = Equality();
        expect(eq.compare(g1, g2), true);
        var g3 = MultiPolygon(coordinates: [
          [
            [
              Position.of([30, 20]),
              Position.of([45, 40]),
              Position.of([10, 40]),
              Position.of([30, 20])
            ]
          ],
          [
            [
              Position.of([15, 5]),
              Position.of([400, 10]),
              Position.of([10, 20]),
              Position.of([5, 10]),
              Position.of([15, 5])
            ]
          ]
        ]);

        eq = Equality();
        expect(eq.compare(g1, g3), false);

        var gh1 = MultiPolygon(coordinates: [
          [
            [
              Position.of([40, 40]),
              Position.of([20, 45]),
              Position.of([45, 30]),
              Position.of([40, 40])
            ]
          ],
          [
            [
              Position.of([20, 35]),
              Position.of([10, 30]),
              Position.of([10, 10]),
              Position.of([30, 5]),
              Position.of([45, 20]),
              Position.of([20, 35])
            ],
            [
              Position.of([30, 20]),
              Position.of([20, 15]),
              Position.of([20, 25]),
              Position.of([30, 20])
            ],
            [
              Position.of([20, 10]),
              Position.of([30, 10]),
              Position.of([30, 15]),
              Position.of([20, 10])
            ]
          ]
        ]);
        var gh2 = MultiPolygon(
          coordinates: [
            [
              [
                Position.of([20, 35]),
                Position.of([10, 30]),
                Position.of([10, 10]),
                Position.of([30, 5]),
                Position.of([45, 20]),
                Position.of([20, 35]),
              ],
              [
                Position.of([20, 10]),
                Position.of([30, 10]),
                Position.of([30, 15]),
                Position.of([20, 10])
              ],
              [
                Position.of([30, 20]),
                Position.of([20, 15]),
                Position.of([20, 25]),
                Position.of([30, 20])
              ]
            ],
            [
              [
                Position.of([40, 40]),
                Position.of([20, 45]),
                Position.of([45, 30]),
                Position.of([40, 40])
              ]
            ]
          ],
        );
        // having holes, both are equal
        eq = Equality();
        expect(eq.compare(gh1, gh2), true);
      });

      test(
        'geojson-equality for GeometryCollection',
        () {
          // will not be equal with different number of geometries
          var f1 = GeometryCollection(geometries: [
            Point(coordinates: Position.of([0, 0]))
          ]);
          var f2 = GeometryCollection(geometries: [
            Point(coordinates: Position.of([0, 0])),
            Point(coordinates: Position.of([0, 0]))
          ]);
          var eq = Equality();
          expect(eq.compare(f1, f2), false);

          // will not be equal with different geometries
          f1 = GeometryCollection(geometries: [
            Point(coordinates: Position.of([0, 0]))
          ]);
          f2 = GeometryCollection(geometries: [
            Point(coordinates: Position.of([1, 1]))
          ]);
          eq = Equality();
          expect(eq.compare(f1, f2), false);

// will not be equal with different order of geometries
          f1 = GeometryCollection(geometries: [
            Point(coordinates: Position.of([0, 0])),
            Point(coordinates: Position.of([1, 1]))
          ]);
          f2 = GeometryCollection(geometries: [
            Point(coordinates: Position.of([1, 1])),
            Point(coordinates: Position.of([0, 0]))
          ]);
          eq = Equality();
          expect(eq.compare(f1, f2), false);

          // will be equal with equal geometries
          f1 = GeometryCollection(geometries: [
            Point(coordinates: Position.of([0, 0]))
          ]);
          f2 = GeometryCollection(geometries: [
            Point(coordinates: Position.of([0, 0]))
          ]);
          eq = Equality();
          expect(eq.compare(f1, f2), true);

          // will be equal with equal with no geometries
          f1 = GeometryCollection(geometries: []);
          f2 = GeometryCollection(geometries: []);
          eq = Equality();
          expect(eq.compare(f1, f2), true);

          // will not be equal if one has bbox and other not
          f1 = GeometryCollection(geometries: [], bbox: BBox(1, 2, 3, 4));
          f2 = GeometryCollection(geometries: []);
          eq = Equality();
          expect(eq.compare(f1, f2), false);
// will not be equal if bboxes are not equal
          f1 = GeometryCollection(geometries: [], bbox: BBox(1, 2, 3, 4));
          f2 = GeometryCollection(geometries: [], bbox: BBox(1, 2, 3, 5));
          eq = Equality();
          expect(eq.compare(f1, f2), false);
// equal geometry collections with bboxes
          f1 = GeometryCollection(geometries: [
            Polygon(coordinates: [
              [
                Position.of([30, 10]),
                Position.of([41, 40]),
                Position.of([20, 40]),
                Position.of([10, 20]),
                Position.of([30, 10])
              ]
            ], bbox: BBox(10, 10, 41, 40)),
          ]);
          f2 = GeometryCollection(geometries: [
            Polygon(coordinates: [
              [
                Position.of([30, 10]),
                Position.of([41, 40]),
                Position.of([20, 40]),
                Position.of([10, 20]),
                Position.of([30, 10])
              ]
            ])
          ], bbox: BBox(10, 10, 41, 40));
          eq = Equality();
          expect(eq.compare(f1, f2), true);
          // not equal geometries with equal bboxes
          f1 = GeometryCollection(geometries: [
            Polygon(coordinates: [
              [
                Position.of([30, 10]),
                Position.of([41, 40]),
                Position.of([20, 40]),
                Position.of([10, 20]),
                Position.of([30, 10])
              ]
            ], bbox: BBox(10, 10, 41, 40))
          ]);
          f2 = GeometryCollection(geometries: [
            Polygon(coordinates: [
              [
                Position.of([30, 10]),
                Position.of([41, 40]),
                Position.of([20, 40]),
                Position.of([10, 20]),
                Position.of([30, 1])
              ]
            ])
          ], bbox: BBox(10, 10, 41, 40));
          eq = Equality();
          expect(eq.compare(f1, f2), true);
        },
      );
    },
  );
}

/**
   * var expect = require('chai').expect,
  Equality = require('../');
describe('geojson-equality for Points', function() {
  var g1 = { "type": "Point", "coordinates": [30, 10] },
    g2 = { "type": "Point", "coordinates": [30, 10] },
    g3 = { "type": "Point", "coordinates": [30, 11] },
    g4 = { "type": "Point", "coordinates": [30, 10, 5]},
    g5 = { "type": "Point", "coordinates": [30, 10, 5]},
    eq = new Equality();
  it('are equal', function() {
    expect(eq.compare(g1,g2)).to.be.true;
  });
  it('are not equal', function() {
    expect(eq.compare(g1,g3)).to.be.false;
  });
  it('are not equal with different point dimensions', function() {
    expect(eq.compare(g1,g4)).to.be.false;
  });
  it('are equal with 3d points', function() {
    expect(eq.compare(g4,g5)).to.be.true;
  });
});
describe('geojson-equality for LineStrings', function() {
  var g1 = { "type": "LineString", "coordinates":
    [ [30, 10], [10, 30], [40, 40] ] },
    g2 = { "type": "LineString", "coordinates":
      [ [30, 10], [10, 30], [40, 40] ] };
  it('are equal', function() {
    var eq = new Equality();
    expect(eq.compare(g1,g2)).to.be.true;
  });
  var g3 = { "type": "LineString", "coordinates":
    [ [31, 10], [10, 30], [40, 40] ] };
  it('are not equal', function() {
    var eq = new Equality();
    expect(eq.compare(g1,g3)).to.be.false;
  });
  var g4 = { "type": "LineString", "coordinates":
    [ [40, 40], [10, 30], [30, 10]] };
  it('reverse direction, direction is not matched, so both are equal', function() {
    var eq = new Equality();
    expect(eq.compare(g1,g4)).to.be.true;
  });
  it('reverse direction, direction is matched, so both are not equal', function() {
    var eq = new Equality({direction: true});
    expect(eq.compare(g1,g4)).to.be.false;
  });
});
describe('geojson-equality for Polygons', function() {
  var g1 = { "type": "Polygon", "coordinates": [
    [[30, 10], [40, 40], [20, 40], [10, 20], [30, 10]]
  ]};
  var g2 = { "type": "Polygon", "coordinates": [
    [[30, 10], [40, 40], [20, 40], [10, 20], [30, 10]]
  ]};
  it('are equal', function() {
    var eq = new Equality();
    expect(eq.compare(g1,g2)).to.be.true;
  });
  var g3 = { "type": "Polygon", "coordinates": [
    [[30, 10], [41, 40], [20, 40], [10, 20], [30, 10]]
  ]};
  it('are not equal', function() {
    var eq = new Equality();
    expect(eq.compare(g1,g3)).to.be.false;
  });
  var g4 = { "type": "Polygon", "coordinates": [
    [[30,10], [10,20], [20,40], [40,40], [30,10]]
  ]};
  it('reverse direction, direction is not matched, so both are equal', function() {
    var eq = new Equality();
    expect(eq.compare(g1,g4)).to.be.true;
  });
  it('reverse direction, direction is matched, so both are not equal', function() {
    var eq = new Equality({direction: true});
    expect(eq.compare(g1,g4)).to.be.false;
  });
  var g5 = { "type": "Polygon", "coordinates": [
    [[10,20], [20,40], [40,40], [30,10], [10,20]]
  ]};
  it('reverse direction, diff start index, direction is not matched, so both are equal',
  function() {
    var eq = new Equality();
    expect(eq.compare(g1,g5)).to.be.true;
  });
  it('reverse direction, diff start index, direction is matched, so both are not equal',
  function() {
    var eq = new Equality({direction: true});
    expect(eq.compare(g1,g5)).to.be.false;
  });
  var gh1 = { "type": "Polygon", "coordinates": [
    [[45, 45], [15, 40], [10, 20], [35, 10],[45, 45]],
    [[20, 30], [35, 35], [30, 20], [20, 30]]
  ]};
  var gh2 = { "type": "Polygon", "coordinates": [
    [[35, 10], [45, 45], [15, 40], [10, 20], [35, 10]],
    [[20, 30], [35, 35], [30, 20], [20, 30]]
  ]};
  it('have holes too and diff start ind, direction is not matched, both are equal',
  function() {
    var eq = new Equality({direction: false});
    expect(eq.compare(gh1,gh2)).to.be.true;
  });
  it('have holes too and diff start ind, direction is matched, so both are not equal',
  function() {
    var eq = new Equality({direction: true});
    expect(eq.compare(gh1,gh2)).to.be.true;
  });
  var gprecision1 = { "type": "Polygon", "coordinates": [
    [[30, 10], [40.12345, 40.12345], [20, 40], [10, 20], [30, 10]]
  ]};
  var gprecision2 = { "type": "Polygon", "coordinates": [
    [[30, 10], [40.123389, 40.123378], [20, 40], [10, 20], [30, 10]]
  ]};
  it('after limiting precision, are equal', function() {
    var eq = new Equality({precision: 3});
    expect(eq.compare(gprecision1,gprecision2)).to.be.true;
  });
  it('with high precision, are not equal', function() {
    var eq = new Equality({precision: 10});
    expect(eq.compare(gprecision1,gprecision2)).to.be.false;
  });

});

describe ('geojson-equality for Feature', function() {
  it ('will not be equal with changed id', function() {
    var f1 = {"type": "Feature", "id": "id1"};
    var f2 = {"type": "Feature", "id": "id2"};
    var eq = new Equality();
    expect(eq.compare(f1, f2)).to.be.false;
  });
  it ('will not be equal with different count of properties', function() {
    var f1 = {"type": "Feature", "id": "id1", "properties": {"foo": "bar"}};
    var f2 = {"type": "Feature", "id": "id1", "properties": {"foo1": "bar", "foo2": "bar"}};
    var eq = new Equality();
    expect(eq.compare(f1, f2)).to.be.false;
  });
  it ('will not be equal with different keys in properties', function() {
    var f1 = {"type": "Feature", "id": "id1", "properties": {"foo1": "bar"}};
    var f2 = {"type": "Feature", "id": "id1", "properties": {"foo2": "bar"}};
    var eq = new Equality();
    expect(eq.compare(f1, f2)).to.be.false;
  });
  it ('will not be equal with different properties', function() {
    var f1 = {"type": "Feature", "id": "id1", "properties": {"foo": "bar1"}};
    var f2 = {"type": "Feature", "id": "id1", "properties": {"foo": "bar2"}};
    var eq = new Equality();
    expect(eq.compare(f1, f2)).to.be.false;
  });
  it ('will not be equal with different geometry', function() {
    var f1 = {
      "type": "Feature",
      "id": "id1",
      "properties": {"foo": "bar1"},
      "geometry": { "type": "Polygon", "coordinates": [
        [[30, 10], [41, 40], [20, 40], [10, 20], [30, 10]]
      ]}
    };
    var f2 = {
      "type": "Feature",
      "id": "id1",
      "properties": {"foo": "bar1"},
      "geometry": { "type": "Polygon", "coordinates": [
        [[40, 20], [31, 10], [30, 20], [30, 10], [10, 40]]
      ]}
    };
    var eq = new Equality();
    expect(eq.compare(f1, f2)).to.be.false;
  });
  it ('will be equal with nested properties', function() {
    var f1 = {"type": "Feature", "id": "id1", "properties": {"foo": {"bar": "baz"}},
      "geometry": {"type": "Point", "coordinates": [0, 1]}
    };
    var f2 = {"type": "Feature", "id": "id1", "properties": {"foo": {"bar": "baz"}},
      "geometry": {"type": "Point", "coordinates": [0, 1]}
    };
    var eq = new Equality();
    expect(eq.compare(f1, f2)).to.be.true;
  });
  it ('will not be equal with different nested properties', function() {
    var f1 = {"type": "Feature", "id": "id1", "properties": {"foo": {"bar": "baz"}},
      "geometry": {"type": "Point", "coordinates": [0, 1]}
    };
    var f2 = {"type": "Feature", "id": "id1", "properties": {"foo": {"bar": "baz2"}},
      "geometry": {"type": "Point", "coordinates": [0, 1]}
    };
    var eq = new Equality();
    expect(eq.compare(f1, f2)).to.be.false;
  });
  it ('will use a custom comparator if provided', function() {
    var f1 = {
      "type": "Feature",
      "id": "id1",
      "properties": {"foo_123": "bar"},
      "geometry": { "type": "Polygon", "coordinates": [
        [[40, 20], [31, 10], [30, 20], [30, 10], [10, 40]]
      ]}
    };
    var f2 = {
      "type": "Feature",
      "id": "id1",
      "properties": {"foo_456": "bar"},
      "geometry": { "type": "Polygon", "coordinates": [
        [[40, 20], [31, 10], [30, 20], [30, 10], [10, 40]]
      ]}
    };
    var eq = new Equality({objectComparator: function(obj1, obj2) {
      return ('foo_123' in obj1 && 'foo_456' in obj2);
    }});
    expect(eq.compare(f1, f2)).to.be.true;
  });
  it ('will not be equal if one has bbox and other not', function() {
    var f1 = {"type": "Feature", "id": "id1", "bbox": [1, 2, 3, 4]},
      f2 = {"type": "Feature", "id": "id1"},
      eq = new Equality();
    expect(eq.compare(f1, f2)).to.be.false;
  });
  it ('will not be equal if bboxes are not equal', function() {
    var f1 = {"type": "Feature", "id": "id1", "bbox": [1, 2, 3, 4]},
      f2 = {"type": "Feature", "id": "id1", "bbox": [1, 2, 3, 5]},
      eq = new Equality();
    expect(eq.compare(f1, f2)).to.be.false;
  });
  it ('equal features with bboxes', function() {
    var f1 = {
      "type": "Feature",
      "id": "id1",
      "properties": {"foo": "bar1"},
      "geometry": { "type": "Polygon", "coordinates": [
        [[30, 10], [41, 40], [20, 40], [10, 20], [30, 10]]
      ]},
      "bbox": [10, 10, 41, 40]
    };
    var f2 = {
      "type": "Feature",
      "id": "id1",
      "properties": {"foo": "bar1"},
      "geometry": { "type": "Polygon", "coordinates": [
        [[30, 10], [41, 40], [20, 40], [10, 20], [30, 10]]
      ]},
      "bbox": [10, 10, 41, 40]
    };
    var eq = new Equality();
    expect(eq.compare(f1, f2)).to.be.true;
  });
  it ('not equal features with equal bboxes', function() {
    var f1 = {
      "type": "Feature",
      "id": "id1",
      "properties": {"foo": "bar1"},
      "geometry": { "type": "Polygon", "coordinates": [
        [[30, 10], [41, 40], [20, 40], [10, 20], [30, 10]]
      ]},
      "bbox": [10, 10, 41, 40]
    };
    var f2 = {
      "type": "Feature",
      "id": "id1",
      "properties": {"foo": "bar1"},
      "geometry": { "type": "Polygon", "coordinates": [
        [[30, 10], [41, 40], [20, 40], [10, 20], [30, 1]]
      ]},
      "bbox": [10, 10, 41, 40]
    };
    var eq = new Equality();
    expect(eq.compare(f1, f2)).to.be.false;
  });
});

describe ('geojson-equality for FeatureCollection', function() {
  it ('will not be equal with different number of features', function() {
    var f1 = {
      "type": "FeatureCollection",
      "features": [{
        "type": "Feature",
        "geometry": { "type": "Point", "coordinates": [0, 0] }
      }]
    };
    var f2 = {
      "type": "FeatureCollection",
      "features": [{
        "type": "Feature",
        "geometry": { "type": "Point", "coordinates": [0, 0] }
      },{
        "type": "Feature",
        "geometry": { "type": "Point", "coordinates": [0, 0] }
      }]
    };
    var eq = new Equality();
    expect(eq.compare(f1, f2)).to.be.false;
  });
  it ('will not be equal with different features', function() {
    var f1 = {
      "type": "FeatureCollection",
      "features": [{
        "type": "Feature",
        "geometry": { "type": "Point", "coordinates": [0, 0] }
      }]
    };
    var f2 = {
      "type": "FeatureCollection",
      "features": [{
        "type": "Feature",
        "geometry": { "type": "Point", "coordinates": [1, 1] }
      }]
    };
    var eq = new Equality();
    expect(eq.compare(f1, f2)).to.be.false;
  });
  it ('will not be equal with different order of features', function() {
    var f1 = {
      "type": "FeatureCollection",
      "features": [{
        "type": "Feature",
        "geometry": { "type": "Point", "coordinates": [0, 0] }
      },{
        "type": "Feature",
        "geometry": { "type": "Point", "coordinates": [1, 1] }
      }]
    };
    var f2 = {
      "type": "FeatureCollection",
      "features": [{
        "type": "Feature",
        "geometry": { "type": "Point", "coordinates": [1, 1] }
      },{
        "type": "Feature",
        "geometry": { "type": "Point", "coordinates": [0, 0] }
      }]
    };
    var eq = new Equality();
    expect(eq.compare(f1, f2)).to.be.false;
  });
  it ('will be equal with equal features', function() {
    var f1 = {
      "type": "FeatureCollection",
      "features": [{
        "type": "Feature",
        "geometry": { "type": "Point", "coordinates": [1, 1] }
      }]
    };
    var f2 = {
      "type": "FeatureCollection",
      "features": [{
        "type": "Feature",
        "geometry": { "type": "Point", "coordinates": [1, 1] }
      }]
    };
    var eq = new Equality();
    expect(eq.compare(f1, f2)).to.be.true;
  });
  it ('will be equal with equal with no features', function() {
    var f1 = {
      "type": "FeatureCollection",
      "features": []
    };
    var f2 = {
      "type": "FeatureCollection",
      "features": []
    };
    var eq = new Equality();
    expect(eq.compare(f1, f2)).to.be.true;
  });
  it ('will use a custom comparator if provided', function() {
    var f1 = {
      "type": "FeatureCollection",
      "features": [{
        "type": "Feature",
        "id": "id1",
        "properties": {"foo_123": "bar"},
        "geometry": { "type": "Polygon", "coordinates": [
          [[40, 20], [31, 10], [30, 20], [30, 10], [10, 40]]
        ]}
      }]
    };
    var f2 = {
      "type": "FeatureCollection",
      "features": [{
        "type": "Feature",
        "id": "id1",
        "properties": {"foo_456": "bar"},
        "geometry": { "type": "Polygon", "coordinates": [
          [[40, 20], [31, 10], [30, 20], [30, 10], [10, 40]]
        ]}
      }]
    };
    var eq = new Equality({objectComparator: function(obj1, obj2) {
      return ('foo_123' in obj1 && 'foo_456' in obj2);
    }});
    expect(eq.compare(f1, f2)).to.be.true;
  });
  it ('will not be equal if one has bbox and other not', function() {
    var f1 = {"type": "FeatureCollection", "features": [], "bbox": [1, 2, 3, 4]},
      f2 = {"type": "FeatureCollection", "features": "[]"},
      eq = new Equality();
    expect(eq.compare(f1, f2)).to.be.false;
  });
  it ('will not be equal if bboxes are not equal', function() {
    var f1 = {"type": "FeatureCollection", "features": [], "bbox": [1, 2, 3, 4]},
      f2 = {"type": "FeatureCollection", "features": [], "bbox": [1, 2, 3, 5]},
      eq = new Equality();
    expect(eq.compare(f1, f2)).to.be.false;
  });
  it ('equal feature collections with bboxes', function() {
    var f1 = {
      "type": "FeatureCollection",
      "features": [{
        "type": "Feature",
        "id": "id1",
        "properties": {"foo": "bar1"},
        "geometry": { "type": "Polygon", "coordinates": [
          [[30, 10], [41, 40], [20, 40], [10, 20], [30, 10]]
        ]}
      }],
      "bbox": [10, 10, 41, 40]
    };
    var f2 = {
      "type": "FeatureCollection",
      "features": [{
        "type": "Feature",
        "id": "id1",
        "properties": {"foo": "bar1"},
        "geometry": { "type": "Polygon", "coordinates": [
          [[30, 10], [41, 40], [20, 40], [10, 20], [30, 10]]
        ]}
      }],
      "bbox": [10, 10, 41, 40]
    };
    var eq = new Equality();
    expect(eq.compare(f1, f2)).to.be.true;
  });
  it ('not equal features with equal bboxes', function() {
    var f1 = {
      "type": "FeatureCollection",
      "features": [{
        "type": "Feature",
        "id": "id1",
        "properties": {"foo": "bar1"},
        "geometry": { "type": "Polygon", "coordinates": [
          [[30, 10], [41, 40], [20, 40], [10, 20], [30, 10]]
        ]}
      }],
      "bbox": [10, 10, 41, 40]
    };
    var f2 = {
      "type": "FeatureCollection",
      "features": [{
        "type": "Feature",
        "id": "id1",
        "properties": {"foo": "bar1"},
        "geometry": { "type": "Polygon", "coordinates": [
          [[30, 10], [41, 40], [20, 40], [10, 20], [30, 1]]
        ]}
      }],
      "bbox": [10, 10, 41, 40]
    };
    var eq = new Equality();
    expect(eq.compare(f1, f2)).to.be.false;
  });
});

describe('geojson-equality for MultiPoints', function() {
  var g1 = { "type": "MultiPoint", "coordinates": [
    [0, 40], [40, 30], [20, 20], [30, 10]
  ]};
  var g2 = { "type": "MultiPoint", "coordinates": [
    [0, 40], [20, 20], [40, 30], [30, 10]
  ]};
  it('are equal', function() {
    var eq = new Equality();
    expect(eq.compare(g1,g2)).to.be.true;
  });
  var g3 = { "type": "MultiPoint", "coordinates": [
    [10, 40], [20, 20], [40, 30], [30, 10]
  ]};
  it('are not equal', function() {
    var eq = new Equality();
    expect(eq.compare(g1,g3)).to.be.false;
  });
});

describe('geojson-equality for MultiLineString', function() {
  var g1 = { "type": "MultiLineString", "coordinates": [
    [[30, 10], [10, 30], [40, 40]],
    [[0, 10], [10, 0], [40, 40]]
  ]};
  var g2 = { "type": "MultiLineString", "coordinates": [
    [[40, 40],[10, 30], [30, 10]],
    [[0, 10], [10, 0], [40, 40]]
  ]};
  it('reverse direction, direction is not matched, so both are equal',
    function() {
      var eq = new Equality();
      expect(eq.compare(g1,g2)).to.be.true;
    }
  );
  it('reverse direction, direction is matched, so both are not equal',
    function() {
      var eq = new Equality({direction: true});
      expect(eq.compare(g1,g2)).to.be.false;
    }
  );
  var g3 = { "type": "MultiLineString", "coordinates": [
    [[10, 10], [20, 20], [10, 40]],
    [[40, 40], [30, 30], [40, 20], [30, 10]] ] };
  it('both are not equal',
    function() {
      var eq = new Equality();
      expect(eq.compare(g1,g3)).to.be.false;
    }
  );
});
describe('geojson-equality for MultiPolygon', function() {
  var g1 = { "type": "MultiPolygon", "coordinates": [
    [[[30, 20], [45, 40], [10, 40], [30, 20]]],
    [[[15, 5], [40, 10], [10, 20], [5, 10], [15, 5]]]
  ]};
  var g2 = { "type": "MultiPolygon", "coordinates": [
    [[[30, 20], [45, 40], [10, 40], [30, 20]]],
    [[[15, 5], [40, 10], [10, 20], [5, 10], [15, 5]]]
  ]};
  it('both are equal', function() {
    var eq = new Equality();
    expect(eq.compare(g1,g2)).to.be.true;
  });
  var g3 = { "type": "MultiPolygon", "coordinates": [
    [[[30, 20], [45, 40], [10, 40], [30, 20]]],
    [[[15, 5], [400, 10], [10, 20], [5, 10], [15, 5]]]
  ]};
  it('both are not equal', function() {
    var eq = new Equality();
    expect(eq.compare(g1,g3)).to.be.false;
  });
  var gh1 = { "type": "MultiPolygon", "coordinates": [
    [[[40, 40], [20, 45], [45, 30], [40, 40]]],
    [
      [[20, 35], [10, 30], [10, 10], [30, 5], [45, 20], [20, 35]],
      [[30, 20], [20, 15], [20, 25], [30, 20]],
      [[20, 10], [30, 10], [30, 15], [20, 10]]
    ]
  ]};
  var gh2 = { "type": "MultiPolygon", "coordinates": [
    [
      [[20, 35], [10, 30], [10, 10], [30, 5], [45, 20], [20, 35]],
      [[20, 10], [30, 10], [30, 15], [20, 10]],
      [[30, 20], [20, 15], [20, 25], [30, 20]]
    ],
    [[[40, 40], [20, 45], [45, 30], [40, 40]]]
  ]};
  it('having holes, both are equal', function() {
    var eq = new Equality();
    expect(eq.compare(gh1,gh2)).to.be.true;
  });
});

describe ('geojson-equality for GeometryCollection', function() {
  it ('will not be equal with different number of geometries', function() {
    var f1 = {
      "type": "GeometryCollection",
      "geometries": [{ "type": "Point", "coordinates": [0, 0] }]
    };
    var f2 = {
      "type": "GeometryCollection",
      "geometries": [
        { "type": "Point", "coordinates": [0, 0] },
        { "type": "Point", "coordinates": [0, 0] }
      ]
    };
    var eq = new Equality();
    expect(eq.compare(f1, f2)).to.be.false;
  });
  it ('will not be equal with different geometries', function() {
    var f1 = {
      "type": "GeometryCollection",
      "geometries": [{ "type": "Point", "coordinates": [0, 0] }]
    };
    var f2 = {
      "type": "GeometryCollection",
      "geometries": [{ "type": "Point", "coordinates": [1, 1] }]
    };
    var eq = new Equality();
    expect(eq.compare(f1, f2)).to.be.false;
  });
  it ('will not be equal with different order of geometries', function() {
    var f1 = {
      "type": "GeometryCollection",
      "geometries": [
        { "type": "Point", "coordinates": [0, 0] },
        { "type": "Point", "coordinates": [1, 1] }
      ]
    };
    var f2 = {
      "type": "GeometryCollection",
      "geometries": [
        { "type": "Point", "coordinates": [1, 1] },
        { "type": "Point", "coordinates": [0, 0] }
      ]
    };
    var eq = new Equality();
    expect(eq.compare(f1, f2)).to.be.false;
  });
  it ('will be equal with equal geometries', function() {
    var f1 = {
      "type": "GeometryCollection",
      "geometries": [{ "type": "Point", "coordinates": [0, 0] }]
    };
    var f2 = {
      "type": "GeometryCollection",
      "geometries": [{ "type": "Point", "coordinates": [0, 0] }]
    };
    var eq = new Equality();
    expect(eq.compare(f1, f2)).to.be.true;
  });
  it ('will be equal with equal with no geometries', function() {
    var f1 = {
      "type": "GeometryCollection",
      "geometries": []
    };
    var f2 = {
      "type": "GeometryCollection",
      "geometries": []
    };
    var eq = new Equality();
    expect(eq.compare(f1, f2)).to.be.true;
  });
  it ('will not be equal if one has bbox and other not', function() {
    var f1 = {"type": "GeometryCollection", "geometries": [], "bbox": [1, 2, 3, 4]},
      f2 = {"type": "GeometryCollection", "geometries": "[]"},
      eq = new Equality();
    expect(eq.compare(f1, f2)).to.be.false;
  });
  it ('will not be equal if bboxes are not equal', function() {
    var f1 = {"type": "GeometryCollection", "geometries": [], "bbox": [1, 2, 3, 4]},
      f2 = {"type": "GeometryCollection", "geometries": [], "bbox": [1, 2, 3, 5]},
      eq = new Equality();
    expect(eq.compare(f1, f2)).to.be.false;
  });
  it ('equal geometry collections with bboxes', function() {
    var f1 = {
      "type": "GeometryCollection",
      "geometries": [{ "type": "Polygon", "coordinates": [
          [[30, 10], [41, 40], [20, 40], [10, 20], [30, 10]]
        ]}
      ],
      "bbox": [10, 10, 41, 40]
    };
    var f2 = {
      "type": "GeometryCollection",
      "geometries": [{ "type": "Polygon", "coordinates": [
          [[30, 10], [41, 40], [20, 40], [10, 20], [30, 10]]
        ]}
      ],
      "bbox": [10, 10, 41, 40]
    };
    var eq = new Equality();
    expect(eq.compare(f1, f2)).to.be.true;
  });
  it ('not equal geometries with equal bboxes', function() {
    var f1 = {
      "type": "GeometryCollection",
      "geometries": [{ "type": "Polygon", "coordinates": [
          [[30, 10], [41, 40], [20, 40], [10, 20], [30, 10]]
        ]}
      ],
      "bbox": [10, 10, 41, 40]
    };
    var f2 = {
      "type": "GeometryCollection",
      "geometries": [{ "type": "Polygon", "coordinates": [
          [[30, 10], [41, 40], [20, 40], [10, 20], [30, 1]]
        ]}
      ],
      "bbox": [10, 10, 41, 40]
    };
    var eq = new Equality();
    expect(eq.compare(f1, f2)).to.be.false;
  });
});
   */
