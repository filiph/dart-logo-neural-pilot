library dart_summit_2016.ship.thruster;

import 'package:box2d/box2d.dart';
import 'package:dart_summit_2016/ship/thurst.dart';
import 'package:dart_summit_2016/ship/revolute_part.dart';

class Thruster {
  static const double MAX_STEP_CHANGE = 0.05;

  final Vector2 _position;
  final Vector2 maxForce;
  final RevolutePart revolutePart;

  double _currentPower = 0.0;
  double get currentPower => _currentPower;

  Thruster(num x, num y, num maxForwardThrust, num maxLateralThrust,
      {this.revolutePart})
      : _position = new Vector2(x.toDouble(), y.toDouble()),
        maxForce = new Vector2(
            maxLateralThrust.toDouble(), maxForwardThrust.toDouble());

  static final NO_ROTATION = new Matrix2.rotation(0.0);

  Matrix2 get _rotation {
    if (revolutePart == null) return NO_ROTATION;
    return new Matrix2.rotation(revolutePart.currentAngle);
  }

  Vector2 get localPosition {
    var rotatedPosition = _rotation.transformed(_position);
    if (revolutePart != null) {
      return revolutePart.jointPosition.clone().add(rotatedPosition);
    } else {
      return rotatedPosition;
    }
  }

  void moveToDesiredPower(double value, {double maxChange: MAX_STEP_CHANGE}) {
    assert(value >= 0.0 && value <= 1.0);
    _currentPower += (value - _currentPower).clamp(-maxChange, maxChange);
  }

  Vector2 getLocalThrustVector(num power) {
    return _rotation.transformed(maxForce.scaled(power));
  }

  Thrust getForce(num power) {
    var locPosition = localPosition;
    var thrust = getLocalThrustVector(power);
    return new Thrust(thrust, locPosition);
  }

  Thrust getWorldForce(num power, Body body) {
    return new Thrust.worldFromLocal(getForce(power), body);
  }

  void applyCurrentPower(Body body) {
    final thrust = getWorldForce(_currentPower, body);
    body.applyForce(thrust.force, thrust.point);
  }
}
