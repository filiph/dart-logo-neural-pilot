import 'dart:async';
import 'dart:math' as Math;

import 'package:darwin/darwin.dart';
import 'package:backy/backy.dart';

import 'package:dart_summit_2016/neural_pilot.dart';
import 'package:dart_summit_2016/simulation.dart';

/**
 * Start the algorithm. Returns a [Future] that completes with the winner
 * [NeuralPilotPhenotype].
 */
Future<NeuralPilotPhenotype> runGeneticAlgorithm(
    NeuralPilotMode pilotModeToTest,
    AsyncVisualizationCallback visualizationCallback,
    VisualizationCallback onStartOneEvaluation,
    VisualizationCallback onEndOneEvaluation,
    {List<List<num>> chromosomesList,
    TextOutputFunction showHeadline,
    LoggingFunction logMessage}) async {
  if (logMessage == null) logMessage = print;
  if (showHeadline == null) showHeadline = (String msg) =>
      print("=== $msg ===");

  showHeadline("Evolving $pilotModeToTest");

  int firstGenerationSize = 20;
  var firstGeneration = new Generation<NeuralPilotPhenotype>();

  var breeder = new GenerationBreeder<NeuralPilotPhenotype>(
      () => new NeuralPilotPhenotype())..crossoverPropability = 0.8;
  var evaluator = new NeuralPilotSerialEvaluator(pilotModeToTest,
      visualizationCallback, onStartOneEvaluation, onEndOneEvaluation);

  if (chromosomesList == null) {
    for (int i = 0; i < firstGenerationSize; i++) {
      // Create random neural network with the correct layout
      // by creating a dummy pilot.
      var dummyPilot =
          new NeuralPilot.fromShip(pilotModeToTest, new Simulation().ship);
      var ph = new NeuralPilotPhenotype.fromBackyWeights(
          dummyPilot.neuralNetwork.weights);
      firstGeneration.members.add(ph);
    }
  } else {
    chromosomesList.forEach((List<num> ch) {
      var ph = breeder.createBlankPhenotype();
      ph.genes = ch;
      firstGeneration.members.add(ph);
    });
  }

  GeneticAlgorithm<NeuralPilotPhenotype> algo = new GeneticAlgorithm(
      firstGeneration, evaluator, breeder,
      statusf: showHeadline);
  algo.onGenerationEvaluated.listen((Generation<NeuralPilotPhenotype> g) {
    // TODO: externalize so that we can save to localStorage / disk
    logMessage("Best phenotype:\n${g.members.first.genesAsString}");
  });

  await algo.runUntilDone();

  showHeadline("Genetic algorithm completed");
  algo.generations.last.members
      .forEach((Phenotype ph) => logMessage("${ph.genesAsString},"));

  return algo.generations.last.best;
}

/// Replaces a text of some element.
typedef TextOutputFunction(String message);

/// Adds text to a log or console.
typedef LoggingFunction(String message);

class NeuralPilotPhenotype extends Phenotype<num> {
  NeuralPilotPhenotype();

  NeuralPilotPhenotype.fromBackyWeights(List<Weight> weightObjects) {
    List<List<List<num>>> weights =
        new List<List<List<num>>>(weightObjects.length);
    for (int i = 0; i < weightObjects.length; i++) {
      List<List<num>> array = weightObjects[i].weights;
      weights[i] = new List<List<num>>(array.length);
      for (int j = 0; j < array.length; j++) {
        weights[i][j] = new List<num>(array[j].length);
        for (int k = 0; k < array[j].length; k++) {
          weights[i][j][k] = array[j][k];
        }
      }
    }
    genes = weights
        .expand(
            (List<List<num>> planes) => planes.expand((List<num> rows) => rows))
        .toList(growable: false);
  }

  List<num> genes;

  num mutateGene(num gene, num strength) {
    Math.Random random = new Math.Random();
    num delta = (random.nextDouble() * 2 - 1) * strength;
    return (gene + delta).clamp(-1, 1);
  }
}

class NeuralPilotSerialEvaluator
    extends PhenotypeSerialEvaluator<NeuralPilotPhenotype> {
  NeuralPilotSerialEvaluator(this.neuralPilotMode, this.visualizationCallback,
      this.onStartOneEvaluation, this.onEndOneEvaluation);

  /// The [ShipBrainMode] we are evaluating.
  final NeuralPilotMode neuralPilotMode;

  /// Function used to visualize the progress of each experiment. The evaluator
  /// waits for the visualization callback to finish between continuing.
  final AsyncVisualizationCallback visualizationCallback;

  final VisualizationCallback onStartOneEvaluation;
  final VisualizationCallback onEndOneEvaluation;

  Future<num> runOneEvaluation(
      NeuralPilotPhenotype phenotype, int experimentNumber) async {
    print("Experiment $experimentNumber");
    if (experimentNumber >= neuralPilotMode.setupFunctions.length) {
      return new Future.value(null);
    }

    var simulation = new Simulation();
    var pilot = new NeuralPilot.fromShip(neuralPilotMode, simulation.ship);
    pilot.setNeuralNetworkFromGenes(phenotype.genes);
    simulation.setNeuralPilot(pilot);

    // Set the simulation according to pre-specified plans.
    neuralPilotMode.setupFunctions[experimentNumber](simulation);

    onStartOneEvaluation(simulation, pilot);

    double cummulativeScore = 0.0;
    for (int i = 0; i < neuralPilotMode.timeToEvaluate; i++) {
      await visualizationCallback(simulation, pilot);
      simulation.step(Simulation.TIME_STEP);
      num score = neuralPilotMode.iterativeFitnessFunction(pilot);
      if (score == null) throw "Fitness function returned a null value.";
      if (score.isInfinite) {
        onEndOneEvaluation(simulation, pilot);

        // Infinity plus anything is infinity.
        return double.INFINITY;
      }
      cummulativeScore += score;
    }

    onEndOneEvaluation(simulation, pilot);

    return cummulativeScore;
  }
}

typedef Future<num> AsyncVisualizationCallback(
    Simulation simulation, NeuralPilot pilot);

typedef void VisualizationCallback(Simulation simulation, NeuralPilot pilot);
