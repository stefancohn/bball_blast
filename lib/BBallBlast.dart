import 'dart:async';
import 'package:bball_blast/entities/Ball.dart';
import 'package:bball_blast/scenes/GameOver.dart';
import 'package:bball_blast/scenes/MainMenu.dart';
import 'package:bball_blast/scenes/Gameplay.dart';
import 'package:flame/camera.dart';
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

  //helper vars
  late Vector2 impulse;
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

    //debugMode = true;
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
      if (!gameplay.isShot){
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
    minForce = enoughForce();
    if (gameplaying && minForce && !gameplay.isShot){
      //make sure there is enough 'umff' for ball to be thrown 
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

  //method to make sure players don't accidently launch ball with no speed
  bool enoughForce() {
    if (impulse.x.abs() < minStrength && impulse.y.abs() < minStrength ) {
      gameplay.dragBehindBall = Offset.zero;
      gameplay.isDragging = false;
      return false;
    }
    return true;
  }
} 