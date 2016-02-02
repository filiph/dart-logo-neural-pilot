import 'package:box2d/box2d.dart';

import 'package:dart_summit_2016/dartship.dart';
import 'package:dart_summit_2016/neural_pilot.dart';

class Simulation {
  static const num TIME_STEP = 1 / 30;
  static const int VELOCITY_ITERATIONS = 10;
  static const int POSITION_ITERATIONS = 10;
  static final Vector2 NO_GRAVITY = new Vector2(0.0, 0.0);

  World _world;
  World get world => _world;

  DartShip _dartShip;
  DartShip get ship => _dartShip;
  NeuralPilot _neuralPilot;

  Simulation() {
    _world = new World.withGravity(NO_GRAVITY);
    _dartShip = new DartShip(_world);
  }

  void setNeuralPilot(NeuralPilot pilot) {
    _neuralPilot = pilot;
    pilot.takeControlOf(_dartShip, _world);
  }

  void step(num timestamp) {
    _world.stepDt(TIME_STEP, VELOCITY_ITERATIONS, POSITION_ITERATIONS);
    _neuralPilot?.step();
    _dartShip.step();
  }
}
