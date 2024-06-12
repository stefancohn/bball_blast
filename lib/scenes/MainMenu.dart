import 'dart:async';
import 'dart:ui';

import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/Background/GradientBackground.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart' hide Gradient;

class MainMenu extends Component with HasGameRef<BBallBlast>{ 
  MainMenu() : super(priority: 0);

  @override
  Future<void> onLoad() async {
    LogoComponent logoComponent = LogoComponent();
    await add(logoComponent);

    RoundedButton button1 = RoundedButton(
      action: () { 
        logoComponent.logoGradientBackground.fadeOut();
        logoComponent.logoComponent!.add(OpacityEffect.fadeOut(EffectController(duration: 1.5), onComplete: ()=> game.loadGameScene()));},
    );
    await add(button1);
  }

}

class RoundedButton extends PositionComponent with TapCallbacks, HasGameRef<BBallBlast> {
  final void Function() action;
  late SpriteComponent playButton;
  late  GradientBackground gradientBackground;

  RoundedButton({
    required this.action,
  });
  
  @override
  Future<FutureOr<void>> onLoad() async {
    super.anchor = Anchor.center;
    super.size = Vector2(200,200);
    super.position = Vector2(game.camera.viewport.position.x + game.camera.viewport.size.x/2, 550);

    List<Color> gradientColors = [const Color.fromARGB(255, 255, 0, 0), const Color.fromARGB(255, 255, 128, 0),const Color.fromARGB(255, 251, 255, 21)];
    
    playButton = SpriteComponent(
      sprite: await game.loadSprite('playButton.png'),
      anchor: Anchor.topLeft,
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

  Vector2 logoSize = Vector2(310,350);
  late Vector2 logoPos = Vector2(game.camera.viewport.position.x + game.camera.viewport.size.x/2 - 3,230);
  List<Color> gradientColors = [const Color.fromARGB(255, 255, 0, 0), const Color.fromARGB(255, 255, 128, 0),const Color.fromARGB(255, 251, 255, 21)];

  //constructor
  LogoComponent({super.priority = 0});

  @override
  Future<void> onLoad() async {
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
}