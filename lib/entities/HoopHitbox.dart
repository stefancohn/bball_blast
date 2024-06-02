import 'package:flame_forge2d/flame_forge2d.dart';

class HoopHitbox extends BodyComponent {
  HoopHitbox(Vector2 position) : super(
    renderBody: false,
    priority: 0,
    bodyDef: BodyDef()
      ..position = position
      ..type = BodyType.static,

    fixtureDefs: [
      FixtureDef(CircleShape()..radius = 0.2)
        ..restitution = 0.1
        ..density = 1
        //..friction = 0.5
    ],
  );
}