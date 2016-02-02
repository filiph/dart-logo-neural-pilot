library dart_summit_2016.neural_pilot.mode.parking;

import 'dart:math' as Math;

import 'package:box2d/box2d.dart';

import '../neural_pilot_mode.dart';
import '../neural_pilot.dart';

class ParkingMode extends NeuralPilotMode {
  Vector2 targetPosition = new Vector2.zero();
  Vector2 targetOrientation = new Vector2(1.0, 0.0);

  @override
  List<num> getInputs(NeuralPilot pilot) {
    double angVel = pilot.ship.body.angularVelocity;
    Vector2 relVector = pilot.ship.getRelativeVectorTo(targetPosition);
    var angle = pilot.ship.getAngleTo(targetPosition);
    var velocity =
        pilot.ship.body.getLinearVelocityFromLocalPoint(new Vector2.zero());
    var velocityAngle = pilot.ship.getVelocityAngleOf(targetPosition);

    return <num>[
      valueToNeuralInput(angVel, 0, 2),
      valueToNeuralInput(angVel, 0, -2),
      valueToNeuralInput(relVector.length, 0, 100),
      valueToNeuralInput(
          pilot.ship.position.distanceTo(targetPosition), 0, 1000),
      valueToNeuralInput(angle, 0, Math.PI * 2),
      valueToNeuralInput(angle, 0, -Math.PI * 2),
      valueToNeuralInput(velocity.length, 0, 5),
      valueToNeuralInput(velocityAngle, 0, 2),
      valueToNeuralInput(velocityAngle, 0, -2),
      // valueToNeuralInput(Math.cos(angleToTarget), -1.0, 1.0),
      // valueToNeuralInput(Math.sin(angleToTarget), -1.0, 1.0),
      // TODO XXX orientation
    ];
  }

  @override
  int inputNeuronsCount = 9;

  @override
  num iterativeFitnessFunction(NeuralPilot pilot) {
    return pilot.ship.position.distanceTo(targetPosition);
  }

  @override
  List<SetupFunction> get setupFunctions => [
        (s) {
          targetPosition = new Vector2.zero();
        },
        (s) {
          targetPosition = new Vector2(200.0, 10.0);
        }
      ];
}
