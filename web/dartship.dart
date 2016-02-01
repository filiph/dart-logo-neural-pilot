import 'package:box2d/box2d.dart';
import 'package:vector_math/vector_math_64.dart' show radians, Matrix2;

class DartShip {
  Body get body => _body;
  Body _body;
  final World _world;

  Thruster mainThruster;

  RevolutePart leftLeg;
  Thruster leftLegThruster;
  RevolutePart rightLeg;
  Thruster rightLegThruster;
  RevolutePart leftFlap;
  Thruster frontLeftThruster;
  RevolutePart rightFlap;
  Thruster frontRightThruster;

  List<Thruster> thrusters;

  Vector2 get position => _body.getWorldPoint(new Vector2.zero());

  DartShip(this._world) {
    final PolygonShape shape = new PolygonShape();
    shape.setAsBoxXY(9.8 / 2, 11.7 / 2);

    // Fixture links body and shape
    final FixtureDef activeFixtureDef = new FixtureDef();
    activeFixtureDef.restitution = 0.5;
    activeFixtureDef.density = 0.05;
    activeFixtureDef.shape = shape;

    // Define main body
    final BodyDef mainBodyDef = new BodyDef();
    mainBodyDef.type = BodyType.DYNAMIC;
    // Reality is unrealistic - so we want even "space" to have some damping
    // in order to "feel real".
    mainBodyDef.linearDamping = 0.1;
    mainBodyDef.angularDamping = 0.2;
    mainBodyDef.position = new Vector2.zero();

    // Create body and fixture from definitions
    _body = _world.createBody(mainBodyDef);
    _body.createFixtureFromFixtureDef(activeFixtureDef);

    mainThruster = new Thruster(0.0, 5.9, -5.0 /* 20 */, 0.0);

    leftLeg = new RevolutePart(-4.6, -0.9, radians(30.0));
    leftLegThruster = new Thruster(1.4, 6.2, -2, 2, revolutePart: leftLeg);

    rightLeg = new RevolutePart(4.6, -0.9, radians(-30.0));
    rightLegThruster = new Thruster(-1.4, 6.2, -2, -2, revolutePart: rightLeg);

    leftFlap = new RevolutePart(-4.7, -4.3, radians(120.0));
    frontLeftThruster = new Thruster(0, 2, 0, 2, revolutePart: leftFlap);

    rightFlap = new RevolutePart(4.7, -4.3, radians(-120.0));
    frontRightThruster = new Thruster(0, 2, 0, -2, revolutePart: rightFlap);

    thrusters = <Thruster>[
      mainThruster,
      leftLegThruster,
      rightLegThruster,
      frontLeftThruster,
      frontRightThruster
    ];

    leftLeg.currentAngleNormalized = 1.0;
    rightLeg.currentAngleNormalized = 0.0;
    leftFlap.currentAngleNormalized = 0.0;
    rightFlap.currentAngleNormalized = 0.0;
  }

  void step() {
    for (var thruster in thrusters) {
      final thrust = thruster.getWorldForce(1.0, body);
      body.applyForce(thrust.force, thrust.point);

      _world.debugDraw.drawSegment(
          thrust.point.clone(),
          thrust.point.clone().add(thrust.force),
          new Color3i.fromRGBd(0.0, 0.0, 250.0));
    }
  }
}

class Thrust {
  final Vector2 point;
  final Vector2 force;
  const Thrust(this.force, this.point);
  Thrust.worldFromLocal(Thrust local, Body body)
      : this(body.getWorldVector(local.force), body.getWorldPoint(local.point));
}

class Thruster {
  final Vector2 _position;
  final Vector2 maxForce;
  final RevolutePart revolutePart;
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
}

class RevolutePart {
  final Vector2 jointPosition;
  final double maxAngle;

  double _currentAngle = 0.0;
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
    assert(value >= 0 && value <= maxAngle);
    _currentAngle = maxAngle * value;
  }

  RevolutePart(num x, num y, this.maxAngle)
      : jointPosition = new Vector2(x.toDouble(), y.toDouble()) {
    assert(maxAngle != 0);
  }
}
