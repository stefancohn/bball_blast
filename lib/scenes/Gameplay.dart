import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/Background.dart';
import 'package:bball_blast/entities/Hoop.dart';
import 'package:bball_blast/entities/Wall.dart';
import 'package:bball_blast/entities/ball.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:bball_blast/config.dart';
import 'package:flame/input.dart';

class Gameplay extends Component with HasGameRef<BBallBlast>{
  //vars we need to be visible thoughout entire file------------------------
  late Ball ball; 
  late Hoop hoop;
  late Sprite ballImg;
  late Sprite hoopImg;
  double linearImpulseStrengthMult = 10;
  late Vector2 impulse;
  late List<Vector2> points;
  Random rand = Random();

  //vars for pause functionality 
  late ButtonComponent pauseButton;

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
    ball = Ball(game, startPos, 3, ballImg);

    //add leftWall and rightWall, and ceiling
    Wall wallLeft = Wall(Vector2(game.camera.visibleWorldRect.topLeft.dx-1, game.camera.visibleWorldRect.topLeft.dy), 1.0, gameHeight);
    Wall wallRight = Wall(Vector2(game.camera.visibleWorldRect.topRight.dx+1, game.camera.visibleWorldRect.topRight.dy), 1.0, gameHeight);
    Wall ceiling = Wall(Vector2(game.camera.visibleWorldRect.topLeft.dx-1, game.camera.visibleWorldRect.topRight.dy-1), gameWidth, 1.0);

    //create hoopimg, hoop, and add it
    hoopImg = await game.loadSprite('hoop.png');
    hoop = Hoop(spawnRight, hoopImg);

    //pause button 
    pauseButton = ButtonComponent(
      position:game.worldToScreen(Vector2(game.camera.visibleWorldRect.topLeft.dx, game.camera.visibleWorldRect.topLeft.dy)),
      button: PositionComponent(
        size: Vector2(50,50),
      ),
      onPressed: ()=>game.loadGameScene(),
    );

    //must add to game because children renders have prio over parent renders for sum reason
    await game.addAll([Background(), pauseButton]);
    //add components to world and game
    await game.world.addAll([ball, wallLeft, wallRight, ceiling, hoop]);

    //launch method to reset scene after score
    scoredOpsTimer = Timer(0.5, onTick: () => spawnNewScene());
    //launch method to go to death scene once user dies
    gameoverOpsTimer = Timer(0.5, onTick: () => spawnGameoverScene());

    //print("TOP LEFT: ${camera.visibleWorldRect.topLeft}");
    //print("BOTTOM LEFT: ${camera.visibleWorldRect.bottomRight}");

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

    //remove ball and its children 
    ball.collider.removeFromParent();
    ball.removeFromParent();

    //remove hoop and children
    hoop.rightHb.removeFromParent();
    hoop.leftHb.removeFromParent();
    hoop.hoopCollDetect.removeFromParent();
    hoop.removeFromParent();
    
    //Create and add new ball, hoop
    startPos = _randomBallPos();
    ball = Ball(game, startPos, 3, ballImg);
    await game.world.add(ball);
    hoop = Hoop(spawnRight, hoopImg);
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
    double randomY = (rand.nextDouble() * 65) - 25;
    if (spawnRight) {
      double randomX = -10 + rand.nextDouble() * -15;
      return Vector2(randomX,randomY);
    } else {
      double randomX = (rand.nextDouble() * 15) + 10;
      return Vector2(randomX,randomY);
    }
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
      //initialVelocity = Ball.checkVelMax(initialVelocity);

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
    //if ball gets scored start scored operations timer 
    if (ballScored) {
      scoredOpsTimer.update(dt);
    }
    //check if ball has missed AKA gone beyond the bottom of the world 
    if (game.world.children.contains(ball) && ball.getSuperPosition().y > game.camera.visibleWorldRect.bottom + 5) {
      gameoverOpsTimer.update(dt);
    }
  }
}   