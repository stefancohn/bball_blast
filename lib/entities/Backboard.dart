import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

class Backboard extends BodyComponent with HasGameRef<Forge2DGame> {
  Vector2 size = Vector2(1.75, 11.5);

  Vector2 startPos;
  Sprite sprite;
  Backboard(this.startPos, this.sprite);
  
  @override
  Future<void> onLoad() async{
    //sprite and add it to body
    renderBody = false; 
    priority = 4;
    await super.onLoad();

   await add(SpriteComponent(
      sprite: sprite,
      size: size,
      anchor: Anchor.center
    ),);
  }

  //define the body, make it a box
  @override
  Body createBody() {
    double hitboxX = size.x/2 - 0.1;
    double hitboxY = size.y/2 - 0.25;

    final shape = PolygonShape()
      ..setAsBoxXY(hitboxX, hitboxY);

    final fixtureDef = FixtureDef(
      shape,
      userData: this,
      restitution: 0.4,
      friction: 0.2,
    );

    final bodyDef = BodyDef(
      position: startPos, 
      type: BodyType.static
    );

    return game.world.createBody(bodyDef)..createFixture(fixtureDef);
  }
}