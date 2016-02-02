import "package:test/test.dart";

import 'package:box2d/box2d.dart';

import 'package:dart_summit_2016/angle_utils.dart';
import 'package:vector_math/vector_math_64.dart';

final Vector2 up = new Vector2(0.0, 1.0);
final Vector2 right = new Vector2(1.0, 0.0);
final Vector2 left = new Vector2(-1.0, 0.0);
final Vector2 down = new Vector2(0.0, -1.0);
final Vector2 upRight = new Vector2(1.0, 1.0);

const double MAX_DELTA = 0.0001;

void expectAngle(Vector2 a, Vector2 b, num expectedResult) {
  expect(angle(a, b), closeTo(radians(expectedResult.toDouble()), MAX_DELTA));
}

void main() {
  group("angle()", () {
    test("computes 0", () {
      expectAngle(up, up, 0);
    });
    test("computes 45", () {
      expectAngle(up, upRight, 45);
    });
    test("computes 90", () {
      expectAngle(up, right, 90);
    });
    test("computes 180", () {
      expect(
          angle(up, down),
          anyOf(closeTo(radians(180.0), MAX_DELTA),
              closeTo(radians(-180.0), MAX_DELTA)));
    });
    test("computes -90", () {
      expectAngle(up, left, -90);
    });
    test("computes 45 even when one vector is scaled up", () {
      expectAngle(up, new Vector2(1000.0, 1000.0), 45);
    });
    test("throws on zero vector a", () {
      expect(() => angle(new Vector2(0.0, 0.0), up), throwsArgumentError);
    });
    test("throws on zero vector b", () {
      expect(() => angle(down, new Vector2(0.0, 0.0)), throwsArgumentError);
    });
  });
}
