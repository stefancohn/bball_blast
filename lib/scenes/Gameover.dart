import 'dart:async';
import 'dart:ui';

import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/Background/GradientBackground.dart';
import 'package:bball_blast/config.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';


class Gameover extends PositionComponent with HasGameRef<BBallBlast>{
 late TextComponent gameOverText;
 late ButtonComponent restartButton;
 
 late Sprite replayImage;
 SpriteComponent? replaySprite;
 
 late GradientBackground gradientBackground;

 Gameover() : super(
 );


 @override
 Future<void> onLoad() async {
  replayImage = await game.loadSprite('playButtonWhite.png');

  List<Color> gradientColors = [const Color.fromARGB(255, 255, 0, 0), const Color.fromARGB(255, 255, 128, 0),const Color.fromARGB(255, 251, 255, 21)];

  gradientBackground = GradientBackground(
      colors: gradientColors,
      size: Vector2.zero(),
      position: Vector2.all(0),
      anchor: Anchor.topLeft,
      fadeOutSpeed: 1.5,
    );

  Paint blueBlend = Paint()
    ..colorFilter = const ColorFilter.mode(
      Color.fromARGB(255, 8, 168, 255), // Change this to the desired color
      BlendMode.modulate,
  );

  replaySprite = SpriteComponent(
    sprite: replayImage, 
    position: (game.camera.viewport.position),
    paint: blueBlend
  );

   gameOverText= TextBoxComponent(
     text: "Game Over",
     textRenderer: textPaint,
     position: Vector2(400,200),
   );


   restartButton = ButtonComponent(
     position: Vector2(300,300),
     button: PositionComponent(
       size: Vector2(100,100),
     ),
     onPressed: ()=>game.loadGameScene(),
   );
  
   add(gameOverText);
   add(restartButton);
   add(replaySprite!);
 }

 @override
  void update(double dt) {
    super.update(dt);
    if (replaySprite != null) {
      replaySprite!.paint = gradientBackground.paint;
    }
  }
}
