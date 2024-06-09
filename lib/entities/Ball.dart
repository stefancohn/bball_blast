import 'dart:async';
import 'dart:ui';
import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/config.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

class Ball extends BodyComponent with HasGameRef<Forge2DGame> {
  @override
  final BBallBlast game;
  @override
  Vector2 position;
  double radius;

  //collider wrapper
  late Collider collider; 
  bool wentAboveRim = false; 

  //points to draw for trajectory
  late List<Vector2> points;

  //TODO: CHANGE WHEN YOU CHANGE BODY
  static double velocityRatio = 1/5.026548245743669;

  //how far trajectory projection should be
  static int steps = 40;


  Ball(this.game, this.position, this.radius, Sprite sprite) : super (
    renderBody: false,
    priority: 3,

    //start body as static then set as dynamic when it is shot
    bodyDef: BodyDef()
      ..position = Vector2(position.x, -75)
      ..type = BodyType.static
      ..linearDamping = 0,

    fixtureDefs: [
      FixtureDef(CircleShape()..radius = radius)
        ..restitution = 0.3
        ..density = 0.1
        //..friction = 0.5
    ],

    //add our sprite
    children: [
      SpriteComponent(
        sprite: sprite,
        size: Vector2.all(radius*2),
        anchor: Anchor.center,
        priority: 3,
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
  void update(double dt) {
    super.update(dt);
    
    _checkBallAboveRim();
  }

  //need to ensure ball is above the hoop to ensure a user can't score underneath!!
  void _checkBallAboveRim() {
    if (getSuperPosition().y < BBallBlast.gameplay.hoop.hoopCollDetect.position.y - 2) {
      wentAboveRim = true;
    }
  }

  static List<Vector2> trajectoryPoints(Vector2 initialVelocity, Vector2 startPos, int steps, double timeStep) {
    List<Vector2> points = [];

    for(double i=0; i<steps; i+=4.5) {
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
  static Vector2 checkVelMax(Vector2 vel) {
    //check x in pos direction
    if (vel.x > 120) {
      vel.x=120;
    } else if (vel.x < -120) {
      vel.x=-120;
    } 
    //check y
    if (vel.y > 120) {
      vel.y=120;
    } else if (vel.y < -120) {
      vel.y=-120;
    }
    return vel;
  }

  //BOX2D Maxes out at 120 vel so we need to cap the max applicable linear impulse to 120!
  static Vector2 checkVelMaxImpulse(Vector2 vel) {
    //check x in pos direction
    if (vel.x*Ball.velocityRatio > 120) {
      vel.x=120/velocityRatio;
    } else if (vel.x*Ball.velocityRatio < -120) {
      vel.x=-120/velocityRatio;
    } 
    //check y
    if (vel.y*Ball.velocityRatio > 120) {
      vel.y=120/velocityRatio;
    } else if (vel.y*Ball.velocityRatio < -120) {
      vel.y=-120/velocityRatio;
    }
    return vel;
  }
  
}

//need to wrap ball in this collider class to attach a hitbox to it.
class Collider extends CircleComponent with CollisionCallbacks {
  final Ball ball;
  final BBallBlast game;
  Collider(this.game, this.ball) : super(
    radius: ball.radius,
    paint: Paint()
      ..color = const Color.fromRGBO(244, 67, 54, 0)
  ){
    add(CircleHitbox(radius: 4));
  }

  @override
  void update(double dt) {
    super.position = Vector2(ball.getSuperPosition().x - ball.radius, ball.getSuperPosition().y - ball.radius);
    super.update(dt);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other){
    if (other is RectangleComponent && ball.wentAboveRim) {
      BBallBlast.gameplay.ballScored = true;
    } else {
      print(other);
    }
    super.onCollision(intersectionPoints, other);
  }

}