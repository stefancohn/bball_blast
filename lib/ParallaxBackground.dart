import 'dart:async';

import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/ParallaxBackgroundConfig.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';

class ParallaxBackground extends Component with HasGameRef<BBallBlast>{
  late ParallaxComponent background;

  late ParallaxBackgroundConfig config; 
  ParallaxBackground() : super(
    priority: -1);
  @override
  FutureOr<void> onLoad() async {
    super.onLoad();

    //load all parallax images into images
    /*
    var images = [];
    for (int i=0; i<config.filepaths.length; i++) {
      images.add(game.loadParallaxImage(config.filepaths[i]));
    }*/

    background = await game.loadParallaxComponent(
      [ParallaxImageData('skyBackground/sky.png'), 
      ParallaxImageData('skyBackground/clouds.png')],
      baseVelocity: Vector2(1,0),
      velocityMultiplierDelta: Vector2(3, -2),
      size: Vector2(4000, 1280),
      fill: LayerFill.height,
    );
    background.parallax?.layers[0].velocityMultiplier = Vector2.all(0);

    game.camera.backdrop.add(background);
    //game.add(background);
  }
}