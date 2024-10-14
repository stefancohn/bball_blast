// ignore: file_names
import 'dart:math';
import 'dart:ui';
import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/config.dart';
import 'package:bball_blast/entities/Ball.dart';
import 'package:bball_blast/entities/Hoop.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:sqflite/sqflite.dart';

class Coin extends SpriteComponent with HasGameRef<BBallBlast>, CollisionCallbacks {
  Vector2 defSize = Vector2(6, 6);
  late Vector2 finalPos;
  bool collected = false;

  late ColorEffect flashingEffect;
  late SizeEffect resizingEffect;

  Random rand = Random();

  //objects we need from gp 
  Ball ball; 
  Hoop hoop;
  
  //set sprite
  Coin({required Sprite sprite, required this.ball, required this.hoop}) : super (
    sprite: sprite
  );
  

  //ONLOAD
  @override
  Future<void> onLoad() async{
    //need this so hoop is initialized and we don't grab a blank value
    await Future.delayed(const Duration(milliseconds: 50));

    //set properties of sprite component here
    size = defSize;
    anchor = Anchor.center;
    finalPos = calculatePlacement(ball.position, hoop.position);
    position = Vector2(finalPos.x, startingYForComponents - 10);
    flashingAndResizingEffect();

    //hitbox
    add(CircleHitbox(radius: defSize.x/2));
  }


  //UPDATE, needed for spawnIntro
  @override
  void update(double dt) {
    spawnIntro(dt);
    super.update(dt);
  }

  //calculate where the ball should go in a manner that allows the user
  //to grab the coin and score the ball
  Vector2 calculatePlacement(Vector2 ballPos, Vector2 hoopPos) {
    double timeToReachHoop = rand.nextDouble() * 1.65 + 0.35;

    //get what the initialVel should be to get in hoop
    double initialVelX = (hoopPos.x - ballPos.x)/timeToReachHoop;
    double initialVelY = (hoopPos.y - ballPos.y - (0.5*gravity*(timeToReachHoop*timeToReachHoop)))/timeToReachHoop;
    Vector2 proposedInitialVel = Vector2(initialVelX, initialVelY);

    //get list of projected trajectory with proposedVel and randomly select one of them to put the ball on
    List<Vector2> proposedPoints = Ball.trajectoryPoints(proposedInitialVel, ballPos, 40, 1/60);

    //if we have a very fast, direct path, there will be less relevant points so grab an earlier one
    if (timeToReachHoop < .8){
      return proposedPoints[rand.nextInt(2) + 2];
    } 
    //otherwise, grab a more varied point
    return proposedPoints[rand.nextInt(3) + 3];
  }

  //this gets called in BBallBlast.gameoverScene to get rid of all components nicely
  //since they are in world  they have to be removed this way 
  void fadeOut(double duration) {
    add(OpacityEffect.fadeOut(EffectController(duration: duration)));
  }

  //coin starts above camera then glides into place
  void spawnIntro(double dt) {
    if (super.position.y <= finalPos.y) {
      super.position.y += 50 * dt;
    }
  }

  void flashingAndResizingEffect() {
    // Flashing effect: alternates between bright and normal color
    flashingEffect = ColorEffect(
      const Color.fromARGB(255, 255, 255, 12), // Brighter color
      EffectController(duration: 1.5, reverseDuration: 1.5, infinite: true), 
      opacityTo: 1.0, // Max opacity (flash brightest)
    );

    // Resizing effect: grow slightly bigger and then shrink back
    resizingEffect = SizeEffect.to(
      defSize * 1.06, // Slightly larger size
      EffectController(duration: 1, reverseDuration: 1, infinite: true), // Reverses back to normal size
    );

    // Add both effects to the coin
    add(flashingEffect);
    add(resizingEffect);
  }

  //remove effects and coin rendering and add
  //particle effect
  Future<void> playCollectedAnimation() async {
    //set this var to true so method only calls once
    collected = true;

    flashingEffect.removeFromParent();
    resizingEffect.removeFromParent();

    SequenceEffect upAndOffScreen = SequenceEffect([
      MoveEffect.by(
        Vector2(0, -25),
        EffectController(
          duration: 0.3,
        )
      ),
      MoveEffect.by(
        Vector2(0, game.camera.viewport.size.y + 100),
        EffectController(
          duration: 5.8
        )
      )
    ]);

    await add(upAndOffScreen);

    iteratePlayerCoins();
  }

  //add one to coin count in player DB 
  Future<void> iteratePlayerCoins() async {
    Database db = game.database;

    //grab current score
    var dbList = await db.query('coins',);

    //if there isn't a score, must add
    if(dbList.isEmpty) {
      await db.insert(
        'coins',
        {"coin" : 1},
        conflictAlgorithm: ConflictAlgorithm.ignore
      );
    }
    //else just iterate by one
    else {
      await db.rawUpdate('UPDATE coins SET coin = coin +1');
    }
  }
}