import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/Background/ParallaxBackground.dart';
import 'package:bball_blast/entities/Hoop.dart';
import 'package:bball_blast/entities/Wall.dart';
import 'package:bball_blast/entities/ball.dart';
import 'package:bball_blast/scenes/PauseOverlay.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:bball_blast/config.dart';
import 'package:flame/input.dart';
import 'package:flame/particles.dart';
import 'package:flame/sprite.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

class Gameplay extends Component with HasGameRef<BBallBlast>{
  //vars we need to be visible thoughout entire file------------------------
  late Ball ball; 
  late Hoop hoop;

  late Sprite ballImg;
  late Sprite hoopLowerImg;
  late Sprite hoopUpperImg;
  late Sprite backboardImg;
  late Sprite wallBumpAniImg;
  late Wall wallLeft;
  late Wall wallRight;

  double linearImpulseStrengthMult = 3;
  double radius = 4;
  late List<Vector2> points;
  Random rand = Random();

  //vars for pause functionality 
  late ButtonComponent pauseButton;
  late PauseOverlay pauseOverlay; 

  //positional vars
  late Vector2 startPos;

  //Vars for determining how ball should be thrown
  late Offset startOfDrag = Offset.zero;
  late Offset currentDragPos = Offset.zero;
  late Offset dragBehindBall = Offset.zero;

  //ball score and spawn/death vars
  bool isDragging = false;
  bool isShot = false;
  bool readyToBeShot = false; 
  bool ballScored = false;
  bool spawnRight = true;
  bool died = false; 
  late Timer scoredOpsTimer;
  late Timer gameoverOpsTimer;
  int score = 0;

   late Timer bumpedTooSoonReset = Timer(0.25, onTick: () { 
      bumpedTooSoon = false;
  });

  late ParallaxBackground bg;

  late SpriteSheet wallBumpAniSpritesheet;

  late List<Paint> wallParticlePaints;

  //----------ONLOAD------------------
  @override
  FutureOr<void> onLoad() async {
    priority = 0;

    //set startPos of ball
    startPos = _randomBallPos();

    //create our objects 
    await _intiializeObjects();

    super.onLoad();
  }




  //----------------------DRAWING----------------------------
  ///////////
  ///////////
  @override
  void render(Canvas canvas){
    super.render(canvas);

    //render the projected trajectory
    if (isDragging && readyToBeShot) {
      //we multiply the input by that number as it's the ratio that converts pixel to velocity
      Vector2 initialVelocity = Vector2(dragBehindBall.dx, dragBehindBall.dy) * linearImpulseStrengthMult * Ball.velocityRatio;
      initialVelocity = Ball.checkVelMax(initialVelocity);

      //get points to draw projected trajectory
      points = Ball.trajectoryPoints(initialVelocity, startPos, Ball.steps, (1/60)); //60 fps so our dt is 1/60

      for (int i = 0; i < points.length; i++) {
        //conversion to put accurately
        Vector2 point1 = game.worldToScreen(points[i]);

        //if within bounds of world, draw trajectory circles
        if (game.camera.viewport.position.x < point1.x && point1.x < (game.camera.viewport.size.x + game.camera.viewport.position.x)
        && game.camera.viewport.position.y < point1.y && point1.y < (game.camera.viewport.size.y + game.camera.viewport.position.y)){
          canvas.drawCircle(
            point1.toOffset(),
            circleRadius,
            outline
          );
          canvas.drawCircle(
            point1.toOffset(),
            circleRadius - (outlineWidth/2),
            Paint()..color=const Color.fromARGB(255, 254, 255, 255)
              ..style = PaintingStyle.fill
          );
        }
      }
    }

    //score text
    textPaintBlack.render(canvas, "$score", game.worldToScreen(Vector2(0, game.camera.visibleWorldRect.top+10)), anchor: Anchor.center);
    textPaint.render(canvas, "$score", game.worldToScreen(Vector2(0, game.camera.visibleWorldRect.top+10)), anchor: Anchor.center);
  }




  //------UPDATE LOOP---------------
  @override
  void update(double dt) {
    super.update(dt);

    //if ball gets scored start scored operations timer 
    //ballScored var gets updated in Hoop class because that class contains hit box logic 
    if (ballScored) {
      //make ball fade out of existance!
      ball.children.first.add(OpacityEffect.fadeOut(EffectController(duration: 3.0)));
      hoop.fadeOutAllComponents(3);
      scoredOpsTimer.update(dt);
    }

    if (game.world.children.contains(ball)) {
      //ball intro 
      ballSpawnIntro(dt);

      //check if ball has missed AKA gone beyond the bottom of the world 
      if (ball.getSuperPosition().y > game.camera.visibleWorldRect.bottom + 5 && !ballScored) {
        gameoverOpsTimer.update(dt); //start gameover operations
        ball.collider.removeFromParent();
      }
    }

    bumpedTooSoonReset.update(dt);
  }




  //------------OTHER METHODS-----------
  //reset our scene
  spawnNewScene() async {
    //reset vars and timer
    isShot = false;
    ballScored = false;
    readyToBeShot = false;
    spawnRight = !spawnRight;
    scoredOpsTimer.stop();
    scoredOpsTimer.start();
    score++; //add to score

    //reset world components
    for (var child in game.world.children) {
      if (child is! Wall) {
        game.world.remove(child);
      }
    }
    
    //Create and add new ball, hoop
    startPos = _randomBallPos();
    ball = Ball(game, startPos, radius, ballImg);
    await game.world.add(ball);
    hoop = Hoop(spawnRight, hoopLowerImg, hoopUpperImg, backboardImg);
    await game.world.add(hoop);

    //change background
    bg.spawnRectMask();
  }

  //spawn the gameover scene when ded
  void spawnGameoverScene() async {
    gameoverOpsTimer.stop();
    gameoverOpsTimer.start();

    game.loadGameoverScene();
  }

  //random ball spawn
  Vector2 _randomBallPos() {
    double randomY = (rand.nextDouble() * 73) - 30;
    if (spawnRight) {
      double randomX = -16 + rand.nextDouble() * -3;
      return Vector2(randomX,randomY);
    } else {
      double randomX = (rand.nextDouble() * 3) + 16;
      return Vector2(randomX,randomY);
    }
  }

  //need this to remove pause overlay
  void removePauseOverlay() {
    remove(pauseOverlay);
    game.timeScale = 1;
  }

  //this gives a lil intro when ball and hoop get added
  void ballSpawnIntro(double dt) {
    if (ball.body.position.y <= startPos.y && !readyToBeShot) {
      ball.body.position.y += 55 * dt;
    } else {
      readyToBeShot = true;
    }
  }

  //
  //method to spawn a new wall bump particle and add it to wall
  //works via collision detect via ball collider. it calls on this method with the proper position
  //and whether the particle should be "flipped" depending on what ball it hits
  bool bumpedTooSoon = false; 
  late double leftWorldToScreen = game.worldToScreen(game.camera.visibleWorldRect.topLeft.toVector2()).x; 
  late double rightWorldToScreen = game.worldToScreen(game.camera.visibleWorldRect.topRight.toVector2()).x; 
  Future<void> wallBumpAnimation(bool flip) async {
    //make sure hasn't been bumped too soon
    if  (!bumpedTooSoon){
      //select a random paint from our list of paints
      Paint paint = wallParticlePaints[rand.nextInt(wallParticlePaints.length)];

      ParticleSystemComponent wallBumpShow = ParticleSystemComponent(
        position: Vector2(rightWorldToScreen - 25, game.camera.viewport.size.y/2), //manual adjustments needed
        particle: SpriteAnimationParticle(
          animation: wallBumpAniSpritesheet.createAnimation(row: 0, stepTime: 3.5, from: 0, to: 20),
          size: Vector2(50, game.camera.viewport.size.y + 30),
          overridePaint: paint
        ),
        anchor: Anchor.center,
      );

      //if on left side of world, flip and adjust position a lil
      if (flip) {
        wallBumpShow.x = leftWorldToScreen + 25;
        wallBumpShow.flipHorizontally();
      }
      
      //start a timer that reinstates bumpedTooSoon after .25 seconds
      bumpedTooSoon = true;
      bumpedTooSoonReset.start();

      await add(wallBumpShow);
    }
  }

  //initialize all objects add add them to world/game
  Future<void> _intiializeObjects()  async {
    await _loadAllImages();
    //make ballSprite and ball
    ball = Ball(game, startPos, radius, ballImg);

    //add leftWall and rightWall, and ceiling
    wallLeft = Wall(Vector2(game.camera.visibleWorldRect.topLeft.dx-1, game.camera.visibleWorldRect.topLeft.dy), 1.0, gameHeight);
    wallRight = Wall(Vector2(game.camera.visibleWorldRect.topRight.dx+1, game.camera.visibleWorldRect.topRight.dy), 1.0, gameHeight);

    hoop = Hoop(spawnRight, hoopLowerImg, hoopUpperImg, backboardImg);

    //pause button 
    pauseButton = ButtonComponent(
      position:game.worldToScreen(Vector2(game.camera.visibleWorldRect.topLeft.dx, game.camera.visibleWorldRect.topLeft.dy)),
      button: PositionComponent(
        size: Vector2(50,50),
      ),
      onPressed: () async { 
        hoop.fadeOutAllComponentsTo(transparency: 0.5, duration: 0.75);
        ball.fadeOutAllComponentsTo(transparency: 0.5, duration: 0.75);
        await game.fader.add(OpacityEffect.to(0.5, EffectController(duration:.75), onComplete: () {
          pauseOverlay = PauseOverlay(this); 
          add(pauseOverlay);
        },));
      },
    );

    //background
    bg = ParallaxBackground(); 

    await addAll([pauseButton, bg]); //add components to world and game
    await game.world.addAll([ball, wallLeft, wallRight, hoop,]);

    //launch method to reset scene after user scores and after user dies !
    scoredOpsTimer = Timer(0.5, onTick: () => spawnNewScene());
    gameoverOpsTimer = Timer(0.5, onTick: () => spawnGameoverScene());

    //load up wallbump animations 
    wallBumpAniSpritesheet = SpriteSheet(
      image: wallBumpAniImg.image,
      srcSize: Vector2(76,125),
    );

    wallParticlePaints = _wallPaintsCreate();
  }

  //method to generate all the paints that will be used for our wall particle
  List<Paint> _wallPaintsCreate() {
    //paint list for our particle when ball hits wall
    //dst is paint, src is img
    Paint whiteBlend = Paint()
        ..colorFilter = const ColorFilter.mode(
          Color.fromARGB(200, 224, 224, 224), // Change this to the desired color
          BlendMode.modulate,
    );

    Paint grayBlend = Paint()
        ..colorFilter = const ColorFilter.mode(
          Color.fromARGB(200, 72, 223, 237), // Change this to the desired color
          BlendMode.modulate,
    );

    Paint blueBlend = Paint()
        ..colorFilter = const ColorFilter.mode(
          Color.fromARGB(200, 119, 255, 126), // Change this to the desired color
          BlendMode.modulate,
    );

    return [whiteBlend, grayBlend, blueBlend];
  }

  //CENTRAL METHOD TO LOAD IMAGES
  //THIS WORKS BY DECLARING VARS AT START OF GAMEPLAY CLASS
  //THEN LOADING THEM HERE AND PASSING THEM TO THE APPROPRIAT OBJECTS
  //WE NEED THIS SO THINGS GET INITIALIZED PROPERLY
  Future<void> _loadAllImages() async {
    ballImg = await game.loadSprite('basketball.png');
    hoopUpperImg = await game.loadSprite('hoopUpper.png');
    hoopLowerImg = await game.loadSprite('hoopLower.png');
    backboardImg = await game.loadSprite('backboard.png');
    wallBumpAniImg = await game.loadSprite('wallBumpAni.png');
  }
}   