library dart_summit_2016.neural_pilot;

import 'package:backy/backy.dart';
import 'package:box2d/box2d.dart';

import 'package:dart_summit_2016/ship/dartship.dart';
import 'package:dart_summit_2016/neural_pilot/neural_pilot_mode.dart';

class NeuralPilot {
  final NeuralPilotMode mode;

  // TODO(filiph): get rid of this, make a better implementation of Neuron
  // http://stackoverflow.com/questions/4719633/java-simple-neural-network-setup
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
      // layers.' -- Jeff Heaton
      (mode.inputNeuronsCount + outputNeuronsCount) ~/ 2,
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
