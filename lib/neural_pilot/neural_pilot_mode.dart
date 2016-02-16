library dart_summit_2016.neural_pilot.mode;

import 'package:dart_summit_2016/simulation.dart';

import 'neural_pilot.dart';

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
  int timeToEvaluate = 2000;

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

  if (!inversed) {
    if (value <= min) {
      return -1.0;
    }
    if (value >= max) {
      return 1.0;
    }
  } else {
    if (value <= max) {
      return 1.0;
    }
    if (value >= min) {
      return -1.0;
    }
  }

  return (value - min) / (max - min) * 2 - 1;
}
