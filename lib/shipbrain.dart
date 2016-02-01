library dart_summit_2016.shipbrain;

import 'dart:math' as Math;

import 'package:backy/backy.dart';
import 'package:box2d/box2d.dart';

import 'dartship.dart';

abstract class ShipBrainMode {
  static final Neuron neuronPrototype = new TanHNeuron();

  final DartShip ship;
  final World world;
  Backy brain;

  int get inputNeuronsCount;
  int outputNeuronsCount;

  ShipBrainMode(this.world, this.ship) {
    neuronPrototype.bias = 1;
    outputNeuronsCount = ship.thrusters.length + ship.revoluteParts.length;
    brain = new Backy([
      inputNeuronsCount,
      // 'The optimal size of the hidden layer is usually
      // between the size of the input and size of the output
      // layers.'
      (inputNeuronsCount + outputNeuronsCount) ~/ 2,
      outputNeuronsCount
    ], neuronPrototype);
  }

  // List<num> _bestPhenotypeGenes;
  // NeuroPilotPhenotype get bestPhenotype {
  //   if (_bestPhenotypeGenes == null) return null;
  //   var ph = new NeuroPilotPhenotype();
  //   ph.genes = _bestPhenotypeGenes;
  //   return ph;
  // }

  // List<SetupFunction> get setupFunctions;

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
  num iterativeFitnessFunction();

  /**
   * Number of simulation steps to evaluate. This should be enough for this
   * brain to do its thing and stay at the needed position.
   */
  int timeToEvaluate = 1000;

  /**
   * Generates input for given [ship] and its [target] in a given situation [s].
   * This is feeded to the [brain]'s neural network.
   * [userData] can be used to store information between runs of the function.
   */
  List<num> getInputs();

  /**
   * Takes control of the ship.
   *
   * Applies the results of the neural network by sending commands to different
   * systems of the ship, according to current situation.
   */
  void control() {
    List<num> outputs = brain.use(getInputs());
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

  // void setBrainFromPhenotype(NeuroPilotPhenotype phenotype) {
  //   List<num> genes = phenotype.genes;
  //   int n = 0;
  //   for (int i = 0; i < brain.weights.length; i++) {
  //     for (int j = 0; j < brain.weights[i].weights.length; j++) {
  //       for (int k = 0; k < brain.weights[i].weights[j].length; k++) {
  //         brain.weights[i].weights[j][k] = genes[n];
  //         n++;
  //       }
  //     }
  //   }
  //   assert(n == genes.length);
  // }
}

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

class ParkShipBrainMode extends ShipBrainMode {
  Vector2 targetPosition = new Vector2.zero();
  Vector2 targetOrientation = new Vector2(1.0, 0.0);

  ParkShipBrainMode(World world, DartShip ship) : super(world, ship);

  @override
  List<num> getInputs() {
    var angleToTarget = ship.getAngleTo(targetPosition);

    return <num>[
      valueToNeuralInput(ship.position.distanceTo(targetPosition), 0, 1000),
      valueToNeuralInput(Math.cos(angleToTarget), -1.0, 1.0),
      valueToNeuralInput(Math.sin(angleToTarget), -1.0, 1.0),
    ];
  }

  @override
  int inputNeuronsCount = 3;

  @override
  num iterativeFitnessFunction() {
    return ship.position.distanceTo(targetPosition);
  }
}

// typedef num IterativeFitnessFunction(AIBox2DShip ship, Box2DShip target,
//     ShipCombatSituation worldState, Object userData);
