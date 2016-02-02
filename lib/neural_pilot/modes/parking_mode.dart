library dart_summit_2016.neural_pilot.mode.parking;

import 'dart:math' as Math;

import 'package:box2d/box2d.dart';

import '../neural_pilot_mode.dart';
import '../neural_pilot.dart';
import 'package:dart_summit_2016/angle_utils.dart';

class ParkingMode extends NeuralPilotMode {
  Vector2 targetPosition = new Vector2.zero();
  Vector2 targetOrientation = new Vector2(1.0, 0.0);

  final Vector2 _forwardVector = new Vector2(0.0, 1.0);

  @override
  List<num> getInputs(NeuralPilot pilot) {
    double angVel = pilot.ship.body.angularVelocity;
    Vector2 relVector = pilot.ship.getRelativeVectorTo(targetPosition);
    double distance = pilot.ship.position.distanceTo(targetPosition);
    var angleToTarget;
    if (distance == 0.0) {
      angleToTarget = 0.0;
    } else {
      angleToTarget = pilot.ship.getAngleTo(targetPosition);
    }
    var velocity =
        pilot.ship.body.getLinearVelocityFromLocalPoint(new Vector2.zero());
    var velocityAngle;
    if (distance == 0.0) {
      velocityAngle = 0.0;
    } else {
      velocityAngle = pilot.ship.getVelocityAngleOf(targetPosition);
    }
    var forward = pilot.ship.body.getWorldVector(_forwardVector);
    var orientationError = angle(forward, targetOrientation);

    return <num>[
      valueToNeuralInput(angVel, 0, 2),
      valueToNeuralInput(angVel, 0, -2),
      valueToNeuralInput(relVector.length, 0, 100),
      valueToNeuralInput(distance, 0, 1000),
      valueToNeuralInput(angleToTarget, 0, Math.PI * 2),
      valueToNeuralInput(angleToTarget, 0, -Math.PI * 2),
      valueToNeuralInput(velocity.length, 0, 5),
      valueToNeuralInput(velocityAngle, 0, 2),
      valueToNeuralInput(velocityAngle, 0, -2),
      valueToNeuralInput(orientationError, 0, Math.PI * 2),
      valueToNeuralInput(orientationError, 0, -Math.PI * 2)
    ];
  }

  @override
  int inputNeuronsCount = 11;

  @override
  num iterativeFitnessFunction(NeuralPilot pilot) {
    var distance = pilot.ship.position.distanceTo(targetPosition);
    var forward = pilot.ship.body.getWorldVector(_forwardVector);
    var orientationError = angle(forward, targetOrientation).abs();
    var orientationAndDistance =
        Math.max(distance / 10, orientationError).clamp(0, Math.PI * 2);

    return distance + orientationAndDistance;
  }

  @override
  List<SetupFunction> get setupFunctions => [
        (s) {
          targetPosition = new Vector2.zero();
          targetOrientation = new Vector2(1.0, 0.0);
        },
        (s) {
          targetPosition = new Vector2(200.0, 10.0);
          targetOrientation = new Vector2(1.0, 0.0);
        },
        (s) {
          targetPosition = new Vector2(-100.0, 10.0);
          targetOrientation = new Vector2(1.0, 0.0);
        },
        (s) {
          targetPosition = new Vector2.zero();
          targetOrientation = new Vector2(-1.0, -1.0);
        },
        (s) {
          targetPosition = new Vector2(50.0, 0.0);
          targetOrientation = new Vector2(-1.0, 0.0);
        },
        (s) {
          targetPosition = new Vector2(-50.0, 500.0);
          targetOrientation = new Vector2(0.0, -1.0);
        },
        (s) {
          targetPosition = new Vector2(200.0, -1000.0);
          targetOrientation = new Vector2(0.5, 1.0);
        }
      ];
}
