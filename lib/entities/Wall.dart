import 'package:bball_blast/BBallBlast.dart';
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

class Wall extends BodyComponent with HasGameRef<Forge2DGame>{
  
  Wall(Vector2 position, double width, double height) : super (
    renderBody: false,
    bodyDef: BodyDef() 
      ..position = position,
    fixtureDefs: [
          FixtureDef(
            PolygonShape()..setAsBoxXY(width, height),
            friction: 0.3,
            restitution: 0.5
          )
      ]
  );


}