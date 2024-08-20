import 'dart:math';
import 'dart:ui';

import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/entities/Backboard.dart';
import 'package:bball_blast/entities/HoopHitbox.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';

//this isn't just a hoop, it encompasses the hoop, its hitboxes, and the backboard if there is one 
class Hoop extends PositionComponent with CollisionCallbacks, HasGameRef<BBallBlast> {

  bool spawnRight;
  late Vector2 startPos;

  //sprites
  late SpriteComponent hoopLowerSprite;
  late SpriteComponent hoopUpperSprite; 

  //physics bodies
  late HoopHitbox leftHb;
  late HoopHitbox rightHb;

  //backboard
  late Backboard backboard;

  //for collision
  late RectangleComponent hoopCollDetect;

  Random rand = Random();

  Sprite hoopUpperImg;
  Sprite hoopLowerImg;
  Sprite backboardImg;
  Hoop(this.spawnRight, this.hoopLowerImg, this.hoopUpperImg, this.backboardImg) : super(priority: 3);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    startPos = _randomPos();

    backboard = Backboard(Vector2(0,0), backboardImg);

    //set pos
    super.position = Vector2(startPos.x,-75);

    hoopLowerSprite = SpriteComponent(
      sprite: hoopLowerImg,
      size: Vector2(11.5, 2.875),
      anchor: Anchor.center,
      priority: 4,
      position: Vector2(getSuperPosition().x,getSuperPosition().y)
    );

    hoopUpperSprite = SpriteComponent(
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


    //add backboard
    await game.world.add(backboard);

    _addCollDetect(); 
  }
 
  Vector2 _randomPos() {
    double randomY = (rand.nextDouble() * 75) - 35;
    if (spawnRight) {
      double randomX = rand.nextDouble() * 12 + 6;
      return Vector2(randomX,randomY);
    } else {
      double randomX = rand.nextDouble() * -12 - 6;
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
  
  @override 
  void update(double dt) {
    //check to see if move all children
    moveAllChildren(55, dt);
  }

  Vector2 getSuperPosition() {
    return super.position;
  }

  //move all children for things like the intro scene
  void moveAllChildren(double rate, double dt) {
    if (position.y <= startPos.y) {
      position.y += rate*dt;
      hoopLowerSprite.position.y += rate * dt;
      hoopUpperSprite.position.y += rate*dt;
      hoopCollDetect.position.y += rate*dt;
      // Update physics bodies using setTransform
      leftHb.body.setTransform(leftHb.body.position + Vector2(0, rate * dt), leftHb.body.angle);
      rightHb.body.setTransform(rightHb.body.position + Vector2(0, rate * dt), rightHb.body.angle);
    }
  }

  void fadeOutAllComponents(double duration) {
    hoopLowerSprite.add(OpacityEffect.fadeOut(EffectController(duration: duration)));
    hoopUpperSprite.add(OpacityEffect.fadeOut(EffectController(duration: duration)));
  }
}