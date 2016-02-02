library dartship_breeding;

import "dart:html" hide Body;

import "package:box2d/box2d_browser.dart";

import 'package:dart_summit_2016/dartship.dart';
import 'package:dart_summit_2016/neural_pilot.dart';
import 'package:dart_summit_2016/simulation.dart';
import 'package:dart_summit_2016/genetic_pilot_breeder.dart';
import 'dart:async';

class CanvasBreederApp {
  /** All of the bodies in a simulation. */
  List<Body> bodies = new List<Body>();

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

  static int computationToShowRatio = 1;
  static int computationToPrintRatio = 100;
  int _printCounter = 0;

  // DartShip _dartShip;
  // NeuralPilotMode _brainMode;

  Simulation simulation;

  CanvasBreederApp(this.canvasContainerEl);

  void start() {
    runGeneticAlgorithm(new ParkingMode(), visualizationCallback,
        initializeAnimation, destroyAnimation);
  }

//   /** Advances the world forward by timestep seconds. */
//   void step(num timestamp, [Function updateCallback]) {
//     if (stopped) return;
//
//     if (computationToShowRatio <= 10) {
//       // Clear the animation panel
//       ctx.clearRect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);
//     }
//
//     bool shouldContinue = true;
//     for (int i = 0; i < computationToShowRatio; i++) {
//       world.stepDt(TIME_STEP, VELOCITY_ITERATIONS, POSITION_ITERATIONS);
//
//       // ---- START CUSTOM STEP CODE
//       _brainMode.control();
//       _dartShip.step();
//
//       // ---- END CUSTOM STEP CODE
//
//       if (updateCallback != null) {
//         shouldContinue = updateCallback(1);
//         if (!shouldContinue) {
//           break;
//         }
//       }
//     }
//
//     _printCounter += 1;
//     if (_printCounter > computationToPrintRatio) {
//       // print("Dart ship is at ${_dartShip.position}");
//       // print("Angle ${_dartShip.leftFlap.currentAngle}");
//
//       _printCounter = 0;
//     }
//
//     if (computationToShowRatio > 10) {
//       // Clear the animation panel
//       ctx.clearRect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);
//     }
//
//     // Draw debug data
//     world.drawDebugData();
//
//     if (shouldContinue) {
//       window.requestAnimationFrame((t) {
//         step(1, updateCallback);
//       });
//     }
//
// //    window.requestAnimationFrame((num time) {
// //      if (updateCallback != null) {
// //        bool cont = updateCallback(time);
// //        if (!cont) {
// //          return;
// //        }
// //      }
// //      step(time, updateCallback);
// //    });
//   }

  final extents = new Vector2(CANVAS_WIDTH / 2, CANVAS_HEIGHT / 2);

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
