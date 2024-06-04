import 'dart:async';
import 'dart:ui';
import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/Background/ParallaxBackgroundConfig.dart';
import 'package:flame/components.dart';
import 'package:flame/parallax.dart';

class ParallaxBackground extends CircleComponent with HasGameRef<BBallBlast>{
  late ParallaxComponent background;

  ParallaxBackgroundConfig config; 
  ParallaxBackground(this.config) : super(
    priority: -2,
    radius: 100,
    paint: Paint()..color = Color.fromARGB(200, 130, 118, 84),

  );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    position = game.camera.viewport.position;
    //create layers
    final layers = config.imageLayers.entries.map(
    (e) => game.loadParallaxLayer(
      ParallaxImageData(e.key),
      velocityMultiplier: e.value,
      fill: LayerFill.height)
    );

    //make component
    background = ParallaxComponent(
      priority: -1,
      parallax: Parallax(
        await Future.wait(layers),
        baseVelocity: config.baseVelocity,
      )
    );

    //game.camera.backdrop.add(background);
    //game.add(background);
    add(background);
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