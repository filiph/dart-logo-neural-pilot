library dart_summit_2016.shipbrain;

import 'dart:math' as Math;

import 'package:backy/backy.dart';
import 'package:box2d/box2d.dart';

import 'dartship.dart';
import 'package:dart_summit_2016/simulation.dart';

abstract class NeuralPilotMode {
  // List<num> _bestPhenotypeGenes;
  // NeuroPilotPhenotype get bestPhenotype {
  //   if (_bestPhenotypeGenes == null) return null;
  //   var ph = new NeuroPilotPhenotype();
  //   ph.genes = _bestPhenotypeGenes;
  //   return ph;
  // }

  List<SetupFunction> get setupFunctions;

  int get inputNeuronsCount;

  /**
   * Takes the [ship] being evaluated, the [worldState] (when also evaluating
   * the effects the phenotype has on its environment, or when evaluating some
   * variables in relation to surroundings) and [userData] (an object that can
   * store state between calls to objective function).
   *
   * The function must return a positive [num]. The lower the value, the better
   * fit. Returning [:0.0:] means the phenotype is performing perfectly (= is in
   * desired state in relation to its surroundings).
   *
   * This function will be called periodically, and its return values will be
   * summed.
   */
  num iterativeFitnessFunction(NeuralPilot pilot);

  /**
   * Number of simulation steps to evaluate. This should be enough for this
   * brain to do its thing and stay at the needed position.
   */
  int timeToEvaluate = 500;

  /**
   * Generates input for given [ship] and its [target] in a given situation [s].
   * This is feeded to the [brain]'s neural network.
   * [userData] can be used to store information between runs of the function.
   */
  List<num> getInputs(NeuralPilot pilot);
}

/**
 * A function to be called before experiment. Makes sure everything is set
 * up in an 'interesting' way. Returns the [ShipCombatSituation].
 */
typedef SetupFunction(Simulation s);

/**
 * Takes a value and [min] and [max], and returns a number that is suitable
 * for [TanHNeuron] input. (Range from [:-1.0:] to [:1.0:].)
 *
 * Values lower than [min] will be mapped to [:-1.0:], values higher than
 * [max] will be mapped to [:1.0:]. Everything between will be mapped
 * lineary.
 *
 * [min] can also be _higher_ than [max], in which case the function will
 * inverse. In other words, a [value] of [max] will be converted to [:-1.0:],
 * etc.
 */
num valueToNeuralInput(num value, num min, num max) {
  if (min == max || min == null || max == null) {
    throw new ArgumentError("The values of min and max must be different "
        "and not null (function called with $min, $max, respectivelly).");
  }
  bool inversed = min > max;

  if (value <= min) {
    return inversed ? 1.0 : -1.0;
  }
  if (value >= max) {
    return inversed ? -1.0 : 1.0;
  }

  return (value - min) / (max - min) * 2 - 1;
}

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

class NeuralPilot {
  final NeuralPilotMode mode;

  // TODO(filiph): get rid of this, make a better implementation of Neuron
  static final Neuron neuronPrototype = new TanHNeuron();

  DartShip ship;
  World world;
  Backy neuralNetwork;

  final int outputNeuronsCount;

  NeuralPilot(this.mode, this.outputNeuronsCount) {
    neuronPrototype.bias = 1;
    neuralNetwork = new Backy([
      mode.inputNeuronsCount,
      // 'The optimal size of the hidden layer is usually
      // between the size of the input and size of the output
      // layers.'
      (mode.inputNeuronsCount + outputNeuronsCount) ~/ 2,
      outputNeuronsCount
    ], neuronPrototype);
  }

  NeuralPilot.fromShip(NeuralPilotMode mode, DartShip ship)
      : this(mode, ship.thrusters.length + ship.revoluteParts.length);

  void takeControlOf(DartShip ship, World world) {
    this.ship = ship;
    this.world = world;
  }

  /**
   * Takes control of the ship.
   *
   * Applies the results of the neural network by sending commands to different
   * systems of the ship, according to current situation.
   */
  void step() {
    if (ship == null || world == null) {
      throw new StateError("NeuralPilot cannot pilot without a ship or world.");
    }
    List<num> outputs = neuralNetwork.use(mode.getInputs(this));
    assert(outputs.length == ship.thrusters.length + ship.revoluteParts.length);
    for (int i = 0; i < ship.thrusters.length; i++) {
      // First part of outputs control the thruster powers.
      num force = ((outputs[i] + 1) / 2).clamp(0, 1); // from <-1,1> to <0,1>
      ship.thrusters[i].moveToDesiredPower(force);
    }
    for (int j = 0; j < ship.revoluteParts.length; j++) {
      // Second part of outputs control the revoluting parts of the ship.
      int i = ship.thrusters.length + j;
      num normalizedAngle = ((outputs[i] + 1) / 2).clamp(0, 1);
      ship.revoluteParts[j].moveToDesiredAngleNormalized(normalizedAngle);
    }
  }

  void setNeuralNetworkFromGenes(List<num> genes) {
    int n = 0;
    for (int i = 0; i < neuralNetwork.weights.length; i++) {
      for (int j = 0; j < neuralNetwork.weights[i].weights.length; j++) {
        for (int k = 0; k < neuralNetwork.weights[i].weights[j].length; k++) {
          neuralNetwork.weights[i].weights[j][k] = genes[n];
          n++;
        }
      }
    }
    assert(n == genes.length);
  }
}

// typedef num IterativeFitnessFunction(AIBox2DShip ship, Box2DShip target,
//     ShipCombatSituation worldState, Object userData);
