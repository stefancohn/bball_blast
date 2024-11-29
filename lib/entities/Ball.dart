import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/Backend.dart';
import 'package:bball_blast/config.dart';
import 'package:bball_blast/entities/TrailEffect.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

class Ball extends BodyComponent with HasGameRef<Forge2DGame>, ContactCallbacks {
  @override
  final BBallBlast game;
  @override
  Vector2 position;
  double radius;

  late Sprite ballImg;
  SpriteComponent? ballSprite;

  //collider wrapper
  late Collider collider; 
  bool wentAboveRim = false; 

  //points to draw for trajectory
  late List<Vector2> points;

  //FOR GENERATE TRAJ METHODS
  static double velocityRatio = 1/5.026548245743669;
  static Random rand = Random();

  //how far trajectory projection should be
  static int steps = 40;


  Ball(this.game, this.position, this.radius, this.ballImg) : super (
    renderBody: false,
    priority: 3,

  );

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      position: Vector2(position.x, startingYForComponents),
      type: BodyType.static,
      linearDamping: 0,
      userData: this, 
    );

    final body = world.createBody(bodyDef);

    final shape = CircleShape()
      ..radius = radius;

    final fixtureDef = FixtureDef(shape)
      ..userData = this
      ..restitution = 0.3
      ..friction = 0.4
      ..density = 0.1;

    body.createFixture(fixtureDef);

    return body;
  }

  @override
  Future<void> onLoad() async {
    //reset for proper coloration
    game.impulse = Vector2.zero();

    //add collider
    collider = Collider(game, this);
    await game.world.add(collider);

    ballSprite = SpriteComponent(
        sprite: ballImg,
        size: Vector2.all(radius*2),
        anchor: Anchor.center,
        priority: 3,
    );
    await add(ballSprite!);

    TrailEffect trail = TrailEffect(ball: this);
    game.world.add(trail);

    super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    _checkBallAboveRim();

    _forceColoration();
  }

  double forceAppliedAbsMax = 650;
  //apply red filter over ball depending on how much force will get applied
  Future<void> _forceColoration() async {
    //get 0-1 num based on how much pull is given to ball
    double forceAppliedAbs = game.impulse.x.abs() + game.impulse.y.abs();
    double forceAppliedPerc = min((forceAppliedAbs/forceAppliedAbsMax),1.0);
    bool entryOnce = false; //want to apply last filter only once 

    //apply red filter based on intensity of pull if has not been shot
    if (ballSprite != null && !BBallBlast.gameplay.isShot && ballSprite!.children.isEmpty) {
        await ballSprite!.add(ColorEffect(
          Color.fromRGBO((forceAppliedPerc * 255).round(), 33, 0, 1),
          opacityTo: (forceAppliedPerc), //helps get smooth look
          EffectController(duration: 0.0),
        ));
    } 
    //else apply no filter when ball gets shot
    else if (ballSprite != null && BBallBlast.gameplay.isShot && !entryOnce) {
      await ballSprite!.add(ColorEffect(
        const Color.fromRGBO(255, 255, 255, 1),
        opacityTo: (forceAppliedPerc), //helps get smooth look
        EffectController(duration: 1),
      ));
      entryOnce = true;
    }
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

  //contact callbacks for physics bodies
  @override
  void beginContact(Object other, Contact contact) {
    if (other == BBallBlast.gameplay.wallRight) {
      BBallBlast.gameplay.wallBumpAnimation(isLeft: false);
    } else if (other == BBallBlast.gameplay.wallLeft) {
      BBallBlast.gameplay.wallBumpAnimation(isLeft: true);
    }

    //play sound on any collision
    
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
    //move collider with physical body
    super.position = Vector2(ball.getSuperPosition().x - ball.radius, ball.getSuperPosition().y - ball.radius);
    super.update(dt);
  }

  @override
  Future<void> onCollision(Set<Vector2> intersectionPoints, PositionComponent other) async {
    //if the ball hit the hoop collider and went over it
    if (other == (BBallBlast.gameplay.hoop.hoopCollDetect) && ball.wentAboveRim) {
      BBallBlast.gameplay.ballScored = true;
    } 

    //if ball hits coin and not yet collected, play collected animation for coin &
    //update coinAmt display
    if (other == BBallBlast.gameplay.coin && !BBallBlast.gameplay.coin.collected) {
      await BBallBlast.gameplay.coin.playCollectedAnimation();
      await Backend.initializeCoinAmt();
    }
    
    super.onCollision(intersectionPoints, other);
  }

}