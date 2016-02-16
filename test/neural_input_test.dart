import "package:test/test.dart";
import 'package:dart_summit_2016/neural_pilot/neural_pilot_mode.dart';

final Vector2 up = new Vector2(0.0, 1.0);
final Vector2 right = new Vector2(1.0, 0.0);
final Vector2 left = new Vector2(-1.0, 0.0);
final Vector2 down = new Vector2(0.0, -1.0);
final Vector2 upRight = new Vector2(1.0, 1.0);

const double MAX_DELTA = 0.0001;

void expectOutput(num value, num min, num max, num expectedResult) {
  expect(valueToNeuralInput(value, min, max),
      closeTo(expectedResult.toDouble(), MAX_DELTA));
}

void main() {
  group("valueToNeuralInput", () {
    test("0 to 1", () {
      expectOutput(0.0, 0, 1, -1);
      expectOutput(0.5, 0, 1, 0);
      expectOutput(1.0, 0, 1, 1);
    });

    test("0 to 5", () {
      expectOutput(0.0, 0, 5, -1);
      expectOutput(2.5, 0, 5, 0);
      expectOutput(5.0, 0, 5, 1);
    });

    test("-1 to 1", () {
      expectOutput(-1, -1, 1, -1);
      expectOutput(0, -1, 1, 0);
      expectOutput(1, -1, 1, 1);
    });

    test("1 to 0", () {
      expectOutput(0.0, 1, 0, 1);
      expectOutput(0.5, 1, 0, 0);
      expectOutput(1.0, 1, 0, -1);
    });

    test("1 to -1", () {
      expectOutput(1.0, 1, -1, -1);
      expectOutput(0.0, 1, -1, 0);
      expectOutput(-1.0, 1, -1, 1);
    });

    test("0 to -1", () {
      expectOutput(0.0, 0, -1, -1);
      expectOutput(-0.5, 0, -1, 0);
      expectOutput(-1.0, 0, -1, 1);
    });
  });
}
