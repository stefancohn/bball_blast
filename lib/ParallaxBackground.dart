import 'dart:async';

import 'package:bball_blast/BBallBlast.dart';
import 'package:flame/components.dart';
import 'package:flame/parallax.dart';

class ParallaxBackground extends PositionComponent with HasGameRef<BBallBlast>{
  late ParallaxComponent background;

  ParallaxBackground() : super(
    priority: -1);
  @override
  FutureOr<void> onLoad() async {
    super.onLoad();
    
    super.size = game.camera.viewport.size;
    super.position = game.worldToScreen(Vector2(game.camera.visibleWorldRect.topLeft.dx, game.camera.visibleWorldRect.topLeft.dy));

    background = await game.loadParallaxComponent(
      [ParallaxImageData('skyBackground/sky.png'),
      ParallaxImageData('skyBackground/clouds.png')],
      baseVelocity: Vector2(1,0),
      velocityMultiplierDelta: Vector2(3, -2),
      size: game.camera.viewport.size,
    );

    background.parallax?.layers[0].velocityMultiplier = Vector2.all(0);

    add(background);
  }
}