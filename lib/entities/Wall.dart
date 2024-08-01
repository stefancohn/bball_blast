import 'package:bball_blast/config.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

class Wall extends BodyComponent with HasGameRef<Forge2DGame>{
  @override
  Vector2 position;
  Wall(this.position, double width, double height) : super (
    renderBody: false,
    bodyDef: BodyDef() 
      ..position = position,
    fixtureDefs: [
          FixtureDef(
            PolygonShape()..setAsBoxXY(width, height),
            friction: 0.3,
            restitution: 0.5
          )
      ]
  );

  @override
  Future<void> onLoad() {
    RectangleComponent hitbox = RectangleComponent(
      position: position,
      size: Vector2(1.35, gameHeight),
      children: [RectangleHitbox()],
    );
    add(hitbox);

    if (position.x >= game.camera.visibleWorldRect.right) {
      hitbox.position.x -= 1.35;
    }
    return super.onLoad();
  }
}