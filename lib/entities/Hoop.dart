import 'dart:ui';

import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/entities/HoopHitbox.dart';
import 'package:bball_blast/entities/ball.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class Hoop extends SpriteComponent with CollisionCallbacks {
  @override
  final BBallBlast game;

  bool spawnRight;

  //physics bodies
  late HoopHitbox leftHb;
  late HoopHitbox rightHb;

  //for collision
  late RectangleComponent hoopCollDetect;

  Hoop(this.game, this.spawnRight, Sprite sprite) : super(
    sprite: sprite,
    size: Vector2.all(15),
    anchor: Anchor.center,
    priority: 1,
  );

  @override
  Future<void> onLoad() async {
    //set pos
    super.position = Vector2(20, -20);

    //add both physics boxes to each side of hoop
    rightHb = HoopHitbox(randomPos());
    await game.world.add(rightHb);

    leftHb = HoopHitbox(Vector2(rightHb.position.x-10, rightHb.position.y));
    await game.world.add(leftHb);

    _addCollDetect(); 

    await super.onLoad();
  }
 
  Vector2 randomPos() {
    return Vector2(30,-30);
  }

  void _addCollDetect() async {
    //create rect compoonent
    hoopCollDetect = RectangleComponent(
      anchor: Anchor.topLeft,
      position: Vector2(leftHb.position.x+2, leftHb.position.y+2),
      size: Vector2(7,1),
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