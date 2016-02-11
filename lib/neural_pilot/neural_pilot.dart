library dart_summit_2016.neural_pilot;

import 'package:box2d/box2d.dart';

import 'package:dart_summit_2016/ship/dartship.dart';
import 'package:dart_summit_2016/neural_pilot/neural_pilot_mode.dart';
import 'package:dart_summit_2016/ann.dart';

class NeuralPilot {
  final NeuralPilotMode mode;

  DartShip ship;
  World world;
  Network neuralNetwork;

  final int outputNeuronsCount;

  NeuralPilot(this.mode, this.outputNeuronsCount) {
    neuralNetwork = new Network(mode.inputNeuronsCount, outputNeuronsCount,
        hiddenLayers: 2);
    neuralNetwork.randomizeWeights();
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
    neuralNetwork.setWeights(genes);
  }
}
