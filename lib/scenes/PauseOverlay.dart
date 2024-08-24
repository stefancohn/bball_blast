import 'dart:async';

import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/config.dart';
import 'package:bball_blast/scenes/Gameplay.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/input.dart';

class PauseOverlay extends Component with HasGameRef<BBallBlast> {
  Gameplay gamep;
  late ButtonComponent resumeButton; 

  late CircleComponent circle;

  PauseOverlay(this.gamep);

  @override
  FutureOr<void> onLoad() async {
    //TEST STUFF
    double circleRadius = game.camera.viewport.size.x/3;
    double circlePosX = game.camera.visibleWorldRect.right;
    double circlePosY = game.camera.visibleWorldRect.top - game.camera.visibleWorldRect.bottom/2;
    circle = CircleComponent(
      radius: circleRadius,
      position: Vector2(circlePosX, circlePosY),
      paint: insideWhite,
      anchor: Anchor.center
    );
    
    //define resume button and add it 
    resumeButton = ButtonComponent(
      position: Vector2(400, 400),
      button: PositionComponent(
        size: Vector2(70,70),
      ),
      onPressed: () {
        gamep.removePauseOverlay();
        //UNFADE WORLD COMPONENTS AND FADEOUT FADE OVERLAY :O 
        gamep.hoop.unfade(duration: .75);
        gamep.ball.unfade(duration: .75);
        game.fader.add(OpacityEffect.fadeOut(EffectController(duration:.75)));
      },
    );
    await addAll([resumeButton, circle]);

    //we set timescale to 0 to simulate a pause 
    game.timeScale = 0;
  }
}