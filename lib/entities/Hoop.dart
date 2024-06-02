import 'dart:math';
import 'dart:ui';

import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/entities/HoopHitbox.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class Hoop extends PositionComponent with CollisionCallbacks, HasGameRef<BBallBlast> {

  bool spawnRight;

  //physics bodies
  late HoopHitbox leftHb;
  late HoopHitbox rightHb;

  //for collision
  late RectangleComponent hoopCollDetect;

  Random rand = Random();

  Sprite hoopUpperImg;
  Sprite hoopLowerImg;
  Hoop(this.spawnRight, this.hoopLowerImg, this.hoopUpperImg) : super(priority: 3);

  @override
  Future<void> onLoad() async {

    //set pos
    super.position = _randomPos();

    SpriteComponent hoopLowerSprite = SpriteComponent(
      sprite: hoopLowerImg,
      size: Vector2(11.5, 2.875),
      anchor: Anchor.center,
      priority: 4,
      position: Vector2(getSuperPosition().x,getSuperPosition().y)
    );

    SpriteComponent hoopUpperSprite = SpriteComponent(
      sprite: hoopUpperImg,
      size: Vector2(11.5, 2.875),
      anchor: Anchor.center,
      priority: 2,
      position: Vector2(getSuperPosition().x,getSuperPosition().y-2.75)
    );

    //MUST ADD TO WORLD FOR PROPER BALL VISUAL EFFECT
    game.world.addAll([hoopUpperSprite, hoopLowerSprite]);

    //add both physics boxes to each side of hoop
    rightHb = HoopHitbox(Vector2(getSuperPosition().x + (5.4), getSuperPosition().y-1.25));
    await game.world.add(rightHb);

    leftHb = HoopHitbox(Vector2(getSuperPosition().x - (5.4), getSuperPosition().y-1.25));
    await game.world.add(leftHb);

    _addCollDetect(); 

    await super.onLoad();
  }
 
  Vector2 _randomPos() {
    double randomY = (rand.nextDouble() * 78) - 39;
    if (spawnRight) {
      double randomX = 3 + rand.nextDouble() * 8;
      return Vector2(randomX,randomY);
    } else {
      double randomX = (rand.nextDouble() * -8) - 3;
      return Vector2(randomX,randomY);
    }
  }

  void _addCollDetect() async {
    //create rect compoonent
    hoopCollDetect = RectangleComponent(
      position: Vector2(getSuperPosition().x, getSuperPosition().y+1.4),
      anchor: Anchor.center,
      size: Vector2(6,0.5),
      paint: Paint()..color = const Color.fromARGB(0, 0, 0, 0),
    );

    //add collision
    await hoopCollDetect.add(RectangleHitbox());

    await game.world.add(hoopCollDetect);
  }
  

  Vector2 getSuperPosition() {
    return super.position;
  }
}