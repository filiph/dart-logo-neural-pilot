// Copyright (c) 2016, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';

const RECOMPUTE_FREQ = 500;
const SPEED = 50;

/// Try animationFrame a bunch of times and see if elapsed (= t - lastRedraw) isn't
/// bigger than 300ms. In that case, we are on a non-supported
/// slow ass device.
Future<bool> isFastEnough(
    {final int iterationCount: 100, final int minFPS: 3}) async {
  final int maxMilliseconds = 1000 ~/ minFPS;
  var el = new SpanElement()
    ..text = "TEST"
    ..style.color = "white"
    ..style.position = "absolute";
  document.body.append(el);

  num previousTime = await window.animationFrame;

  for (int i = 0; i < iterationCount; i++) {
    num t = await window.animationFrame;
    num elapsed = t - previousTime;
    if (elapsed > maxMilliseconds) {
      el.remove();
      return false;
    }
    previousTime = t;
    // Do some work.
    el.style.transform =
        "translate3d(${50+0.1*i}px, ${i}px, 0) rotateZ(${i/2}deg)";
  }
  el.remove();
  return true;
}

Future main() async {
  var output = querySelector('#output');
  SpanElement spaceshipEl = querySelector("#spaceship");
  // spaceshipEl.style.transform = "translate(50px, 100px) rotate(20deg)";
  spaceshipEl.style.transition = "${RECOMPUTE_FREQ / 1000}s linear";

  if (!await isFastEnough()) {
    output.text = "This device is not fast enough.";
    return;
  }

  bool go = true;
  querySelector("h1").onClick.listen((_) => go = false);

  num lastRedraw = 0;

  while (go) {
    await new Future.delayed(const Duration(milliseconds: RECOMPUTE_FREQ));
    num t = await window.animationFrame;
    // await new Future.delayed(const Duration(milliseconds: 100));

    // num elapsed = t - lastRedraw;
    // if (elapsed > 300) print("OMG $elapsed");
    // if (t < lastRedraw + RECOMPUTE_FREQ) continue;
    int i = (t / SPEED).floor();
    spaceshipEl.style.transform =
        "translate3d(${50+0.1*i}px, ${i}px, 0) rotateZ(${i/2}deg)";
    lastRedraw = t;
    output.text = "time: $i";
  }
}
