import 'package:box2d/box2d.dart';
import 'package:vector_math/vector_math_64.dart' show radians, Matrix2;

class DartShip {
  Body get body => _body;
  Body _body;
  // Body _leftPaw;
  // Body _rightPaw;
  // RevoluteJoint _rightPawJoint;
  final World _world;

  RevolutePart leftFlap;
  Thruster frontLeftThruster;
  RevolutePart rightFlap;
  Thruster frontRightThruster;

  Vector2 get position => _body.getWorldPoint(new Vector2.zero());

  // num get rightPawAngle =>
  // (_rightPawJoint.getJointAngle() / DEGREES_TO_RADIANS).toInt();

  // static final List<Vector2> DART_LOGO_CORE = <Vector2>[
  //   new Vector2(0.0, -5.7),
  //   new Vector2(-4.9, -4.6),
  //   new Vector2(-5.0, -1.9),
  //   new Vector2(-1.6, 5.3),
  //   new Vector2(0.0, 5.9),
  //   new Vector2(1.6, 5.3),
  //   new Vector2(5.0, -1.9),
  //   new Vector2(4.9, -4.6)
  // ];
  //
  // static final List<Vector2> DART_LOGO_LEFT_PAW = <Vector2>[
  //   new Vector2(-4.6, -0.9),
  //   new Vector2(-5.0, 0.0),
  //   new Vector2(-5.1, 3.4),
  //   new Vector2(-1.7, 6.8),
  //   // new Vector2(-0.0, 5.9),
  //   new Vector2(-1.6, 5.3)
  // ];

  DartShip(this._world) {
    final PolygonShape shape = new PolygonShape();
    // shape.set(DART_LOGO_CORE, DART_LOGO_CORE.length);
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

    leftFlap = new RevolutePart(-4.7, -4.3, radians(120.0));
    frontLeftThruster = new Thruster(0, 2, 0, 2, revolutePart: leftFlap);

    rightFlap = new RevolutePart(4.7, -4.3, -radians(120.0));
    frontRightThruster = new Thruster(0, 2, 0, -2, revolutePart: rightFlap);

    // // Define left paw, reuse the PolygonShape object.
    // shape.set(DART_LOGO_LEFT_PAW, DART_LOGO_LEFT_PAW.length);
    // final BodyDef pawBodyDef = new BodyDef();
    // pawBodyDef.type = BodyType.KINEMATIC;
    // _leftPaw = _world.createBody(pawBodyDef);
    // _leftPaw.createFixtureFromFixtureDef(activeFixtureDef);
    //
    // final RevoluteJointDef pawJointDef = new RevoluteJointDef();
    // pawJointDef.initialize(_body, _leftPaw, new Vector2(-4.6, -0.9));
    // pawJointDef.referenceAngle = 0.0;
    // pawJointDef.enableLimit = true;
    // pawJointDef.lowerAngle = -1.0;
    // pawJointDef.upperAngle = 30 * DEGREES_TO_RADIANS;
    // // pawJointDef.enableMotor = false;
    // // pawJointDef.maxMotorTorque = 0.0;
    // // pawJointDef.motorSpeed = 0.0;
    //
    // _world.createJoint(pawJointDef);
    //
    // // Define right paw, reuse the PolygonShape object.
    // shape.set(
    //     DART_LOGO_LEFT_PAW
    //         .map((v) => new Vector2(-v.x, v.y))
    //         .toList(growable: false),
    //     DART_LOGO_LEFT_PAW.length);
    // _rightPaw = _world.createBody(pawBodyDef);
    // _rightPaw.createFixtureFromFixtureDef(activeFixtureDef);
    // pawJointDef.initialize(_body, _rightPaw, new Vector2(4.6, -0.9));
    // pawJointDef.referenceAngle = 0.0;
    // pawJointDef.lowerAngle = -30 * DEGREES_TO_RADIANS;
    // pawJointDef.upperAngle = 1.0;
    // _rightPawJoint = _world.createJoint(pawJointDef);

    // _body.setTransform(position, initialAngle.toDouble());
  }
}

class Force {
  final Vector2 point;
  final Vector2 force;
  const Force(this.force, this.point);
  Force.worldFromLocal(Force local, Body body)
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
    return revolutePart.jointPosition.clone().add(rotatedPosition);
  }

  Vector2 getLocalThrustVector(num power) {
    return _rotation.transformed(maxForce);
  }

  Force getForce(num power) {
    var locPosition = localPosition;
    var thrust = getLocalThrustVector(power);
    return new Force(thrust, locPosition);
  }

  Force getWorldForce(num power, Body body) {
    return new Force.worldFromLocal(getForce(power), body);
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
