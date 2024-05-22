import 'dart:async';
import 'dart:ui';
import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/config.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

class Ball extends BodyComponent {
  @override
  final BBallBlast game;
  @override
  final Vector2 position;
  double radius;

  //collider wrapper
  late Collider collider; 

  //points to draw for trajectory
  late List<Vector2> points;

  //TODO: CHANGE WHEN YOU CHANGE BODY
  late double velocityRatio = 1/28.274333882308138;
  //how far trajectory projection should be
  int steps = 180;


  Ball(this.game, this.position, this.radius, Sprite sprite) : super (
    renderBody: false,
    priority: 1,

    //start body as static then set as dynamic when it is shot
    bodyDef: BodyDef()
      ..position = position
      ..type = BodyType.static
      ..linearDamping = 0,

    fixtureDefs: [
      FixtureDef(CircleShape()..radius = radius)
        ..restitution = 0.3
        ..density = 1
        //..friction = 0.5
    ],

    //add our sprite
    children: [
      SpriteComponent(
        sprite: sprite,
        size: Vector2 (6, 6),
        anchor: Anchor.center,
      )
    ],

  );

  @override
  Future<void> onLoad() async {
    collider = Collider(game, this);
    await game.world.add(collider);
    super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    //draw projected trajectory with info given by drags 
    if (game.isDragging) {
      //we multiply the input by that number as it's the ratio that converts pixel to velocity
      Vector2 initialVelocity = Vector2(game.dragBehindBall.dx, game.dragBehindBall.dy) * game.linearImpulseStrengthMult * velocityRatio;
      //initialVelocity = _checkVelMax(initialVelocity);
      //print(initialVelocity);
      //get points to draw projected trajectory
      points = trajectoryPoints(initialVelocity, Vector2(game.startPosX, game.startPosY), steps, (1/60)); //60 fps so our dt is 1/60

      Paint paint = Paint()
        ..color = const Color.fromRGBO(244, 67, 54, 1)
        ..strokeWidth = 0.5
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < points.length - 1; i++) {
        canvas.drawLine(
          Offset(points[i].x, points[i].y),
          Offset(points[i + 1].x, points[i + 1].y),
          paint,
        );
      }
    }
  }

  List<Vector2> trajectoryPoints(Vector2 initialVelocity, Vector2 startPos, int steps, double timeStep) {
    List<Vector2> points = [];

    for(int i=0; i<steps+1; i++) {
      //get the timestep for a certain time in place
      double t = i * timeStep;

      //multiply velocity by timestep to get appropriate velocity and grav at ceratain time
      Vector2 stepVel = initialVelocity * t;
      Vector2 stepGrav = Vector2(0.0, 0.5* gravity *(t*t));

      //calculate displacement based on stepVel and stepGrav in relation to starting position
      double xDisplacement = startPos.x + stepVel.x;
      double yDisplacement = startPos.y + stepVel.y + stepGrav.y;

      //form our vectors
      Vector2 pos = Vector2(xDisplacement, yDisplacement);
      points.add(pos);
    }

    return points;
  }

  Vector2 getSuperPosition(){
    return super.position;
  }

  //BOX2D Maxes out at 120 vel so we need this to ensure accurate trajectory
  Vector2 _checkVelMax(Vector2 vel) {
    if (vel.x > 120) {
      vel.x=120;
    } else if (vel.x < -120) {
      vel.x=-120;
    } 

    if (vel.y > 120) {
      vel.y=120;
    } else if (vel.y < -120) {
      vel.y=-120;
    }

    return vel;
  }
  
}

//need to wrap ball in this collider class to attach a hitbox to it.
class Collider extends CircleComponent with CollisionCallbacks {
  final Ball ball;
  final BBallBlast game;
  Collider(this.game, this.ball) : super(
    priority: 0,
    radius: ball.radius,
  ){
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.position = Vector2(ball.getSuperPosition().x - ball.radius, ball.getSuperPosition().y - ball.radius);
    super.update(dt);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other){
    if (other is RectangleComponent) {
      game.ballScored = true;
    } else {
      print(other);
    }
    super.onCollision(intersectionPoints, other);
  }

}