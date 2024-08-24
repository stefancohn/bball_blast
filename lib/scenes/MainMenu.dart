import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/Background/GradientBackground.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart' hide Gradient;

class MainMenu extends Component with HasGameRef<BBallBlast>{ 
  LogoComponent? logoComponent;
  RoundedButton? button1; 
  MainMenu() : super(priority: 0);

  @override
  Future<void> onLoad() async {
    logoComponent = LogoComponent();
    await add(logoComponent!);

    button1 = RoundedButton(
      action: () { 
        game.loadGameScene();
      });
    await add(button1!);
  }

}

class RoundedButton extends PositionComponent with TapCallbacks, HasGameRef<BBallBlast> {
  final void Function() action;
  late SpriteComponent playButton;
  late GradientBackground gradientBackground;

  RoundedButton({
    required this.action,
  });
  
  @override
  Future<FutureOr<void>> onLoad() async {
    super.anchor = Anchor.center;
    super.size = Vector2(game.camera.viewport.size.x/3, game.camera.viewport.size.y/6);
    super.position = Vector2(game.camera.viewport.position.x + game.camera.viewport.size.x/2, game.camera.viewport.position.y + (game.camera.viewport.size.y - game.camera.viewport.size.y/6));

    List<Color> gradientColors = [const Color.fromARGB(255, 255, 0, 0), const Color.fromARGB(255, 255, 128, 0),const Color.fromARGB(255, 251, 255, 21)];
    
    playButton = SpriteComponent(
      sprite: await game.loadSprite('playButton.png'),
      anchor: Anchor.topLeft,
      size: Vector2(game.camera.viewport.size.x/3, game.camera.viewport.size.y/6)
    );

    gradientBackground = GradientBackground(
      colors: gradientColors,
      size: playButton.size,
      position: Vector2.all(0),
      anchor: Anchor.topLeft,
      fadeOutSpeed: 1.5,
    );

    await add(gradientBackground);
    await add(playButton);

    super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
  }

  @override
  void onTapDown(TapDownEvent event) {
    scale = Vector2.all(1.05);
  }

  @override
  void onTapUp(TapUpEvent event) {
    scale = Vector2.all(1.0);
    //initialize fade out
    playButton.add(OpacityEffect.fadeOut(EffectController(duration: 1.5)));
    gradientBackground.fadeOut();

    action(); //call action
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    scale = Vector2.all(1.0);
  }
}

class LogoComponent extends Component with HasGameRef<BBallBlast>{
  Sprite? logoImg;
  SpriteComponent? logoComponent;
  late GradientBackground logoGradientBackground;

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

    logoGradientBackground = GradientBackground(colors: gradientColors, size: logoSize, position: logoPos, anchor: Anchor.center, fadeOutSpeed: 1.5);

    //this thing works by having a white image with transparency inside the letters 
    //so that "under" the logoComponent is the gradient background
    await add(logoGradientBackground);
    await add(logoComponent!);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _sinWaveMove(dt);
  }

  //sin wave function :D 
  double elapsedTime = 0.0;
  double amplitude = 1;
  double frequency = 1.5;

  void _sinWaveMove(double dt){
    elapsedTime += dt/2;

    logoComponent!.position.y += (amplitude * sin(elapsedTime * pi * frequency));
    logoGradientBackground.position.y += (amplitude * sin(elapsedTime * pi * frequency));
  }
}