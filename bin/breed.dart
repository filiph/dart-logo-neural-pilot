import 'dart:async';
import 'dart:io';

import 'package:darwin/darwin.dart';

import 'package:dart_summit_2016/genetic_pilot_breeder.dart';
import 'package:dart_summit_2016/neural_pilot/modes/parking_mode.dart';
import '../web/winners.dart';

Future main(List<String> args) async {
  if (args.isEmpty) {
    print("Must provide output file.");
    return;
  }
  var filename = args.single;
  IOSink fileSink = new File(filename).openWrite();

  var algo = setUpGeneticAlgorithm(new ParkingMode(), null, null, null,
      chromosomesList: CHROMOSOMES_LIST);

  algo.MAX_EXPERIMENTS = 200000;
  algo.breeder.fitnessSharingRadius = 0.1;
  algo.breeder.mutationRate = 0.02;
  algo.breeder.mutationStrength = 0.2;
  algo.breeder.elitismCount = 3;

  fileSink.writeln("STARTING NEW ALGO");
  fileSink.writeln("Algo settings: ");
  fileSink.writeln("  algo.MAX_EXPERIMENTS = ${algo.MAX_EXPERIMENTS};");
  fileSink.writeln("  algo.THRESHOLD_RESULT = ${algo.THRESHOLD_RESULT};");
  fileSink.writeln("  algo.generationSize = ${algo.generationSize};");
  fileSink.writeln(
      "  algo.MAX_GENERATIONS_IN_MEMORY = ${algo.MAX_GENERATIONS_IN_MEMORY};");
  fileSink.writeln(
      "  algo.breeder.fitnessSharing = ${algo.breeder.fitnessSharing};");
  fileSink.writeln(
      "  algo.breeder.fitnessSharingRadius = ${algo.breeder.fitnessSharingRadius};");
  fileSink.writeln(
      "  algo.breeder.fitnessSharingAlpha = ${algo.breeder.fitnessSharingAlpha};");
  fileSink
      .writeln("  algo.breeder.mutationRate = ${algo.breeder.mutationRate};");
  fileSink.writeln(
      "  algo.breeder.mutationStrength = ${algo.breeder.mutationStrength};");
  fileSink.writeln(
      "  algo.breeder.crossoverPropability = ${algo.breeder.crossoverPropability};");
  fileSink
      .writeln("  algo.breeder.elitismCount = ${algo.breeder.elitismCount};");

  fileSink.writeln("\nFirst generation:");
  for (var ph in algo.generations.last.members) {
    fileSink.writeln("  const ${ph.genesAsString},");
  }

  algo.onGenerationEvaluated.listen((Generation<NeuralPilotPhenotype> g) {
    fileSink.writeln("\n\nGeneration ${algo.currentGeneration} evaluated:");
    fileSink.writeln("- BEST: ${g.bestFitness}");
    fileSink.writeln("- AVG: ${g.averageFitness}");
    fileSink.writeln("\n${g.best.genesAsString}");
  });

  await algo.runUntilDone();

  fileSink.writeln("Genetic algorithm completed");
  algo.generations.last.members
      .forEach((NeuralPilotPhenotype ph) => print("${ph.genesAsString},"));

  fileSink.writeln("\n\nAnd the winner is:");
  fileSink.writeln(algo.generations.last.best.genesAsString);
  fileSink.writeln("\n\nconst CHROMOSOMES_LIST = const [");
  for (var ph in algo.generations.last.members) {
    fileSink.writeln("  const ${ph.genesAsString},");
  }
  fileSink.writeln("];");
  await fileSink.close();
  print("Done.");
  print("Winner = \n${algo.generations.last.best.genesAsString}");
}
