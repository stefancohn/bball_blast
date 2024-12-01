import 'dart:async';
import 'package:bball_blast/Backend.dart';
import 'package:bball_blast/entities/Ball.dart';
import 'package:bball_blast/scenes/CustomizeMenu.dart';
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
import 'package:sqflite/sqflite.dart';


class BBallBlast extends Forge2DGame with PanDetector, HasGameRef<BBallBlast>, HasCollisionDetection, CollisionCallbacks, HasTimeScale {
  //scenes
  static late Gameplay gameplay;
  static late MainMenu mainMenu;
  static late Gameover gameover;
  static late CustomizeMenu customMenu;

  RectangleComponent? fader;


  //statemanagement
  bool gameplaying = false; 
  late Component currentScene;
  late Timer gamePlayingDelay;

  //helper vars
  late Vector2 impulse = Vector2.zero();
  double minStrength = 40;
  late bool minForce;

  final Database database;
  static var db; 


  //--------CONSTRUCTOR-------------
  BBallBlast({required this.database}): super(
      gravity: Vector2(0,gravity),
      camera: CameraComponent.withFixedResolution(width: gameWidth, height: gameHeight),
      zoom: 8,
  );




  //----------ONLOAD------------------
  @override
  FutureOr<void> onLoad() async {
    //set up static db
    db = database;

    //start with loading all necessary things from DB
    await Backend.acquireBallPath();
    await Backend.acquireBump();
    await Backend.acquireTrail();
    await Backend.getAllAcquiredBgs();

    await Backend.loadBallsForMenu();
    await Backend.loadTrailsForMenu();
    await Backend.loadBumpsForMenu();
    await Backend.loadBgsForMenu();

    await Backend.initializeCoinAmt();
    await Backend.addLotsOfCoins();

    game.camera.viewfinder.position.setAll(0);

    await loadMainMenuScene();

    gamePlayingDelay = Timer(0.3, onTick: ()=> gameplaying = true);

    fader = _initializeFader();
    await add(fader!);

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
      if (!(child is Forge2DWorld || child is CameraComponent|| child == fader)){
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
    //if back to home after game started, use transition
    if (fader != null) {
      gameplay.hoop.fadeOutAllComponents(.75); //fade hoop and coin
      gameplay.coin.fadeOut(.75);
      gameplay.ball.fadeOutAllComponentsTo(transparency: 0, duration: .75);
      fader!.add(OpacityEffect.fadeIn(EffectController(duration:.75), onComplete: () async {
        fader!.add(OpacityEffect.fadeOut(EffectController(duration: .75)));
        removeScene();
        resetWorld();
        mainMenu = MainMenu();
        currentScene = mainMenu;
        await add(mainMenu);
      }));
    } 
    //on load of game
    else {
      removeScene();
      resetWorld();
      mainMenu = MainMenu();
      currentScene = mainMenu;
      await add(mainMenu);
    }
  }

  //load gameplay
  void loadGameScene() async {
    fader!.add(OpacityEffect.fadeIn(EffectController(duration: .75), onComplete: () async {
      fader!.add(OpacityEffect.fadeOut(EffectController(duration: .75)));
      removeScene();
      resetWorld();

      gameplay = Gameplay();
      await add(gameplay);
      gameplaying = true;

      currentScene = gameplay;
    }));
  }

  void loadGameoverScene() async {
    //await add(fader);
    gameplay.hoop.fadeOutAllComponents(.75); //fade hoop and coin
    gameplay.coin.fadeOut(.75);

    //fade everything else and call appropriate functions once complete
    fader!.add(OpacityEffect.fadeIn(EffectController(duration:.75), onComplete: () async {
      removeScene();
      resetWorld();
      gameover = Gameover();
      await add(gameover);
      gameplaying = false;
      currentScene  = gameover;
      fader!.add(OpacityEffect.fadeOut(EffectController(duration: .75)));

    },));
  }

  void loadCustomizerScene() async {
    fader!.add(OpacityEffect.fadeIn(EffectController(duration: .75), onComplete: () async {
      fader!.add(OpacityEffect.fadeOut(EffectController(duration: .75)));

      removeScene();
      resetWorld();

      customMenu = CustomizeMenu();
      await add(customMenu);
      
      gameplaying = false;
      currentScene = customMenu; 
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
        //print(Ball.getInitialVelToScore(gameplay.hoop.position, gameplay.ball.position) / Ball.velocityRatio);

        //so ball spins
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
    RectangleComponent fader = RectangleComponent(
      size: camera.viewport.size,
      position: camera.viewport.position,
      paint: insideWhite,
      priority: 5,
    );
    fader.opacity = 0;
    return fader;
  }
} 