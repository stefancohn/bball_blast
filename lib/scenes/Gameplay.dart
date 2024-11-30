import 'dart:async';
import 'dart:math';
import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/Backend.dart';
import 'package:bball_blast/Background/ParallaxBackground.dart';
import 'package:bball_blast/entities/Ball.dart';
import 'package:bball_blast/entities/Coin.dart';
import 'package:bball_blast/entities/CoinAmtDisplay.dart';
import 'package:bball_blast/entities/Hoop.dart';
import 'package:bball_blast/entities/Wall.dart';
import 'package:bball_blast/scenes/PauseOverlay.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:bball_blast/config.dart';
import 'package:flame/input.dart';
import 'package:flame_noise/flame_noise.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:flame/particles.dart';
import 'package:forge2d/src/dynamics/body_type.dart';

class Gameplay extends Component with HasGameRef<BBallBlast>{
  //vars we need to be visible thoughout entire file------------------------
  late Ball ball; 
  late Hoop hoop;
  late Coin coin;
  late CoinAmtDisplay coinDisplay;

  late Sprite ballImg;
  late Sprite hoopLowerImg;
  late Sprite hoopUpperImg;
  late Sprite backboardImg;
  late Sprite resumeImg;
  late Sprite pauseImg;
  late Sprite coinImg;

  late Wall wallLeft;
  late Wall wallRight;

  double linearImpulseStrengthMult = 3;
  double radius = 4;
  late List<Vector2> points;
  Random rand = Random();

  //vars for pause functionality 
  late ButtonComponent pauseButton;
  late PauseOverlay pauseOverlay; 
  bool pauseActive = false;

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

  late ParallaxBackground bg;

  //vars for determining ball stuck
  double stuckTimer = 0;
  double stuckDuration = 2; 

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

    //FOR ALL METHODS INVOLVING BALL 
    if (game.world.children.contains(ball)) {
      //ball intro 
      ballSpawnIntro(dt);

      //check if ball has missed AKA gone beyond the bottom of the world 
      if (ball.getSuperPosition().y > game.camera.visibleWorldRect.bottom + 5 && !ballScored) {
        gameoverOpsTimer.update(dt); //start gameover operations
        ball.collider.removeFromParent();
      }

      checkBallStuck(dt);
    }
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

    //30% chance of coin
    if (rand.nextDouble() < .31) {
      coin = Coin(sprite: coinImg, hoop: hoop, ball: ball);
      await game.world.add(coin);
    }

    //change background
    bg.spawnRectMask();
  }

  //spawn the gameover scene when ded
  void spawnGameoverScene() async {
    gameoverOpsTimer.stop();

    game.loadGameoverScene();
  }

  //random ball spawn
  Vector2 _randomBallPos() {
    double randomY = (rand.nextDouble() * 73) - 28;
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

  //check if the ball is stuck!
  void checkBallStuck(double dt) async {
    //make sure ball has been shot and velocity is very low
    if (ball.body.linearVelocity.length <= 2 && isShot) {
      stuckTimer += dt;

      //once the timer hits the max duration
      if (stuckTimer >= stuckDuration) {
        //reset position
        ball.body.setTransform(startPos, 0);
        ball.body.setType(BodyType.static);

        //reset nevessary vars
        isShot = false;
        ballScored = false;
        readyToBeShot = false;

      }

    } //reset our timer if ball not stuck
    else {
      stuckTimer = 0;
    }
  }

  //make camera shake, add falling orange particles
  Future<void> wallBumpAnimation({required bool isLeft}) async {
    //MAKE SCREEN SHAKE
    game.camera.viewfinder.add(
      MoveEffect.by(
        Vector2(5, 5),
        NoiseEffectController(duration: 0.2, noise: PerlinNoise(frequency: 400)),
      ),
    );


    //PARTICLE
    //vars for particle
    int particleCount = 10;
    double xPosForParticle;
    List<Vector2> accelForParticle = List.filled(10, Vector2.all(0)); 
    for(int i =0; i < particleCount; i++) {accelForParticle[i] = Vector2.random()..scale(100);} //set 10 diff vals

    //Set vars correctly depending on which wall
    if (isLeft) {
      xPosForParticle = wallLeft.body.position.x;
    } else {
      xPosForParticle = wallRight.body.position.x;
      for (int i=0;i<particleCount;i++) {accelForParticle[i].x*=-1;}//change x direction if on right
    }

    //our particle 
    final particle = ParticleSystemComponent(
      particle: Particle.generate(
        count: particleCount,  // Number of particles
        lifespan: 2,  // How long the particles last
        generator: (i) => AcceleratedParticle(
          acceleration: accelForParticle.elementAt(i),
          position: Vector2(xPosForParticle, ball.body.position.y ),  // Where the impact happened
          child: ComputedParticle(
            renderer: (canvas, particle) {
              //so the color slowly fades away
              Paint paint = Paint()..color = Colors.white;
              paint.color = paint.color.withOpacity(1-particle.progress);

              //our circle for particle
              canvas.drawCircle(
                Offset.zero,
                1,
                paint
              );
            }
          ),
        ),
      ),
    );

    game.world.add(particle);
  }

  //initialize all objects add add them to world/game
  Future<void> _intiializeObjects() async {
    await _loadAllImages();

    //make ballSprite and ball
    ball = Ball(game, startPos, radius, ballImg);

    //add leftWall and rightWall, and ceiling
    wallLeft = Wall(Vector2(game.camera.visibleWorldRect.topLeft.dx-1, game.camera.visibleWorldRect.topLeft.dy), 1.0, gameHeight);
    wallRight = Wall(Vector2(game.camera.visibleWorldRect.topRight.dx+1, game.camera.visibleWorldRect.topRight.dy), 1.0, gameHeight);

    hoop = Hoop(spawnRight, hoopLowerImg, hoopUpperImg, backboardImg);

    //pause button 
    pauseButton = _initializePauseButton();

    //coin indicator and necessary vars
    Vector2 coinAmtDisplayPos = game.worldToScreen(game.camera.visibleWorldRect.topRight.toVector2());
    Vector2 coinAmtDisplaySize = Vector2(game.camera.viewport.size.x/4,game.camera.viewport.size.y/14);
    coinAmtDisplayPos.x -= coinAmtDisplaySize.x + 10;
    coinAmtDisplayPos.y += 20;

    coinDisplay = CoinAmtDisplay(coinImg: coinImg, position: coinAmtDisplayPos, size: coinAmtDisplaySize);

    //background
    bg = ParallaxBackground(); 

    //coin 
    coin = Coin(ball: ball, hoop: hoop, sprite: coinImg);

    await addAll([pauseButton, bg, coinDisplay]); //add components to world and game
    await game.world.addAll([ball, wallLeft, wallRight, hoop, coin]);

    //launch method to reset scene after user scores and after user dies !
    scoredOpsTimer = Timer(0.5, onTick: () => spawnNewScene());
    gameoverOpsTimer = Timer(0.5, onTick: () => spawnGameoverScene());
  }


  //---------------------------------------INITIALIZE METHODS BELOW HERE--------------------------------------------


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


  //Codes PauseButton: it's functionality, sprite, positiion, size
  ButtonComponent _initializePauseButton() {
    ButtonComponent pauseButton = ButtonComponent(
      position:game.worldToScreen(Vector2(game.camera.visibleWorldRect.topLeft.dx + 2, game.camera.visibleWorldRect.topLeft.dy + 2)),
      size: Vector2(game.camera.viewport.size.x/8, game.camera.viewport.size.y/12),
      button: SpriteComponent(
        sprite: pauseImg,
        size: Vector2(game.camera.viewport.size.x/8, game.camera.viewport.size.y/12),
      ),
      onPressed: () async { 
        //we need to control when pause can get pressed b/c if not it can be pressed again while game is paused
        //adn break the game
        if (pauseActive == false) {
          //initialize pause overlay, add it, and make pauseActive true
          pauseOverlay = PauseOverlay(this, resumeImg); 
          add(pauseOverlay);
          pauseActive = true;
        }
      },
    );

    return pauseButton;
  }

  //---------------------------------------INITIALIZE METHODS ABOVE HERE--------------------------------------------

  //CENTRAL METHOD TO LOAD IMAGES
  //THIS WORKS BY DECLARING VARS AT START OF GAMEPLAY CLASS
  //THEN LOADING THEM HERE AND PASSING THEM TO THE APPROPRIAT OBJECTS
  //WE NEED THIS SO THINGS GET INITIALIZED PROPERLY
  Future<void> _loadAllImages() async {
    ballImg = await game.loadSprite(ballImgPath);
    hoopUpperImg = await game.loadSprite('hoopUpper.png');
    hoopLowerImg = await game.loadSprite('hoopLower.png');
    backboardImg = await game.loadSprite('backboard.png');
    resumeImg = await game.loadSprite('playButtonTransparent.png');
    pauseImg = await game.loadSprite('pauseButton.png');
    coinImg = await game.loadSprite("coin.png");
  }
}   