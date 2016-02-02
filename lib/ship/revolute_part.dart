library dart_summit_2016.ship.revolute_part;

import 'package:box2d/box2d.dart';

class RevolutePart {
  final Vector2 jointPosition;
  final double maxAngle;

  double _currentAngle = 0.0;

  static const double MAX_STEP_CHANGE = 0.05;

  double get currentAngle => _currentAngle;
  set currentAngle(double value) {
    if (currentAngle < 0 && maxAngle >= 0) _currentAngle = 0.0;
    if (currentAngle > 0 && maxAngle <= 0) _currentAngle = 0.0;
    if (maxAngle >= 0) {
      if (value < 0) _currentAngle = 0.0;
      else if (value > maxAngle) _currentAngle = maxAngle;
      else _currentAngle = value;
    } else {
      if (value > 0) _currentAngle = 0.0;
      else if (value < maxAngle) _currentAngle = maxAngle;
      else _currentAngle = value;
    }
  }

  double get currentAngleNormalized => (_currentAngle / maxAngle);
  set currentAngleNormalized(double value) {
    assert(value >= 0 && value <= 1.0);
    _currentAngle = maxAngle * value;
  }

  RevolutePart(num x, num y, this.maxAngle)
      : jointPosition = new Vector2(x.toDouble(), y.toDouble()) {
    assert(maxAngle != 0);
  }

  void moveToDesiredAngleNormalized(double value,
      {double maxChange: MAX_STEP_CHANGE}) {
    assert(value >= 0 && value <= 1.0);
    double desiredAngle = maxAngle * value;
    _currentAngle +=
        (desiredAngle - _currentAngle).clamp(-maxChange, maxChange);
  }
}
