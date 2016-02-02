library dart_summit_2016.angle_utils;

import 'dart:math' as Math;

import 'package:box2d/box2d.dart';
import 'package:vector_math/vector_math_64.dart';

final Matrix2 _rightAngleRotation = new Matrix2.rotation(radians(90.0));

double angle(Vector2 a, Vector2 b) {
  if (a.length2 == 0.0 || b.length2 == 0.0) {
    throw new ArgumentError("Cannot compute angle from a zero vector.");
  }
  var rightAngleB = _rightAngleRotation.transformed(b);
  return Math.acos(a.dot(b) / (b.length * a.length)) *
      (a.dot(rightAngleB) > 0 ? 1 : -1);
}
