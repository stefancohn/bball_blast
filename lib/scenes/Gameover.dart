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

 late Vector2 replaySpriteSize = Vector2(game.camera.viewport.size.x/3, game.camera.viewport.size.x/3);


 Gameover() : super(
 );

 @override
 Future<void> onLoad() async {
  replayImage = await game.loadSprite('replayButton.png');


  /*Paint gradientBlend = Paint()
    ..colorFilter = const ColorFilter.mode(
      Color.fromARGB(255, 8, 168, 255), // Change this to the desired color
      BlendMode.modulate,
    );*/

  //replay button spirte
  replaySprite = SpriteComponent(
    sprite: replayImage, 
    size: replaySpriteSize,
    position: game.worldToScreen(Vector2(0, 28)),
    anchor: Anchor.center
  );

  GradientBackground gradientBg = GradientBackground(
    colors: [const Color.fromARGB(255, 255, 0, 0), const Color.fromARGB(255, 255, 128, 0),const Color.fromARGB(255, 251, 255, 21)],
    size: replaySpriteSize,
    position: replaySprite!.position,
    anchor: Anchor.center
  );

  //text
   gameOverText= TextBoxComponent(
     text: "Game Over",
     textRenderer: textPaint,
     position: Vector2(400,200),
   );

    //restart
   restartButton = ButtonComponent(
     position: replaySprite!.position,
     button: PositionComponent(
       size: replaySprite!.size,
     ),
     onPressed: ()=>game.loadGameScene(),
     anchor: Anchor.center
   );

    //add to game
   await game.add(gameOverText);
   await game.add(restartButton);
   await game.add(replaySprite!);
   await game.add(gradientBg);
 }

 @override
  void update(double dt) {
    super.update(dt);
  }
}
