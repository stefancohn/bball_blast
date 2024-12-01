import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/scenes/PauseOverlay.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';

class HomeButton extends ButtonComponent with HasGameRef<BBallBlast> {
  late SpriteComponent playButton;
  PauseOverlay? pauseOverlay;

  HomeButton({required super.position, required super.size, this.pauseOverlay});
  
  @override
  Future<void> onLoad() async {
    super.anchor = Anchor.center;

    playButton = SpriteComponent(
      sprite: await game.loadSprite('homeButton.png'),
      anchor: Anchor.topLeft,
      size: size
    );
    button = playButton;

    onPressed = () {
      scale = Vector2.all(1.05);
    };

    onReleased = () {
      game.loadMainMenuScene();
      BBallBlast.gameplay;
      scale = Vector2.all(.95);

      if (pauseOverlay!=null) {
        pauseOverlay!.pressedOps();
      }
    };

    onCancelled = () {
      game.loadMainMenuScene();
      scale=Vector2.all(.95);

      if (pauseOverlay!=null) {
        pauseOverlay!.pressedOps();
      }
    };

    super.onLoad();
  }
}