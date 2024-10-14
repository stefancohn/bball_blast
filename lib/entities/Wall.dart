import 'package:bball_blast/config.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

class Wall extends BodyComponent with HasGameRef<Forge2DGame> {
  @override
  Vector2 position;
  double width;
  double height; 

  Wall(this.position, this.width, this.height);

  @override
  Future<void> onLoad() async {
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

  @override
  Body createBody() {
    final shape = PolygonShape()..setAsBoxXY(width, height);
    
    final fixtureDef = FixtureDef(
      shape,
      friction: 0.3,
      restitution: 0.5,
      userData: this,
    );

    final bodyDef = BodyDef(
      userData: this,
      position: position,
      type: BodyType.static,
    );

    return game.world.createBody(bodyDef)..createFixture(fixtureDef);
  }
}