import 'dart:async';
import 'package:bball_blast/Background.dart';
import 'package:bball_blast/entities/Hoop.dart';
import 'package:bball_blast/entities/Wall.dart';
import 'package:bball_blast/entities/ball.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:bball_blast/config.dart';

class BBallBlast extends Forge2DGame with PanDetector, HasGameRef<BBallBlast>, HasCollisionDetection, CollisionCallbacks {
  //vars we need to be visible thoughout entire file------------------------
  late Ball ball; 
  late Hoop hoop;
  late Sprite ballImg;
  late Sprite hoopImg;
  double linearImpulseStrengthMult = 12.5;
  late Vector2 impulse;

  //positional vars
  double startPosX = 00;
  double startPosY = 00;
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



  //--------CONSTRUCTOR-------------
  BBallBlast(): super(
      gravity: Vector2(0,gravity),
      camera: CameraComponent.withFixedResolution(width: gameWidth, height: gameHeight),
  );




  //----------ONLOAD------------------
  @override
  FutureOr<void> onLoad() async {
    //set startPos of ball
    startPos = Vector2(startPosX, startPosY);

    //load images into cache
    await images.loadAllImages();

    //make ballSprite and ball
    ballImg = await loadSprite('ball.png');
    //_randomBallPos();
    ball = Ball(this, Vector2(startPosX, startPosY), 3, ballImg);

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
    scoredOpsTimer = Timer(0.5, onTick: () => spawnNewScene());

    //print("TOP LEFT: ${camera.visibleWorldRect.topLeft}");
    //print("BOTTOM LEFT: ${camera.visibleWorldRect.bottomRight}");

    debugMode=true;
    super.onLoad();
  }




  //------UPDATE LOOP---------------
  @override
  void update(double dt) {
    super.update(dt);

    if (ballScored) {
      scoredOpsTimer.update(dt);
    }

  }




  //------------OTHER METHODS-----------
  //reset our scene
  void spawnNewScene() async {
    //reset vars and timer
    isShot = false;
    ballScored = false;
    spawnRight = !spawnRight;
    scoredOpsTimer.stop();
    scoredOpsTimer.start();

    //remove ball and its children 
    ball.collider.removeFromParent();
    ball.removeFromParent();

    //remove hoop and children
    hoop.rightHb.removeFromParent();
    hoop.leftHb.removeFromParent();
    hoop.hoopCollDetect.removeFromParent();
    hoop.removeFromParent();
    
    //Create and add new ball, hoop
    ball = Ball(this, Vector2(startPosX, startPosY), 3, ballImg);
    await world.add(ball);
    hoop = Hoop(this, spawnRight, hoopImg);
    await world.add(hoop);
  }

  //random ball spawn



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
    print("BALL MASS: ${ball.body.mass}");

    //reset necessary vars 
    isDragging=false;
    isShot = true;
    dragBehindBall = Offset(startPosX, startPosY);
  }
  
} 

