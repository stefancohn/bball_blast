import 'dart:async';

import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/config.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';

class Gameover extends PositionComponent with HasGameRef<BBallBlast>{
  late TextComponent gameOverText;
  late ButtonComponent restartButton; 

  Gameover() : super(
  );

  @override
  FutureOr<void> onLoad() {
    gameOverText= TextBoxComponent(
      text: "Game Over",
      textRenderer: textPaint,
      position: Vector2(400,200),
    );

    restartButton = ButtonComponent(
      position: Vector2(300,300),
      button: PositionComponent(
        size: Vector2(20,20),
      ),
      onPressed: ()=>print('bob'),
    );

    add(gameOverText);
    add(restartButton);
  }
}