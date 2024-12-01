import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/Background/ParallaxBackground.dart';
import 'package:bball_blast/entities/CustomizeButton.dart';
import 'package:bball_blast/ui/PlayButton.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart' hide Gradient;

class MainMenu extends Component with HasGameRef<BBallBlast>{ 
  LogoComponent? logoComponent;
  ButtonComponent? customizeButton;
  MainMenu() : super(priority: 0);

  @override
  Future<void> onLoad() async {

    logoComponent = LogoComponent();
    await add(logoComponent!);

    PlayButton playButton = PlayButton(size: Vector2(game.camera.viewport.size.x/3, game.camera.viewport.size.y/6), 
      position: game.worldToScreen(Vector2(0, 15)),
    );
    await add(playButton);

    //aspecs for customize button
    customizeButton = CustomizeButton(
      position: game.worldToScreen(Vector2(0, 40)),
      size: playButton.playButton.size/1.2
    );
    await add(customizeButton!);

    addParallaxBg();
  }

  //helper to make parallax bg the bg with a gray overlay
  void addParallaxBg() async{
    ParallaxBackground parallax = ParallaxBackground();
    await add(parallax);
    RectangleComponent rect = RectangleComponent(priority: -1, anchor: Anchor.center, position: game.worldToScreen(Vector2(0,0)), size: game.camera.viewport.size, paint: Paint() ..color = const Color.fromARGB(107, 255, 255, 255));
    await game.add(rect);
  }

}

class LogoComponent extends Component with HasGameRef<BBallBlast>{
  Sprite? logoImg;
  SpriteComponent? logoComponent;

  //Vector2 logoSize = Vector2(310,350);
  late Vector2 logoPos = Vector2(game.camera.viewport.position.x + game.camera.viewport.size.x/2 - 3,game.camera.viewport.position.y + game.camera.viewport.size.y/4.5);
  List<Color> gradientColors = [const Color.fromARGB(255, 255, 0, 0), const Color.fromARGB(255, 255, 128, 0),const Color.fromARGB(255, 251, 255, 21)];

  //constructor
  LogoComponent({super.priority = 0});

  @override
  Future<void> onLoad() async {
    Vector2 logoSize = Vector2(game.camera.viewport.size.x/1.5, game.camera.viewport.size.y/2.5);
    logoImg = await game.loadSprite('ballBoomLogo.png');

    logoComponent = SpriteComponent(
      sprite: logoImg,
      size: logoSize,
      position: logoPos,
      anchor: Anchor.center,
    );

    await add(logoComponent!);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _sinWaveMove(dt);
  }

  //sin wave function :D 
  double elapsedTime = 0.0;
  double get amplitude => game.camera.viewport.size.y * 0.001;
  double frequency = 1.2;

  void _sinWaveMove(double dt){
    elapsedTime += dt/2;

    logoComponent!.position.y += (amplitude * sin(elapsedTime * pi * frequency));
  }
}