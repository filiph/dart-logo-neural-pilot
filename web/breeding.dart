library dartship_breeding;

import "dart:html" hide Body;

import "package:box2d/box2d_browser.dart";

import 'package:dart_summit_2016/dartship.dart';

class CanvasBreederApp {
  /** All of the bodies in a simulation. */
  List<Body> bodies = new List<Body>();

  /** The default canvas width and height. */
  static const int CANVAS_WIDTH = 900;
  static const int CANVAS_HEIGHT = 600;

  /** Scale of the viewport. */
  static const double _VIEWPORT_SCALE = 10.0;

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
  World world;

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
  double viewportScale;

  // For timing the world.step call. It is kept running but reset and polled
  // every frame to minimize overhead.
  Stopwatch _stopwatch;

  final Element canvasContainerEl;

  static int computationToShowRatio = 1;
  static int computationToPrintRatio = 100;
  int _printCounter = 0;

  DartShip _dartShip;

  CanvasBreederApp(this.canvasContainerEl,
      {Vector2 gravity, this.viewportScale: _VIEWPORT_SCALE}) {
    bool doSleep = true;
    if (null == gravity) gravity = new Vector2(0.0, GRAVITY);
    world = new World.withPool(
        gravity,
        new DefaultWorldPool(
            World.WORLD_POOL_SIZE, World.WORLD_POOL_CONTAINER_SIZE));
  }

  void start() {
    initialize();
    initializeAnimation();
    debugDraw.appendFlags(DebugDraw.JOINT_BIT |
        DebugDraw.PAIR_BIT |
        DebugDraw.CENTER_OF_MASS_BIT);
    runAnimation();
  }

  /** Advances the world forward by timestep seconds. */
  void step(num timestamp, [Function updateCallback]) {
    if (destroyed) return;

    if (computationToShowRatio <= 10) {
      // Clear the animation panel
      ctx.clearRect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);
    }

    bool shouldContinue = true;
    for (int i = 0; i < computationToShowRatio; i++) {
      world.stepDt(TIME_STEP, VELOCITY_ITERATIONS, POSITION_ITERATIONS);

      // ---- START CUSTOM STEP CODE
      _dartShip.step();

      // ---- END CUSTOM STEP CODE

      if (updateCallback != null) {
        shouldContinue = updateCallback(1);
        if (!shouldContinue) {
          break;
        }
      }
    }

    _printCounter += 1;
    if (_printCounter > computationToPrintRatio) {
      // print("Dart ship is at ${_dartShip.position}");
      print("Angle ${_dartShip.leftFlap.currentAngle}");

      _printCounter = 0;
    }

    if (computationToShowRatio > 10) {
      // Clear the animation panel
      ctx.clearRect(0, 0, CANVAS_WIDTH, CANVAS_HEIGHT);
    }

    // Draw debug data
    world.drawDebugData();

    if (shouldContinue) {
      window.requestAnimationFrame((t) {
        step(1, updateCallback);
      });
    }

//    window.requestAnimationFrame((num time) {
//      if (updateCallback != null) {
//        bool cont = updateCallback(time);
//        if (!cont) {
//          return;
//        }
//      }
//      step(time, updateCallback);
//    });
  }

  /**
   * Creates the canvas and readies the demo for animation. Must be called
   * before calling runAnimation.
   */
  void initializeAnimation() {
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

    // Have the world draw itself for debugging purposes.
    world.debugDraw = debugDraw;

    frameCount = 0;
//    new Timer.periodic(new Duration(seconds: 1), (Timer t) {
//        fpsCounter.innerHtml = frameCount.toString();
//        frameCount = 0;
//    });
//    new Timer.periodic(new Duration(milliseconds: 200), (Timer t) {
//        worldStepTime.innerHtml = "${elapsedUs / 1000} ms";
//    });
  }

  bool destroyed = false;

  void destroy() {
    destroyed = true;
  }

  void initialize() {
    _dartShip = new DartShip(world);
  }

  /**
   * Starts running the demo as an animation using an animation scheduler.
   */
  void runAnimation([Function updateCallback]) {
    step(1, updateCallback);
  }
}

main() {
  print("Starting simulation.");
  var app =
      new CanvasBreederApp(querySelector("#sim"), gravity: new Vector2.zero());
  app.start();
}
