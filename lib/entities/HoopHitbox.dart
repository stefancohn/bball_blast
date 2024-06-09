import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

class HoopHitbox extends BodyComponent with CollisionCallbacks {
  Vector2 position1;
  CircleComponent? circleCollDetect;

  HoopHitbox(this.position1) : super(
    renderBody: false,
    priority: 0,
    bodyDef: BodyDef()
      ..position = position1
      ..type = BodyType.static,

    fixtureDefs: [
      FixtureDef(CircleShape()..radius = 0.2)
        ..restitution = 0.1
        ..density = 1
        //..friction = 0.5
    ],
  );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    circleCollDetect = CircleComponent(
      radius: 0.3,
      paint: Paint() ..color = const Color.fromARGB(0, 0, 238, 255),
      anchor: Anchor.center,
    );
    circleCollDetect!.add(CircleHitbox());
    game.world.add(circleCollDetect!);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (this.body.isActive && circleCollDetect != null) {
      circleCollDetect!.position = position;
    }
  }
}