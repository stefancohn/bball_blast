import 'dart:async';
import 'dart:math';
import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/Background.dart';
import 'package:bball_blast/entities/Hoop.dart';
import 'package:bball_blast/entities/Wall.dart';
import 'package:bball_blast/entities/ball.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:bball_blast/config.dart';

class Gameplay extends Component with HasGameRef<BBallBlast>, DragCallbacks {
  //vars we need to be visible thoughout entire file------------------------
  late Ball ball; 
  late Hoop hoop;
  late Sprite ballImg;
  late Sprite hoopImg;
  double linearImpulseStrengthMult = 10;
  late Vector2 impulse;
  late List<Vector2> points;
  Random rand = Random();

  //positional vars
  late Vector2 startPos;

  //Vars for determining how ball should be thrown
  late Offset startOfDrag;
  late Offset currentDragPos;
  late Offset dragBehindBall = Offset.zero;
  bool isDragging = false;
  bool isShot = false;

  //ball score and spawn vars
  bool ballScored = false;
  late Timer scoredOpsTimer;
  bool spawnRight = true;
  int score = 0;



  //----------ONLOAD------------------
  @override
  FutureOr<void> onLoad() async {
    //set startPos of ball
    startPos = _randomBallPos();

    //make ballSprite and ball
    ballImg = await game.loadSprite('ball.png');
    //_randomBallPos();
    ball = Ball(game, startPos, 3, ballImg);

    //add leftWall and rightWall, and ceiling
    Wall wallLeft = Wall(Vector2(game.camera.visibleWorldRect.topLeft.dx-1, game.camera.visibleWorldRect.topLeft.dy), 1.0, gameHeight);
    Wall wallRight = Wall(Vector2(game.camera.visibleWorldRect.topRight.dx+1, game.camera.visibleWorldRect.topRight.dy), 1.0, gameHeight);
    Wall ceiling = Wall(Vector2(game.camera.visibleWorldRect.topLeft.dx-1, game.camera.visibleWorldRect.topRight.dy-1), gameWidth, 1.0);

    //create hoopimg, hoop, and add it
    hoopImg = await game.loadSprite('hoop.png');
    hoop = Hoop(game, spawnRight, hoopImg);

    //add components to game  
    await game.world.addAll([Background(), ball, wallLeft, wallRight, ceiling, hoop]);

    //launch method to spawn new scene
    scoredOpsTimer = Timer(0.5, onTick: () => spawnNewScene());

    //print("TOP LEFT: ${camera.visibleWorldRect.topLeft}");
    //print("BOTTOM LEFT: ${camera.visibleWorldRect.bottomRight}");

    debugMode=true;
    super.onLoad();
  }



  //------------OTHER METHODS-----------
  //reset our scene
  void spawnNewScene() async {
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
    hoop = Hoop(game, spawnRight, hoopImg);
    await game.world.add(hoop);
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
}   