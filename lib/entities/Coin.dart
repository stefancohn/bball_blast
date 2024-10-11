// ignore: file_names
import 'dart:math';

import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/config.dart';
import 'package:bball_blast/entities/Ball.dart';
import 'package:bball_blast/entities/Hoop.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';

class Coin extends SpriteComponent with HasGameRef<BBallBlast> {
  Vector2 defSize = Vector2(6, 6);

  Random rand = Random();

  //objects we need from gp 
  Ball ball; 
  Hoop hoop;

  //set sprite
  Coin({required Sprite sprite, required this.ball, required this.hoop}) : super (
    sprite: sprite
  );
  
  @override
  Future<void> onLoad() async{
    //set properties of sprite component here
    size = defSize;
    anchor = Anchor.center;
    position = calculatePlacement(ball.position, hoop.position);
  }

  //calculate where the ball should go in a manner that allows the user
  //to grab the coin and score the ball
  Vector2 calculatePlacement(Vector2 ballPos, Vector2 hoopPos) {
    print(hoopPos);
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
}