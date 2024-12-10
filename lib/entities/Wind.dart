import 'dart:async';
import 'dart:math';

import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/entities/Ball.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';

//will be added to world
class Wind extends Component with HasGameRef<BBallBlast> {
  Ball ball;
  SpriteComponent? windSprite;
  List<SpriteComponent> winds = List.empty();
  Random rand = Random();
  
  Wind(this.ball);

  @override 
  FutureOr<void> onLoad() async {

    await super.onLoad();

    await _initWinds();

    windSprite = SpriteComponent(
      sprite: await game.loadSprite("wind.png"),
      size: Vector2(3,1),
      position: Vector2(-40,0)
    );

    await add(windSprite!);
  }

    
  @override
  void update(double dt) {
    ball.body.applyLinearImpulse(Vector2(2,0));

    if (windSprite != null){
      //effects for wind as it goes
      _dynamicGrowAndMove(windSprite!);
      _sinWaveMove(dt, windSprite!);
    }

    super.update(dt);
  }


  //initialized winds list
  Future<void> _initWinds() async {
    final windImg = await Flame.images.load("wind.png");

    double worldFifth = game.size.y/5; 
    Vector2 windSpriteSize = Vector2(3,1);

    //get randomX between 0 and -10
    double randomX = rand.nextDouble() * -10;
    double randomY = rand.nextDouble() * worldFifth*2;

    winds.add(SpriteComponent(sprite: Sprite(windImg), position: Vector2(randomX, randomY), size: windSpriteSize));
  }


  bool grew = false;
  //dynamic effects of wind
  void _dynamicGrowAndMove(SpriteComponent windSprite) {

    //make wind go across screen 
    windSprite.position = Vector2(windSprite.position.x+0.3, windSprite.position.y);

    //make wind grow to a certain point
    if (grew == false) {
      windSprite.size = Vector2(windSprite.size.x+.15, windSprite.size.y+.02);
      if (windSprite.size.x > 20) {
        grew = true;
      }
    } 

    //shrink once point reached
    else {
      if (windSprite.size.x > 0) {
        windSprite.size = Vector2(windSprite.size.x-.15, windSprite.size.y-.02);
      }
    }
  }


  double elapsedTime = 0.0;
  double get amplitude => 0.4;
  double frequency = 2;

  //sin wave function :D 
  void _sinWaveMove(double dt, SpriteComponent windSprite){
    elapsedTime += dt/2;

    windSprite.position.y += (amplitude * sin(elapsedTime * pi * frequency));
  }
}