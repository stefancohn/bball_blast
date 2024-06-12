import 'dart:async';
import 'package:bball_blast/entities/Ball.dart';
import 'package:bball_blast/scenes/GameOver.dart';
import 'package:bball_blast/scenes/MainMenu.dart';
import 'package:bball_blast/scenes/Gameplay.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:bball_blast/config.dart';
import 'package:flutter/material.dart';


class BBallBlast extends Forge2DGame with PanDetector, HasGameRef<BBallBlast>, HasCollisionDetection, CollisionCallbacks, HasTimeScale {
  //scenes
  static late Gameplay gameplay;
  static late MainMenu mainMenu;
  static late Gameover gameover;

  late RectangleComponent _fader;


  //statemanagement
  bool gameplaying = false; 
  late Component currentScene;
  late Timer gamePlayingDelay;

  //helper vars
  late Vector2 impulse = Vector2.zero();
  double minStrength = 40;
  late bool minForce;



  //--------CONSTRUCTOR-------------
  BBallBlast(): super(
      gravity: Vector2(0,gravity),
      camera: CameraComponent.withFixedResolution(width: gameWidth, height: gameHeight),
      zoom: 8,
  );




  //----------ONLOAD------------------
  @override
  FutureOr<void> onLoad() async {
    game.camera.viewfinder.position.setAll(0);

    await loadMainMenuScene();

    gamePlayingDelay = Timer(0.3, onTick: ()=> gameplaying = true);

    _fader = _initializeFader();

    //debugMode = true;
    super.onLoad();
  }

  //background color to white
  @override
  Color backgroundColor() => const Color.fromARGB(255, 255, 255, 255);




  //-------------------OTHER METHODS-------------------------

  //when switching scenes, need to reset world so we have this to 
  //remove all child componenents FROM WORLD
  //the WORLD is EVERYTHING THAT INTERACTS WITHIN A GAME
  //IF NOT, JUST ADD TO COMPONENT LIKE UI ELEMENTS
  void resetWorld() {
    // ignore: avoid_function_literals_in_foreach_calls
    world.children.forEach((child) => child.removeFromParent());
  }

  //Remove Scene from game (takes off ui components and such) 
  void removeScene() async {
    //remove game children
    children.forEach((child) {
      if (!(child is Forge2DWorld || child is CameraComponent)){
        child.removeFromParent();
      }
    });
    
    //remove backdrop
    if (camera.backdrop.hasChildren){
      camera.backdrop.children.first.removeFromParent();
    }
  }

  //load main menu 
  loadMainMenuScene() async {
    removeScene();
    resetWorld();

    mainMenu = MainMenu();
    currentScene = mainMenu;
    await add(mainMenu);

  }

  //load gameplay
  void loadGameScene() async {
    removeScene();
    resetWorld();

    await add(_fader);
    gameplay = Gameplay();
    await add(gameplay);
    gameplaying = true;

    _fader.add(OpacityEffect.fadeOut(EffectController(duration: 1.5)));

    currentScene = gameplay;
  }

  void loadGameoverScene() async {
    await add(_fader);
    gameplay.hoop.fadeOutAllComponents(1.5); //fade hoop
    //fade everything else and call appropriate functions once complete
    _fader.add(OpacityEffect.fadeIn(EffectController(duration:1.5), onComplete: () async {
      removeScene();
      resetWorld();
      gameover = Gameover();
      await add(gameover);
      gameplaying = false;
      currentScene  = gameover;
    },));
  }
  ///////////




  //-----------------------INPUT HANDLING (DRAGS)-----------------------
  @override
  void onPanStart(DragStartInfo info) {
    //when user drags screen, store whre it happened and let program know dragging=true
    if (gameplaying) {
      if (!gameplay.isShot && gameplay.readyToBeShot){
      //ball can't be shot and must be ready
        gameplay.startOfDrag = Offset(info.eventPosition.global.x, info.eventPosition.global.y);
        gameplay.isDragging = true;
      }
    }
  }

  @override 
  void onPanUpdate(DragUpdateInfo info) {
    if (gameplaying) {
      if (!gameplay.isShot && gameplay.readyToBeShot && gameplay.isDragging){
        //we get the dragPos, then we get the distance of the drag relative to starting point 
        //then apply it to our "dragBehindBall" which is given to trajectory drawing 
        gameplay.currentDragPos = Offset(info.eventPosition.global.x, info.eventPosition.global.y);
        double relX = gameplay.startOfDrag.dx - gameplay.currentDragPos.dx;
        double relY = gameplay.startOfDrag.dy - gameplay.currentDragPos.dy;
        gameplay.dragBehindBall = Offset((relX), (relY));
        impulse = Vector2(gameplay.dragBehindBall.dx, gameplay.dragBehindBall.dy) * gameplay.linearImpulseStrengthMult;
        impulse = Ball.checkVelMaxImpulse(impulse);
      }
    }
  }

  @override
  void onPanEnd(DragEndInfo info) {
    
    //if the ball is readytobeshot, isshot, has minimum force and the game is being played
    if (gameplaying) {
      //make sure there is enough 'umff' for ball to be thrown 
      minForce = _enoughForce();
      if (minForce && !gameplay.isShot && gameplay.readyToBeShot && gameplay.isDragging){
        //make ball move when thrown
        gameplay.ball.body.setType(BodyType.dynamic);
        Ball.velocityRatio = 1/gameplay.ball.body.mass;
        gameplay.ball.body.applyLinearImpulse(impulse);
        gameplay.ball.body.applyAngularImpulse(impulse.x * -1);
        //print("BALL MASS: ${gameplay.ball.body.mass}");


        //change necessary vars 
        gameplay.isDragging=false;
        gameplay.isShot = true;
        gameplay.dragBehindBall = Offset.zero;
      }
    }
  }

  //method to make sure players don't accidently launch ball with no speed
  bool _enoughForce() {
    if (impulse.x.abs() < minStrength && impulse.y.abs() < minStrength && gameplay.readyToBeShot) {
      gameplay.dragBehindBall = Offset.zero;
      gameplay.isDragging = false;
      return false;
    }
    return true;
  }

  RectangleComponent _initializeFader() {
    return RectangleComponent(
      size: camera.viewport.size,
      position: camera.viewport.position,
      paint: insideWhite,
    );
  }
} 