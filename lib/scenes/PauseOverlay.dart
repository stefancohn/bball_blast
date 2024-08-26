import 'dart:async';
import 'dart:ui';

import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/Background/GradientBackground.dart';
import 'package:bball_blast/scenes/Gameplay.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/input.dart';

class PauseOverlay extends Component with HasGameRef<BBallBlast> {
  Gameplay gamep;
  Sprite resumeImg; 

  late ButtonComponent resumeButton; 

  CircleComponent? circle;

  List<Color> gradientColors = [const Color.fromARGB(255, 255, 0, 0), const Color.fromARGB(255, 255, 128, 0),const Color.fromARGB(255, 251, 255, 21)];
  GradientBackground? bg;

  PauseOverlay(this.gamep, this.resumeImg);

  @override
  FutureOr<void> onLoad() async {
    bg = GradientBackground(colors: gradientColors, size: Vector2.all(0), position: Vector2.all(0));

    //CIRCLE w/ GRADIENT COLORING
    double circleRadius = game.camera.viewport.size.x/3.5;
    double circlePosX = game.camera.viewport.position.x + game.camera.viewport.size.x/2;
    double circlePosY = game.camera.viewport.position.y + (game.camera.viewport.size.y - game.camera.viewport.size.y/6);
    circle = CircleComponent(
      radius: circleRadius,
      position: Vector2(circlePosX, circlePosY),
      anchor: Anchor.center,
      priority: 1
    );
    
    //define resume button and add it 
    resumeButton = ButtonComponent(
      position: circle!.position,
      anchor: Anchor.center,
      size: Vector2.all(circle!.radius * 2),
      priority: 2,
      button: SpriteComponent(
        sprite: resumeImg,
        size: Vector2.all(circle!.radius * 2),
      ),
      onPressed: () {
        gamep.removePauseOverlay();
        gamep.pauseActive = false; 
        //UNFADE WORLD COMPONENTS AND FADEOUT FADE OVERLAY :O 
        gamep.hoop.unfade(duration: .75);
        gamep.ball.unfade(duration: .75);
        game.fader.add(OpacityEffect.fadeOut(EffectController(duration:.75)));
      },
    );
    await addAll([bg!, resumeButton, circle!]);

    //we set timescale to 0 to simulate a pause 
    game.timeScale = 0;
  }

  @override
  void update(double dt) {
    //get gradienet paint onto circle
    if (bg != null && circle != null) {
      circle!.paint = bg!.paint;
    }
    super.update(dt);
  }
}