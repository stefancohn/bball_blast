import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/ParallaxBackground.dart';
import 'package:bball_blast/entities/Hoop.dart';
import 'package:bball_blast/entities/Wall.dart';
import 'package:bball_blast/entities/ball.dart';
import 'package:bball_blast/scenes/PauseOverlay.dart';
import 'package:flame/components.dart';
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
  late Offset startOfDrag;
  late Offset currentDragPos;
  late Offset dragBehindBall = Offset.zero;
  bool isDragging = false;
  bool isShot = false;

  //ball score and spawn/death vars
  bool ballScored = false;
  late Timer scoredOpsTimer;
  late Timer gameoverOpsTimer;
  bool spawnRight = true;
  int score = 0;
  bool died = false; 



  //----------ONLOAD------------------
  @override
  FutureOr<void> onLoad() async {
    //set startPos of ball
    startPos = _randomBallPos();

    //make ballSprite and ball
    ballImg = await game.loadSprite('ball.png');
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


    //must add to game because children renders have prio over parent renders for sum reason
    //await game.add(Background());
    ParallaxBackground bg = ParallaxBackground();
    await game.add(bg);
    await addAll([pauseButton]); //add components to world and game
    await game.world.addAll([ball, wallLeft, wallRight, hoop]);

    //Ball.velocityRatio = 1/ball.body.mass;
    //ball.body.setType(BodyType.static);

    //launch method to reset scene after user scores and after user dies !
    scoredOpsTimer = Timer(0.5, onTick: () => spawnNewScene());
    gameoverOpsTimer = Timer(0.5, onTick: () => spawnGameoverScene());

    debugMode=true;
    super.onLoad();
  }



  //------------OTHER METHODS-----------
  //reset our scene
  spawnNewScene() async {
    //reset vars and timer
    isShot = false;
    ballScored = false;
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
  }

  //spawn the gameover scene when ded
  void spawnGameoverScene() async {
    gameoverOpsTimer.stop();
    gameoverOpsTimer.start();

    game.loadGameoverScene();
  }

  //random ball spawn
  Vector2 _randomBallPos() {
    double randomY = (rand.nextDouble() * 62) - 22;
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

  //----------------------DRAWING----------------------------
  ///////////
  ///////////
  @override
  void render(Canvas canvas){
    super.render(canvas);

    //render the projected trajectory
    if (isDragging) {
      //we multiply the input by that number as it's the ratio that converts pixel to velocity
      Vector2 initialVelocity = Vector2(dragBehindBall.dx, dragBehindBall.dy) * linearImpulseStrengthMult * Ball.velocityRatio;
      initialVelocity = Ball.checkVelMax(initialVelocity);

      //get points to draw projected trajectory
      points = Ball.trajectoryPoints(initialVelocity, startPos, Ball.steps, (1/60)); //60 fps so our dt is 1/60

      Paint paint = Paint()
        ..color = const Color.fromRGBO(244, 67, 54, 1)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < points.length - 1; i++) {
        //conversion to put accurately
        Vector2 point1 = game.worldToScreen(points[i]);
        Vector2 point2 = game.worldToScreen(points[i+1]);
        canvas.drawLine(
          Offset(point1.x, point1.y),
          Offset(point2.x, point2.y),
          paint,
        );
      }
    }

    //score text
    textPaint.render(canvas, "$score", game.worldToScreen(Vector2(0, game.camera.visibleWorldRect.top)));
  }




  //------UPDATE LOOP---------------
  @override
  void update(double dt) {
    super.update(dt);
    //print("VEL: ${ball.body.linearVelocity}");

    //if ball gets scored start scored operations timer 
    //ballScored var gets updated in Hoop class because that class contains hit box logic 
    if (ballScored) {
      scoredOpsTimer.update(dt);
    }
    //check if ball has missed AKA gone beyond the bottom of the world 
    if (game.world.children.contains(ball) && ball.getSuperPosition().y > game.camera.visibleWorldRect.bottom + 5 && !ballScored) {
      gameoverOpsTimer.update(dt);
    }
  }
}   