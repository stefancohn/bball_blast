import 'package:bball_blast/BBallBlast.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';

class PlayButton extends ButtonComponent with HasGameRef<BBallBlast> {
  late SpriteComponent playButton;

  PlayButton({required super.position, required super.size});
  
  @override
  Future<void> onLoad() async {
    super.anchor = Anchor.center;

    playButton = SpriteComponent(
      sprite: await game.loadSprite('playButtonWhite.png'),
      anchor: Anchor.topLeft,
      size: size
    );
    button = playButton;

    onPressed = () {
      game.loadGameScene();
      scale = Vector2.all(1.05);
    };

    onReleased = () {
      scale = Vector2.all(.95);
    };

    super.onLoad();
  }
}