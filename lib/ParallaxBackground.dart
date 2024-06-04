import 'dart:async';

import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/ParallaxBackgroundConfig.dart';
import 'package:flame/components.dart';
import 'package:flame/parallax.dart';

class ParallaxBackground extends Component with HasGameRef<BBallBlast>{
  late ParallaxComponent background;

  ParallaxBackgroundConfig config; 
  ParallaxBackground(this.config) : super(priority: -1);
  @override
  FutureOr<void> onLoad() async {
    super.onLoad();

    //create layers
    final layers = config.imageLayers.entries.map(
    (e) => game.loadParallaxLayer(
      ParallaxImageData(e.key),
      velocityMultiplier: e.value,)
    );

    //make component
    background = ParallaxComponent(
      parallax: Parallax(
        await Future.wait(layers),
        baseVelocity: config.baseVelocity,
      )
    );

    game.camera.backdrop.add(background);
    //game.add(background);
  }
}

/*
background = await game.loadParallaxComponent(
  [ParallaxImageData('skyBackground/sky.png'), 
  ParallaxImageData('skyBackground/clouds.png')],
  baseVelocity: Vector2(1,0),
  velocityMultiplierDelta: Vector2(3, -2),
  fill: LayerFill.height,
);
background.parallax?.layers[0].velocityMultiplier = Vector2.all(0);*/