import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/Background/GradientBackground.dart';
import 'package:bball_blast/Background/ParallaxBackground.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart' hide Gradient;

class MainMenu extends Component with HasGameRef<BBallBlast>{ 
  LogoComponent? logoComponent;
  RoundedButton? button1; 
  ButtonComponent? customizeButton;
  MainMenu() : super(priority: 0);

  @override
  Future<void> onLoad() async {
    Sprite customizeButtonImg = await game.loadSprite("customizeButton.png");

    logoComponent = LogoComponent();
    await add(logoComponent!);

    button1 = RoundedButton(
      action: () { 
        game.loadGameScene();
      });
    await add(button1!);

    //aspecs for customize button
    customizeButton = ButtonComponent(
      onPressed: () => game.loadCustomizerScene(),
      position: Vector2(button1!.position.x, button1!.position.y + button1!.size.y + game.camera.viewport.size.y/16),
      anchor: Anchor.center,
      button: SpriteComponent(sprite: customizeButtonImg, size: button1!.playButton.size/1.2)
    );
    await add(customizeButton!);

    addParalaxBg();
  }

  //helper to make parallax bg the bg with a gray overlay
  void addParalaxBg() async{
    ParallaxBackground parallax = ParallaxBackground();
    await add(parallax);
    RectangleComponent rect = RectangleComponent(priority: -1, anchor: Anchor.center, position: game.worldToScreen(Vector2(0,0)), size: game.camera.viewport.size, paint: Paint() ..color = Color.fromARGB(107, 255, 255, 255));
    await game.add(rect);
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
    super.position = Vector2(game.camera.viewport.position.x + game.camera.viewport.size.x/2, game.camera.viewport.position.y + (game.camera.viewport.size.y - game.camera.viewport.size.y/3.2));

    List<Color> gradientColors = [const Color.fromARGB(255, 255, 0, 0), const Color.fromARGB(255, 255, 128, 0),const Color.fromARGB(255, 251, 255, 21)];
    
    playButton = SpriteComponent(
      sprite: await game.loadSprite('playButtonWhite.png'),
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