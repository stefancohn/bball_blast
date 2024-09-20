import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/config.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
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

  //FOR GENERATE TRAJ METHODS
  static double velocityRatio = 1/5.026548245743669;
  static List<double> randomAnglesForCoinShot = [pi/4, pi/3, pi/3.5];
  static Random rand = Random();

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

  //FADE BALL METHOD FOR WHEN GAME GETS PAUSED
  void fadeOutAllComponentsTo({required double transparency, required double duration}) {
    children.first.add(OpacityEffect.to(transparency, EffectController(duration: duration)));
  }
  //MAKE BALL OPAQUE FOR WHEN GAME IS UNPAUSED
  void unfade({required double duration}) {
    children.first.add(OpacityEffect.fadeIn(EffectController(duration: duration)));
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

  static Vector2 getInitialVelToScore(Vector2 hoopPos, Vector2 ballStartPos){
    // Calculate the horizontal and vertical distances
    print(hoopPos.x);
    print(ballStartPos.x);
    double dx = hoopPos.x - ballStartPos.x;
    double dy = hoopPos.y - ballStartPos.y;

    double angle = randomAnglesForCoinShot[rand.nextInt(3)];

    // Calculate the initial velocity required
    double v0 = sqrt((gravity * dx * dx) / (2 * (dx * tan(angle) - dy) * cos(angle) * cos(angle)));

    // Calculate the components of the initial velocity
    double vx = v0 * cos(angle);
    double vy = v0 * sin(angle);

    return Vector2(vx,vy);
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
    //if the ball hit the hoop collider and went over it
    if (other == (BBallBlast.gameplay.hoop.hoopCollDetect) && ball.wentAboveRim) {
      BBallBlast.gameplay.ballScored = true;
    } 

    //if ball hits wall
    if (other == BBallBlast.gameplay.wallRight.children.first) {
      BBallBlast.gameplay.wallBumpAnimation(false);
    } else if (other == BBallBlast.gameplay.wallLeft.children.first) {
      BBallBlast.gameplay.wallBumpAnimation(true);
    }
    
    super.onCollision(intersectionPoints, other);
  }

}