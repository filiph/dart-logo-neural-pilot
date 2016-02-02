library dart_summit_2016.ship.thrust;

import 'package:box2d/box2d.dart';

class Thrust {
  final Vector2 point;
  final Vector2 force;
  const Thrust(this.force, this.point);
  Thrust.worldFromLocal(Thrust local, Body body)
      : this(body.getWorldVector(local.force), body.getWorldPoint(local.point));
}
