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

  Function showHeadlineFunction;

  void showHeadline(String msg) {
    if (showHeadlineFunction == null) return;

    showHeadlineFunction(msg);
  }

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
        pilot.ship.body.getLinearVelocityFromWorldPoint(targetPosition);

    var relativeVelocity =
        pilot.ship.body.getLinearVelocityFromLocalPoint(new Vector2.zero());

    var relativeVelocityAngle;
    if (distance == 0.0 || relativeVelocity.length2 == 0.0) {
      relativeVelocityAngle = 0.0;
    } else {
      relativeVelocityAngle = angle(relativeVelocity, relVector);
    }

    var forward = pilot.ship.body.getWorldVector(_forwardVector);
    var orientationError = angle(forward, targetOrientation);

    var inputs = <num>[
      valueToNeuralInput(angVel, -1, 1),
      valueToNeuralInput(relVector.x, -100, 100),
      valueToNeuralInput(relVector.y, -100, 100),
      valueToNeuralInput(relVector.x, -10, 10),
      valueToNeuralInput(relVector.y, -10, 10),
      Math.sin(angleToTarget),
      Math.cos(angleToTarget),
      valueToNeuralInput(velocity.length, 0, 5),
      valueToNeuralInput(velocity.x, -10, 10),
      valueToNeuralInput(velocity.y, -10, 10),
      valueToNeuralInput(velocity.x, -100, 100),
      valueToNeuralInput(velocity.y, -100, 100),
      valueToNeuralInput(relativeVelocity.x, -10, 10),
      valueToNeuralInput(relativeVelocity.y, -10, 10),
      valueToNeuralInput(relativeVelocity.x, -100, 100),
      valueToNeuralInput(relativeVelocity.y, -100, 100),
      Math.sin(relativeVelocityAngle),
      Math.cos(relativeVelocityAngle),
      Math.sin(orientationError),
      Math.cos(orientationError),
      valueToNeuralInput(pilot.ship.leftFlap.currentAngleNormalized, 0, 1),
      valueToNeuralInput(pilot.ship.rightFlap.currentAngleNormalized, 0, 1),
      valueToNeuralInput(pilot.ship.leftLeg.currentAngleNormalized, 0, 1),
      valueToNeuralInput(pilot.ship.rightLeg.currentAngleNormalized, 0, 1),
      1.0
    ];

    showHeadline(inputs.map((n) => n.toStringAsFixed(1)).join("\n"));

    return inputs;
  }

  @override
  int inputNeuronsCount = 25;

  @override
  num iterativeFitnessFunction(NeuralPilot pilot) {
    var distance = pilot.ship.position.distanceTo(targetPosition);
    if (distance.isInfinite) {
      throw new StateError("Distance cannot be infinite.");
    }
    var forward = pilot.ship.body.getWorldVector(_forwardVector);
    var orientationError = angle(forward, targetOrientation).abs();
    var orientationAndDistance =
        Math.max(distance / 10, orientationError).clamp(0, Math.PI * 2);
    double angVel = pilot.ship.body.angularVelocity.abs();

    var sum =
        (5 * Math.log(distance + 1) + orientationAndDistance + angVel / 2);
    return sum;
  }

  @override
  List<SetupFunction> get setupFunctions => [
        (s) {
          targetPosition = new Vector2.zero();
          targetOrientation = new Vector2(1.0, 0.0);
        },
        (s) {
          targetPosition = new Vector2(50.0, 0.0);
          targetOrientation = new Vector2(-1.0, 0.0);
        },
        (s) {
          targetPosition = new Vector2(150.0, 10.0);
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
          targetPosition = new Vector2(-50.0, 300.0);
          targetOrientation = new Vector2(0.0, -1.0);
        },
        (s) {
          targetPosition = new Vector2(200.0, -1000.0);
          targetOrientation = new Vector2(0.5, 1.0);
        }
      ];
}
