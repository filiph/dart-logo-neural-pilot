library dartship_breeding;

import 'dart:async';
import "dart:html";

import "package:box2d/box2d_browser.dart";

import 'package:dart_summit_2016/genetic_pilot_breeder.dart';
import 'package:dart_summit_2016/simulation.dart';
import 'package:dart_summit_2016/neural_pilot/modes/parking_mode.dart';
import 'package:dart_summit_2016/neural_pilot/neural_pilot.dart';
import 'package:darwin/darwin.dart';

import 'winners.dart';

class CanvasBreederApp {
  /** The default canvas width and height. */
  static const int CANVAS_WIDTH = 900;
  static const int CANVAS_HEIGHT = 600;

  /** Scale of the viewport. */
  static const double _VIEWPORT_SCALE = 5.0;

  /** The gravity vector's y value. */
  static const double GRAVITY = -10.0;

  /** The timestep and iteration numbers. */
  static const num TIME_STEP = 1 / 30;
  static const int VELOCITY_ITERATIONS = 10;
  static const int POSITION_ITERATIONS = 10;

  /** The drawing canvas. */
  CanvasElement canvas;

  /** The canvas rendering context. */
  CanvasRenderingContext2D ctx;

  /** The transform abstraction layer between the world and drawing canvas. */
  ViewportTransform viewport;

  /** The debug drawing tool. */
  DebugDraw debugDraw;

  /** The physics world. */
  // World world;

  /** Frame count for fps */
  int frameCount;

  /** HTML element used to display the FPS counter */
  Element fpsCounter;

  /** Microseconds for world step update */
  int elapsedUs;

  /** HTML element used to display the world step time */
  Element worldStepTime;

  // TODO(dominich): Make this library-private once optional positional
  // parameters are introduced.
  double viewportScale = _VIEWPORT_SCALE;

  // For timing the world.step call. It is kept running but reset and polled
  // every frame to minimize overhead.
  Stopwatch _stopwatch;

  final Element canvasContainerEl;
  Element _showHeadlineEl;

  static int computationToShowRatio = 1;
  static int computationToPrintRatio = 100;
  int _printCounter = 0;

  CanvasBreederApp(this.canvasContainerEl) {
    _showHeadlineEl = new PreElement()..style.position = "absolute";
    canvasContainerEl.append(_showHeadlineEl);
  }

  showHeadline(String text) {
    _showHeadlineEl.text = text;
  }

  GeneticAlgorithm<NeuralPilotPhenotype> algo;

  void start() {
    var mode = new ParkingMode()..showHeadlineFunction = showHeadline;
    algo = setUpGeneticAlgorithm(
        mode, visualizationCallback, initializeAnimation, destroyAnimation,
        showHeadline: showHeadline, chromosomesList: CHROMOSOMES_LIST);

    algo.MAX_EXPERIMENTS = 20000;

    algo.onGenerationEvaluated.listen((Generation<NeuralPilotPhenotype> g) {
      // TODO: externalize so that we can save to localStorage / disk
      print("Best phenotype:\n${g.members.first.genesAsString}");
    });

    algo.runUntilDone().then((_) {
      print("Genetic algorithm completed");
      algo.generations.last.members
          .forEach((Phenotype ph) => print("${ph.genesAsString},"));
    });
  }

  /**
   * Creates the canvas and readies the demo for animation. Must be called
   * before calling runAnimation.
   */
  void initializeAnimation(Simulation simulation, NeuralPilot pilot) {
    print("Initializing animation");
    // Setup the canvas.
    canvas = new Element.tag('canvas');
    canvas.width = CANVAS_WIDTH;
    canvas.height = CANVAS_HEIGHT;
    canvasContainerEl.nodes.add(canvas);
    ctx = canvas.getContext("2d");

    // Create the viewport transform with the center at extents.
    final extents = new Vector2(CANVAS_WIDTH / 2, CANVAS_HEIGHT / 2);
    viewport = new CanvasViewportTransform(extents, extents);
    viewport.scale = viewportScale;

    // Create our canvas drawing tool to give to the world.
    debugDraw = new CanvasDraw(viewport, ctx);

    debugDraw.appendFlags(DebugDraw.JOINT_BIT |
        DebugDraw.PAIR_BIT |
        DebugDraw.CENTER_OF_MASS_BIT);

    // Have the world draw itself for debugging purposes.
    simulation.world.debugDraw = debugDraw;

    frameCount = 0;
//    new Timer.periodic(new Duration(seconds: 1), (Timer t) {
//        fpsCounter.innerHtml = frameCount.toString();
//        frameCount = 0;
//    });
//    new Timer.periodic(new Duration(milliseconds: 200), (Timer t) {
//        worldStepTime.innerHtml = "${elapsedUs / 1000} ms";
//    });
  }

  Future<num> visualizationCallback(
      Simulation simulation, NeuralPilot pilot) async {
    var timestamp = await window.animationFrame;

    // Clear the animation panel
    ctx.clearRect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);

    debugDraw.setCamera(pilot.ship.body.position.x * viewportScale + 450,
        pilot.ship.body.position.y * viewportScale + 300, viewportScale);

    if (pilot.mode is ParkingMode) {
      var target = (pilot.mode as ParkingMode).targetPosition;
      var orientation = (pilot.mode as ParkingMode).targetOrientation;

      // Notice: drawCircle mutates [target] so we need to clone.
      debugDraw.drawCircle(
          target.clone(), 5.0, new Color3i.fromRGBd(0.0, 250.0, 0.0));
      debugDraw.drawSegment(
          target.clone(),
          target + orientation.normalized().scaled(10.0),
          new Color3i.fromRGBd(0.0, 250.0, 0.0));
    }

    simulation.world.drawDebugData();

    return timestamp;
  }

  void destroyAnimation(Simulation simulation, NeuralPilot pilot) {
    print("Destroying animation");
    simulation.world.debugDraw = null;
    ctx = null;
    viewport = null;
    canvas.remove();
  }

  bool stopped = false;

  void stop() {
    stopped = true;
  }
}

main() {
  var app = new CanvasBreederApp(querySelector("#sim"));
  app.start();

  querySelector("h1").onClick.listen((_) => app.stop());
}
