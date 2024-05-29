import 'dart:async';
import 'package:bball_blast/scenes/GameOver.dart';
import 'package:bball_blast/scenes/MainMenu.dart';
import 'package:bball_blast/scenes/Gameplay.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:bball_blast/config.dart';


class BBallBlast extends Forge2DGame with PanDetector, HasGameRef<BBallBlast>, HasCollisionDetection, CollisionCallbacks, HasTimeScale {
  //scenes
  static late Gameplay gameplay;
  static late MainMenu mainMenu;
  static late Gameover gameover;

  //statemanagement
  bool gameplaying = false; 
  late Component currentScene;
  late Timer gamePlayingDelay;




  //--------CONSTRUCTOR-------------
  BBallBlast(): super(
      gravity: Vector2(0,gravity),
      camera: CameraComponent.withFixedResolution(width: gameWidth, height: gameHeight),
      zoom: 11,
  );




  //----------ONLOAD------------------
  @override
  FutureOr<void> onLoad() async {
    await loadMainMenuScene();
    gamePlayingDelay = Timer(0.3, onTick: ()=> gameplaying = true);

    debugMode = true;
    super.onLoad();
  }



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
    children.forEach((child) {
      if (!(child is Forge2DWorld || child is CameraComponent)){
        child.removeFromParent();
      }
    });
  }

  //load main menu 
  loadMainMenuScene() async {
    removeScene();
    resetWorld();

    mainMenu = MainMenu();
    currentScene = mainMenu;

    add(mainMenu);
  }

  //load gameplay
  void loadGameScene() async {
    removeScene();
    resetWorld();

    gameplay = Gameplay();
    await game.add(gameplay);
    gameplaying = true;

    currentScene = gameplay;
  }

  void loadGameoverScene() async {
    removeScene();
    resetWorld();

    gameover = Gameover();
    await game.add(gameover);
    gameplaying = false;
    currentScene  = gameover;
  }
  ///////////



  @override
  void update(double dt) {
    super.update(dt);
    //print(gameplaying);
  }



  //-----------------------INPUT HANDLING (DRAGS)-----------------------
  @override
  void onPanStart(DragStartInfo info) {
    //when user drags screen, store whre it happened and let program know dragging=true
    if (gameplaying) {
      if (!gameplay.isShot){
        gameplay.startOfDrag = Offset(info.eventPosition.global.x, info.eventPosition.global.y);
        gameplay.isDragging = true;
      }
    }
  }

  @override 
  void onPanUpdate(DragUpdateInfo info) {
    if (gameplaying) {
      if (!gameplay.isShot && gameplaying){
        //we get the dragPos, then we get the distance of the drag relative to starting point 
        //then apply it to our "dragBehindBall" which is given to trajectory drawing 
        gameplay.currentDragPos = Offset(info.eventPosition.global.x, info.eventPosition.global.y);
        double relX = gameplay.startOfDrag.dx - gameplay.currentDragPos.dx;
        double relY = gameplay.startOfDrag.dy - gameplay.currentDragPos.dy;
        gameplay.dragBehindBall = Offset((relX), (relY));
      }
    }
  }

  @override
  void onPanEnd(DragEndInfo info) {
    if (gameplaying){
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
} 