import 'dart:async';

import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/scenes/Gameplay.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/input.dart';

class PauseOverlay extends Component with HasGameRef<BBallBlast> {
  Gameplay gamep;
  late ButtonComponent resumeButton; 

  PauseOverlay(this.gamep);

  @override
  FutureOr<void> onLoad() async {
    
    //define resume button and add it 
    resumeButton = ButtonComponent(
      position: Vector2(400, 400),
      button: PositionComponent(
        size: Vector2(70,70),
      ),
      onPressed: () {
        gamep.removePauseOverlay();
        game.fader.add(OpacityEffect.fadeOut(EffectController(duration:.75)));
      },
    );
    await add(resumeButton);

    //we set timescale to 0 to simulate a pause 
    game.timeScale = 0;
  }
}