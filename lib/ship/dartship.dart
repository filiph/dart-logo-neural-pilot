library dart_summit_2016.ship.dartship;

import 'package:box2d/box2d.dart';
import 'package:vector_math/vector_math_64.dart' show radians, Matrix2;
import 'package:dart_summit_2016/ship/thruster.dart';
import 'package:dart_summit_2016/ship/revolute_part.dart';
import 'package:dart_summit_2016/angle_utils.dart';

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
  List<RevolutePart> revoluteParts;

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

    revoluteParts = thrusters
        .map((t) => t.revolutePart)
        .where((p) => p != null)
        .toList(growable: false);

    leftLeg.currentAngleNormalized = 0.0;
    rightLeg.currentAngleNormalized = 0.0;
    leftFlap.currentAngleNormalized = 0.0;
    rightFlap.currentAngleNormalized = 0.0;
  }

  void step() {
    for (var thruster in thrusters) {
      thruster.applyCurrentPower(body);

      // DEBUG
      final thrust = thruster.getWorldForce(thruster.currentPower, body);

      _world.debugDraw.drawSegment(
          thrust.point.clone(),
          thrust.point.clone().add(thrust.force),
          new Color3i.fromRGBd(0.0, 0.0, 250.0));
    }
  }

  final Vector2 _zeroVector = new Vector2.zero();
  final Vector2 _forwardVector = new Vector2(0.0, 1.0);

  Vector2 getRelativeVectorTo(Vector2 targetPosition) =>
      body.getLocalPoint(targetPosition);

  num getAngleTo(Vector2 targetPosition) {
    Vector2 relativeVectorToTarget = getRelativeVectorTo(targetPosition);
    return angle(relativeVectorToTarget, _forwardVector);
  }

  /*
   * The angle at which [this] is moving towards/away from [target]. For
   * example, when this ship is aproaching target straight on, the velocity
   * angle would be 180° (pi).
   */
  num getVelocityAngleOf(Vector2 target) {
    Vector2 relativeVector = getRelativeVectorTo(target);
    Vector2 relativeVelocity =
        body.getLinearVelocityFromLocalPoint(_zeroVector);
    if (relativeVelocity.length2 == 0.0) return 0.0;
    return angle(relativeVelocity, relativeVector);
  }
}
