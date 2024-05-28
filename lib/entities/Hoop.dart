import 'dart:math';
import 'dart:ui';

import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/entities/HoopHitbox.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class Hoop extends SpriteComponent with CollisionCallbacks, HasGameRef<BBallBlast> {

  bool spawnRight;

  //physics bodies
  late HoopHitbox leftHb;
  late HoopHitbox rightHb;

  //for collision
  late RectangleComponent hoopCollDetect;

  Random rand = Random();

  Hoop(this.spawnRight, Sprite sprite) : super(
    sprite: sprite,
    size: Vector2.all(15),
    anchor: Anchor.center,
    priority: 1,
  );

  @override
  Future<void> onLoad() async {
    //set pos
    super.position = _randomPos();

    //add both physics boxes to each side of hoop
    rightHb = HoopHitbox(Vector2(getSuperPosition().x + size.x/2, getSuperPosition().y));
    await game.world.add(rightHb);

    leftHb = HoopHitbox(Vector2(getSuperPosition().x - size.x/2, rightHb.position.y));
    await game.world.add(leftHb);

    _addCollDetect(); 

    await super.onLoad();
  }
 
  Vector2 _randomPos() {
    double randomY = (rand.nextDouble() * 100) - 50;
    if (spawnRight) {
      double randomX = 10 + rand.nextDouble() * 15;
      return Vector2(randomX,randomY);
    } else {
      double randomX = (rand.nextDouble() * -15) - 10;
      return Vector2(randomX,randomY);
    }
  }

  void _addCollDetect() async {
    //create rect compoonent
    hoopCollDetect = RectangleComponent(
      position: Vector2(leftHb.position.x+3, leftHb.position.y+3),
      size: Vector2(5,1),
      paint: Paint()..color = const Color.fromARGB(255, 0, 0, 0),
    );

    //add collision
    await hoopCollDetect.add(RectangleHitbox());

    await game.world.add(hoopCollDetect);
  }
  

  Vector2 getSuperPosition() {
    return super.position;
  }
}