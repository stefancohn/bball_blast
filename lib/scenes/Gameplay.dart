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
import 'package:flame_forge2d/flame_forge2d.dart';

class Gameplay extends Component with HasGameRef<BBallBlast>{
  //vars we need to be visible thoughout entire file------------------------
  late Ball ball; 
  late Hoop hoop;

  late Sprite ballImg;
  late Sprite hoopLowerImg;
  late Sprite hoopUpperImg;
  late Wall wallLeft;
  late Wall wallRight;
  //late Wall ceiling;

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

  late ParallaxBackground bg;





  //----------ONLOAD------------------
  @override
  FutureOr<void> onLoad() async {
    priority = 0;

    //set startPos of ball
    startPos = _randomBallPos();

    //make ballSprite and ball
    ballImg = await game.loadSprite('basketball.png');
    ball = Ball(game, startPos, radius, ballImg);

    //add leftWall and rightWall, and ceiling
    wallLeft = Wall(Vector2(game.camera.visibleWorldRect.topLeft.dx-1, game.camera.visibleWorldRect.topLeft.dy), 1.0, gameHeight);
    wallRight = Wall(Vector2(game.camera.visibleWorldRect.topRight.dx+1, game.camera.visibleWorldRect.topRight.dy), 1.0, gameHeight);
    //ceiling = Wall(Vector2(game.camera.visibleWorldRect.topLeft.dx-1, game.camera.visibleWorldRect.topRight.dy-1), gameWidth, 1.0);

    //create hoopimg, hoop, and add it
    hoopUpperImg = await game.loadSprite('hoopUpper.png'); //just to load in beforehand
    hoopLowerImg = await game.loadSprite('hoopLower.png');
    hoop = Hoop(spawnRight, hoopLowerImg, hoopUpperImg);

    //pause button 
    pauseButton = ButtonComponent(
      position:game.worldToScreen(Vector2(game.camera.visibleWorldRect.topLeft.dx, game.camera.visibleWorldRect.topLeft.dy)),
      button: PositionComponent(
        size: Vector2(50,50),
      ),
      onPressed: () { 
        pauseOverlay = PauseOverlay(this); 
        add(pauseOverlay);
      },
    );



    bg = ParallaxBackground();
    await add(bg);
    await addAll([pauseButton]); //add components to world and game
    await game.world.addAll([ball, wallLeft, wallRight, hoop]);

    //launch method to reset scene after user scores and after user dies !
    scoredOpsTimer = Timer(0.5, onTick: () => spawnNewScene());
    gameoverOpsTimer = Timer(0.5, onTick: () => spawnGameoverScene());

    super.onLoad();
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
    hoop = Hoop(spawnRight, hoopLowerImg, hoopUpperImg);
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
    double randomY = (rand.nextDouble() * 77) - 37;
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
            insideWhite
          );
        }
      }
    }

    //score text
    textPaint.render(canvas, "$score", game.worldToScreen(Vector2(0, game.camera.visibleWorldRect.top+5)), anchor: Anchor.center);
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
      hoop.fadeOutAllComponents();
      scoredOpsTimer.update(dt);
    }

    if (game.world.children.contains(ball)) {
      //ball intro 
      ballSpawnIntro(dt);

      //check if ball has missed AKA gone beyond the bottom of the world 
      if (ball.getSuperPosition().y > game.camera.visibleWorldRect.bottom + 5 && !ballScored) {
        gameoverOpsTimer.update(dt); //start gameover operations
      }
    }
  }
}   