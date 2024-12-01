import 'package:bball_blast/BBallBlast.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';

class CustomizeButton extends ButtonComponent with HasGameRef<BBallBlast> {
  late SpriteComponent playButton;

  CustomizeButton({required super.position, required super.size});
  
  @override
  Future<void> onLoad() async {
    super.anchor = Anchor.center;

    playButton = SpriteComponent(
      sprite: await game.loadSprite('customizeButton.png'),
      anchor: Anchor.topLeft,
      size: size
    );
    button = playButton;

    onPressed = () {
      scale = Vector2.all(1.05);
    };

    onReleased = () {
      game.loadCustomizerScene();
      scale = Vector2.all(.95);
    };

    onCancelled = () {
      game.loadCustomizerScene();
      scale=Vector2.all(.95);
    };

    super.onLoad();
  }
}