import 'dart:async';
import 'dart:math';
import 'package:bball_blast/Background.dart';
import 'package:bball_blast/entities/Hoop.dart';
import 'package:bball_blast/entities/Wall.dart';
import 'package:bball_blast/entities/ball.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:bball_blast/config.dart';

class BBallBlast extends Forge2DGame with PanDetector, HasGameRef<BBallBlast>, HasCollisionDetection, CollisionCallbacks {
  //vars we need to be visible thoughout entire file------------------------
  late Ball ball; 
  late Hoop hoop;
  late Sprite ballImg;
  late Sprite hoopImg;
  double linearImpulseStrengthMult = 10;
  late Vector2 impulse;
  late List<Vector2> points;
  Random rand = Random();
  late RouterComponent router; 

  //positional vars
  late Vector2 startPos;

  //Vars for determining how ball should be thrown
  late Offset startOfDrag;
  late Offset currentDragPos;
  late Offset dragBehindBall = Offset.zero;
  bool isDragging = false;
  bool isShot = false;

  //ball score and spawn vars
  bool ballScored = false;
  late Timer scoredOpsTimer;
  bool spawnRight = true;
  int score = 0;



  //--------CONSTRUCTOR-------------
  BBallBlast(): super(
      gravity: Vector2(0,gravity),
      camera: CameraComponent.withFixedResolution(width: gameWidth, height: gameHeight),
      zoom: 11,
  );




  //----------ONLOAD------------------
  @override
  FutureOr<void> onLoad() async {
    router = RouterComponent(
      initialRoute: 'gameplay',
      routes: {
        'gameplay': Route(Background.new),
      }
    );
    //await world.add(router);
    //set startPos of ball
    startPos = _randomBallPos();

    //load images into cache
    await images.loadAllImages();

    //make ballSprite and ball
    ballImg = await loadSprite('ball.png');
    //_randomBallPos();
    ball = Ball(this, startPos, 3, ballImg);

    //add leftWall and rightWall, and ceiling
    Wall wallLeft = Wall(Vector2(camera.visibleWorldRect.topLeft.dx-1, camera.visibleWorldRect.topLeft.dy), 1.0, gameHeight);
    Wall wallRight = Wall(Vector2(camera.visibleWorldRect.topRight.dx+1, camera.visibleWorldRect.topRight.dy), 1.0, gameHeight);
    Wall ceiling = Wall(Vector2(camera.visibleWorldRect.topLeft.dx-1, camera.visibleWorldRect.topRight.dy-1), gameWidth, 1.0);

    //create hoopimg, hoop, and add it
    hoopImg = await loadSprite('hoop.png');
    hoop = Hoop(this, spawnRight, hoopImg);

    //add components to game  
    await world.addAll([Background(), ball, wallLeft, wallRight, ceiling, hoop]);

    //launch method to spawn new scene
    scoredOpsTimer = Timer(0.5, onTick: () => _resetScene());

    //print("TOP LEFT: ${camera.visibleWorldRect.topLeft}");
    //print("BOTTOM LEFT: ${camera.visibleWorldRect.bottomRight}");

    debugMode=true;
    super.onLoad();
  }




  //------UPDATE LOOP---------------
  @override
  void update(double dt) {
    //if ball gets scored start scored operations timer 
    if (ballScored) {
      scoredOpsTimer.update(dt);
    }

    super.update(dt);
  }





  //------------OTHER METHODS-----------
  //reset our scene
  void _resetScene() async {
    //reset vars and timer
    isShot = false;
    ballScored = false;
    spawnRight = !spawnRight;
    scoredOpsTimer.stop();
    scoredOpsTimer.start();
    score++; //add to score

    //remove ball and its children 
    ball.collider.removeFromParent();
    ball.removeFromParent();

    //remove hoop and children
    hoop.rightHb.removeFromParent();
    hoop.leftHb.removeFromParent();
    hoop.hoopCollDetect.removeFromParent();
    hoop.removeFromParent();
    

    //Create and add new ball, hoop
    startPos = _randomBallPos();
    ball = Ball(this, startPos, 3, ballImg);
    await world.add(ball);
    hoop = Hoop(this, spawnRight, hoopImg);
    await world.add(hoop);
  }

  //random ball spawn
  Vector2 _randomBallPos() {
    double randomY = (rand.nextDouble() * 65) - 25;
    if (spawnRight) {
      double randomX = -10 + rand.nextDouble() * -15;
      return Vector2(randomX,randomY);
    } else {
      double randomX = (rand.nextDouble() * 15) + 10;
      return Vector2(randomX,randomY);
    }
  }




  //----------------------DRAWING----------------------------
    @override
  void render(Canvas canvas){
    super.render(canvas);

    //
    //render the projected trajectory
    if (isDragging) {
      //we multiply the input by that number as it's the ratio that converts pixel to velocity
      Vector2 initialVelocity = Vector2(dragBehindBall.dx, dragBehindBall.dy) * linearImpulseStrengthMult * Ball.velocityRatio;
      //initialVelocity = Ball.checkVelMax(initialVelocity);

      //get points to draw projected trajectory
      points = Ball.trajectoryPoints(initialVelocity, startPos, Ball.steps, (1/60)); //60 fps so our dt is 1/60

      Paint paint = Paint()
        ..color = const Color.fromRGBO(244, 67, 54, 1)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < points.length - 1; i++) {
        //conversion to put accurately
        Vector2 point1 = worldToScreen(points[i]);
        Vector2 point2 = worldToScreen(points[i+1]);
        canvas.drawLine(
          Offset(point1.x, point1.y),
          Offset(point2.x, point2.y),
          paint,
        );
      }
    }

    //score text
    textPaint.render(canvas, "$score", worldToScreen(Vector2(0, camera.visibleWorldRect.top)));
  }




  //-----------------------INPUT HANDLING (DRAGS)-----------------------
  @override
  void onPanStart(DragStartInfo info) {
    //when user drags screen, store whre it happened and let program know dragging=true
    if (!isShot){
      startOfDrag = Offset(info.eventPosition.global.x, info.eventPosition.global.y);
      isDragging = true;
    }
  }

  @override 
  void onPanUpdate(DragUpdateInfo info) {
    if (!isShot){
      //we get the dragPos, then we get the distance of the drag relative to starting point 
      //then apply it to our "dragBehindBall" which is given to trajectory drawing 
      currentDragPos = Offset(info.eventPosition.global.x, info.eventPosition.global.y);
      double relX = startOfDrag.dx - currentDragPos.dx;
      double relY = startOfDrag.dy - currentDragPos.dy;
      dragBehindBall = Offset((relX), (relY));
    }
  }

  @override
  void onPanEnd(DragEndInfo info) {
    //make ball move when thrown
    ball.body.setType(BodyType.dynamic);
    impulse = Vector2(dragBehindBall.dx, dragBehindBall.dy) * linearImpulseStrengthMult;
    ball.body.applyLinearImpulse(impulse);

    //reset necessary vars 
    isDragging=false;
    isShot = true;
    dragBehindBall = Offset.zero;
  }
  
} 