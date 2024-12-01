import 'dart:async';
import 'dart:ui';

import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/scenes/Gameplay.dart';
import 'package:bball_blast/entities/HomeButton.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/input.dart';

class PauseOverlay extends Component with HasGameRef<BBallBlast> {
  Gameplay gamep;
  Sprite resumeImg; 

  late ButtonComponent resumeButton; 
  late HomeButton homeButton;
  RectangleComponent? bgOverlay;

  PauseOverlay(this.gamep, this.resumeImg);

  @override
  FutureOr<void> onLoad() async {
    //make pause button dissapear
    gamep.pauseButton.button!.add(OpacityEffect.fadeOut(EffectController(duration: 0)));
    
    Vector2 resumeButtonSize = Vector2(25,25);
    Vector2 resumeButtonPos = (Vector2(0, 30));
    //define resume button and add it 
    resumeButton = ButtonComponent(
      position: resumeButtonPos,
      anchor: Anchor.center,
      size: resumeButtonSize,
      priority: 5,
      button: SpriteComponent(
        sprite: resumeImg,
        size: resumeButtonSize,
      ),
      onReleased: () {
        pressedOps();
      },
      onCancelled: () {
        pressedOps();
      },
      onPressed: () {
        resumeButton.size*1.05;
      }
    );

    homeButton = HomeButton(position: Vector2(0, 0), size: Vector2(20,20), pauseOverlay: this);
    homeButton.priority=4;

    bgOverlay = RectangleComponent(priority: -1, anchor: Anchor.center, position: Vector2(0,0), size: game.size, paint: Paint() ..color = const Color.fromARGB(130, 0, 0, 0));
    bgOverlay!.priority = 4;

    game.world.addAll([resumeButton, bgOverlay!, homeButton]);

    //we set timescale to 0 to simulate a pause 
    game.timeScale = 0;
  }

  void pressedOps() {
    //remove components 
    removeFromParent();
    homeButton.removeFromParent();
    resumeButton.removeFromParent();
    bgOverlay!.removeFromParent();

    //reset time scale and bool
    game.timeScale = 1;
    gamep.pauseActive = false; 

    //UNFADE WORLD COMPONENTS AND FADEOUT FADE OVERLAY :O 
    gamep.pauseButton.button!.add(OpacityEffect.fadeIn(EffectController(duration: 0.75)));
    gamep.hoop.unfade(duration: .75);
    gamep.ball.unfade(duration: .75);
  }
}