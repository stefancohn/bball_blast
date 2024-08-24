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
  Vector2 hoopSize = Vector2(11.5, 5.75);

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

    //set pos
    super.position = Vector2(startPos.x,-75);

    hoopLowerSprite = SpriteComponent(
      sprite: hoopLowerImg,
      size: Vector2(hoopSize.x, hoopSize.y/2),
      anchor: Anchor.center,
      priority: 3,
      position: Vector2(getSuperPosition().x,getSuperPosition().y)
    );

    hoopUpperSprite = SpriteComponent(
      sprite: hoopUpperImg,
      size: Vector2(hoopSize.x, hoopSize.y/2),
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
    Vector2 backboardPos = _getBackboardPos();
    backboard = Backboard(backboardPos, backboardImg);
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
  //startPos refers to where we want to component to end
  void moveAllChildren(double rate, double dt) {
    if (position.y <= startPos.y) {
      position.y += rate*dt;
      hoopLowerSprite.position.y += rate * dt;
      hoopUpperSprite.position.y += rate*dt;
      hoopCollDetect.position.y += rate*dt;

      // Update PHYSICS BODUIES using setTransform. 
      leftHb.body.setTransform(leftHb.body.position + Vector2(0, rate * dt), leftHb.body.angle);
      rightHb.body.setTransform(rightHb.body.position + Vector2(0, rate * dt), rightHb.body.angle);
      backboard.body.setTransform(backboard.body.position + Vector2(0, rate*dt), backboard.body.angle);
    }
  }

  //this gets called in BBallBlast.gameoverScene to get rid of all components nicely
  //since they are in world  they have to be removed this way 
  void fadeOutAllComponents(double duration) {
    hoopLowerSprite.add(OpacityEffect.fadeOut(EffectController(duration: duration)));
    hoopUpperSprite.add(OpacityEffect.fadeOut(EffectController(duration: duration)));
    backboard.children.first.add(OpacityEffect.fadeOut(EffectController(duration: duration)));
  }
  //SAME METHOD AS ABOVE FOR FADE TO
  void fadeOutAllComponentsTo({required double transparency, required double duration}) {
    hoopLowerSprite.add(OpacityEffect.to(transparency, EffectController(duration: duration)));
    hoopUpperSprite.add(OpacityEffect.to(transparency, EffectController(duration: duration)));
    backboard.children.first.add(OpacityEffect.to(transparency, EffectController(duration: duration)));
  }
  //MAKE ALL COMPONENTS OPAQUE FOR WHEN GAME GETS UNPAUSED
  void unfade({required double duration}) {
    hoopLowerSprite.add(OpacityEffect.fadeIn(EffectController(duration: duration)));
    hoopUpperSprite.add(OpacityEffect.fadeIn(EffectController(duration: duration)));
    backboard.children.first.add(OpacityEffect.fadeIn(EffectController(duration: duration)));
  }

  //50% chance backboard will spawn
  Vector2 _getBackboardPos() {
    double chance = rand.nextDouble();
    
    //see if chance is greater than 0.5 we will spawn backboard
    if (chance >= 0.5) {
      //if the hoop is on right adjust position properly
      if (spawnRight) {
        return Vector2(startPos.x + hoopSize.x/2+1.2, (getSuperPosition().y - 2 - 11.5/2));
      }
      //if hoop is left adjust position properly
      return Vector2(startPos.x - hoopSize.x/2-1.2, (getSuperPosition().y - 2 - 11.5/2));
    } 
    //if chance is less than 0.5 we just put the position off the map. don't just get rid 
    //of it because it makes update loop n stuff have lots more code !
    else {
      return Vector2(100, getSuperPosition().y);
    }
  }
}