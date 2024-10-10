// ignore: file_names
import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/entities/Ball.dart';
import 'package:bball_blast/entities/Hoop.dart';
import 'package:flame/components.dart';

class Coin extends SpriteComponent with HasGameRef<BBallBlast> {
  Vector2 defSize = Vector2(6, 6);

  Vector2 startPos = Vector2(3, 5);

  //objects we need from gp 
  Ball ball; 
  Hoop hoop;

  //set sprite
  Coin({required Sprite sprite, required this.ball, required this.hoop}) : super (
    sprite: sprite
  );
  
  @override
  Future<void> onLoad() async{
    //set properties of sprite component here
    size = defSize;
    anchor = Anchor.center;
    position = startPos;
  }
}