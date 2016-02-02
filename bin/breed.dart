import 'dart:async';

import 'package:dart_summit_2016/genetic_pilot_breeder.dart';
import 'package:dart_summit_2016/neural_pilot/modes/parking_mode.dart';

Future main() async {
  var winner = await runGeneticAlgorithm(new ParkingMode(), null, null, null,
      logMessage: print, showHeadline: (m) => print("====\n$m\n===="));

  print("\n\nAnd the winner is:");
  print(winner.genesAsString);
}
