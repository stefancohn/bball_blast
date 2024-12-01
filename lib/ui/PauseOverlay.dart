import 'dart:async';
import 'dart:ui';

import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/scenes/Gameplay.dart';
import 'package:bball_blast/ui/HomeButton.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart' hide Gradient;

class PauseOverlay extends Component with HasGameRef<BBallBlast> {
  Gameplay gamep;
  Sprite resumeImg; 

  late ButtonComponent resumeButton; 
  late HomeButton homeButton;
  late SpriteComponent pausedText;
  RectangleComponent? bgOverlay;

  PauseOverlay(this.gamep, this.resumeImg);

  @override
  FutureOr<void> onLoad() async {
    //make pause button dissapear
    gamep.pauseButton.button!.add(OpacityEffect.fadeOut(EffectController(duration: 0)));
    
    Vector2 resumeButtonSize = Vector2(25,25);
    Vector2 resumeButtonPos = (Vector2(0, 0));

    //define resume button and add it 
    resumeButton = ButtonComponent(
      position: resumeButtonPos,
      anchor: Anchor.center,
      size: resumeButtonSize,
      priority: 5,
      button: SpriteComponent(
        sprite: resumeImg,
        size: resumeButtonSize,
      ),
      onReleased: () async {
        await pressedOps();
      },
      onCancelled: () async {
        await pressedOps();
      },
      onPressed: () {
        resumeButton.size*1.05;
      }
    );

    //home button init
    homeButton = HomeButton(position: Vector2(0, 30), size: Vector2(20,20), pauseOverlay: this)..priority=4;

    //gray transparent mask for effect
    bgOverlay = RectangleComponent(priority: -1, anchor: Anchor.center, position: Vector2(0,0), size: game.size, paint: Paint() ..color = const Color.fromARGB(130, 0, 0, 0))..priority = 4;  

    //PAUSED TEXT
    Sprite pausedImg = await game.loadSprite("paused.png");
    pausedText = SpriteComponent(anchor: Anchor.center, position: Vector2(0,-30), size: Vector2(40,17.5), priority: 4, sprite: pausedImg);

    await game.world.addAll([resumeButton, bgOverlay!, homeButton, pausedText]);

    //we set timescale to 0 to simulate a pause 
    game.timeScale = 0;
  }

  Future<void> pressedOps() async {
    //remove components 
    removeFromParent();
    homeButton.removeFromParent();
    resumeButton.removeFromParent();
    bgOverlay!.removeFromParent();
    pausedText.removeFromParent();

    //UNFADE WORLD COMPONENTS AND FADEOUT FADE OVERLAY :O 
    gamep.pauseButton.button!.add(OpacityEffect.fadeIn(EffectController(duration: 0.75)));
    gamep.hoop.unfade(duration: .75);
    gamep.ball.unfade(duration: .75);

    game.timeScale = 1;
    gamep.pauseActive = false; 
  }
}