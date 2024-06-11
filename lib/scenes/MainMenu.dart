import 'dart:async';
import 'dart:ui';

import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/config.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart' hide Gradient;

class MainMenu extends Component with HasGameRef<BBallBlast>{ 

  MainMenu() : super(priority: 3);

  @override
  Future<void> onLoad() async {
    LogoComponent logoComponent = LogoComponent();
    add(logoComponent);
    RoundedButton button1 = RoundedButton(
        text: 'Level 1',
        action: () { 
          logoComponent.logoComponent!.add(OpacityEffect.fadeOut(EffectController(duration: 1.0), onComplete: ()=> game.loadGameScene()));},
        color: const Color(0xffadde6c),
        borderColor: const Color.fromARGB(255, 121, 30, 126),
      );
      await add(button1);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(Rect.fromLTRB(game.camera.viewport.position.x, game.camera.viewport.position.y, game.camera.viewport.size.x + game.camera.viewport.position.x, game.camera.viewport.size.y + game.camera.viewport.position.y), insideWhite);
    super.render(canvas);
  }
}

class RoundedButton extends PositionComponent with TapCallbacks {
  RoundedButton({
    required this.text,
    required this.action,
    required Color color,
    required Color borderColor,
    super.anchor = Anchor.center,
  }) : _textDrawable = TextPaint(
          style: const TextStyle(
            fontSize: 20,
            color: Color.fromARGB(255, 29, 147, 237),
            fontWeight: FontWeight.w800,
          ),
        ).toTextPainter(text) {
    super.size = Vector2(500, 500);
    super.position = Vector2(500, 500);
    _textOffset = Offset(
      (size.x - _textDrawable.width) / 2,
      (size.y - _textDrawable.height) / 2,
    );
    _rrect = RRect.fromLTRBR(250, 250, size.x, size.y, Radius.circular(size.y / 2));
    _bgPaint = Paint()..color = color;
    _borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = borderColor;
  }

  final String text;
  final void Function() action;
  final TextPainter _textDrawable;
  late final Offset _textOffset;
  late final RRect _rrect;
  late final Paint _borderPaint;
  late final Paint _bgPaint;

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(_rrect, _bgPaint);
    canvas.drawRRect(_rrect, _borderPaint);
    _textDrawable.paint(canvas, _textOffset);
  }

  @override
  void onTapDown(TapDownEvent event) {
    scale = Vector2.all(1.05);
  }

  @override
  void onTapUp(TapUpEvent event) {
    scale = Vector2.all(1.0);
    action();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    scale = Vector2.all(1.0);
  }
}

class LogoComponent extends Component with HasGameRef<BBallBlast>{
  Sprite? logoImg;
  SpriteComponent? logoComponent;
  RectangleComponent? logoGradientBackground;

  Vector2 logoSize = Vector2(310,350);
  late Vector2 logoPos = Vector2(game.camera.viewport.position.x + game.camera.viewport.size.x/2 - 3,230);

  //for our gradient animation 
  List<double> colorStops = [0, 0.5, 1];
  List<Color> gradientColors = [const Color.fromARGB(255, 255, 0, 0), const Color.fromARGB(255, 255, 128, 0),const Color.fromARGB(255, 251, 255, 21)];

  late var gradientPaint = Paint()
    ..shader = Gradient.linear(
      Offset.zero,
      const Offset(0, 350),
      gradientColors,
      colorStops,
      TileMode.mirror,
  );

  LogoComponent();

  @override
  Future<void> onLoad() async {
    logoImg = await game.loadSprite('ballBoomLogo.png');

    logoComponent = SpriteComponent(
      sprite: logoImg,
      size: logoSize,
      position: logoPos,
      anchor: Anchor.center,
    );

    logoGradientBackground = RectangleComponent(
      paint: gradientPaint,
      size: logoSize,
      position: logoPos,
      anchor: Anchor.center,
    );

    //this thing works by having a white image with transparency inside the letters 
    //so that "under" the logoComponent is the gradient background
    add(logoGradientBackground!);
    add(logoComponent!);
  }

  @override
  void update(double dt) {
    super.update(dt);

    _animateGradient(dt);
  }

  //essentially create our own animation loop :D 
  bool insertNewFlag = false;
  void _animateGradient(double dt) {
    //increase the colorStop
    for (int i =0; i < colorStops.length; i++) {
      colorStops[i] += 0.3*dt; 
    }

    //once a color reaches a color beyond "the end" we 
    //add that same color to the beginning at the list at a 
    //position off the "gradient" and we have a flag so that 
    //this function doesn't repeatedly get called
    var lastColor = gradientColors[gradientColors.length-1];
    var lastStop = colorStops[colorStops.length-1];
    if (lastStop >= 1 && !insertNewFlag) {
      colorStops.insert(0, -0.5);
      gradientColors.insert(0, lastColor);
      insertNewFlag = true;
    }
    
    //once the second to last color reaches "the end" we have 
    //to calibrate our list by removing the previous last color
    //and shifting the colors and stops one to the right!
    var secondToLastStop = colorStops[colorStops.length-2];
    if (secondToLastStop >= 1) {
      colorStops.remove(lastStop);
      gradientColors.remove(lastColor);
      var lastElement = gradientColors.removeLast();
      gradientColors.insert(0, lastElement);
      insertNewFlag = false;
    }

    //must recreate gradient paint and reassign ti to 
    //logoGradientBackground
    gradientPaint = Paint()
      ..shader = Gradient.linear(
        Offset.zero,
        const Offset(0, 350),
        gradientColors,
        colorStops,
        TileMode.clamp
      );

    logoGradientBackground!.paint = gradientPaint;
  }
}