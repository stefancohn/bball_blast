import 'dart:async';
import 'package:bball_blast/scenes/GameOver.dart';
import 'package:bball_blast/scenes/MainMenu.dart';
import 'package:bball_blast/scenes/gameplay.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:bball_blast/config.dart';

class BBallBlast extends Forge2DGame with PanDetector, HasGameRef<BBallBlast>, HasCollisionDetection, CollisionCallbacks {
  //scenes
  static Gameplay gameplay = Gameplay();
  static MainMenu mainMenu = MainMenu();
  static Gameover gameover = Gameover();

  //statemanagement
  bool gameplaying = false; 




  //--------CONSTRUCTOR-------------
  BBallBlast(): super(
      gravity: Vector2(0,gravity),
      camera: CameraComponent.withFixedResolution(width: gameWidth, height: gameHeight),
      zoom: 11,
  );




  //----------ONLOAD------------------
  @override
  FutureOr<void> onLoad() async {
    add(mainMenu);
    

    debugMode = true;
    super.onLoad();
  }


  //-------------------OTHER METHODS-------------------------
  ///////////
  //////////

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
    removeAll(children);
  }

  void loadGameScene() async {
    await game.add(gameplay);
    gameplaying = true;
    removeScene();
  }

  void loadGameoverScene() async {
    await game.add(gameover);
    gameplaying = false;
    removeScene();
    resetWorld();
  }
  ///////////
  ///////////
  ///////////


  //-----------------------INPUT HANDLING (DRAGS)-----------------------
  @override
  void onPanStart(DragStartInfo info) {
    //when user drags screen, store whre it happened and let program know dragging=true
    if (!gameplay.isShot){
      gameplay.startOfDrag = Offset(info.eventPosition.global.x, info.eventPosition.global.y);
      gameplay.isDragging = true;
    }
  }

  @override 
  void onPanUpdate(DragUpdateInfo info) {
    if (!gameplay.isShot){
      //we get the dragPos, then we get the distance of the drag relative to starting point 
      //then apply it to our "dragBehindBall" which is given to trajectory drawing 
      gameplay.currentDragPos = Offset(info.eventPosition.global.x, info.eventPosition.global.y);
      double relX = gameplay.startOfDrag.dx - gameplay.currentDragPos.dx;
      double relY = gameplay.startOfDrag.dy - gameplay.currentDragPos.dy;
      gameplay.dragBehindBall = Offset((relX), (relY));
    }
  }

  @override
  void onPanEnd(DragEndInfo info) {
    //make ball move when thrown
    gameplay.ball.body.setType(BodyType.dynamic);
    gameplay.impulse = Vector2(gameplay.dragBehindBall.dx, gameplay.dragBehindBall.dy) * gameplay.linearImpulseStrengthMult;
    gameplay.ball.body.applyLinearImpulse(gameplay.impulse);

    //reset necessary vars 
    gameplay.isDragging=false;
    gameplay.isShot = true;
    gameplay.dragBehindBall = Offset.zero;
  }
} 