import 'dart:async';

import 'package:bball_blast/config.dart';
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';


class Background extends RectangleComponent with HasGameRef<Forge2DGame> {
  //TODO: implement camera.backdrop? 
  Background() 
    : super(
        paint: Paint()..color = const Color(0xfff2e8cf),
        priority: -1,
    );

  @override
  FutureOr<void> onLoad() async {
    super.onLoad();
    super.size = Vector2(gameWidth/2, gameHeight);
    super.position = game.worldToScreen(Vector2(game.camera.visibleWorldRect.topLeft.dx, game.camera.visibleWorldRect.topLeft.dy));
  }
}