// ignore: file_names
import 'dart:async';

import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/config.dart';
import 'package:flame/components.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flame/palette.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

//GODUNIT of our customize menu
class CustomizeMenu extends Component with HasGameRef<BBallBlast>{
  TextPaint textPaintBlack = TextPaint(
    style: const TextStyle(
      fontSize: 20,
      fontFamily: 'Score',
      color: Color.fromARGB(255, 255, 255, 255),
    )
  );

  @override
  FutureOr<void> onLoad() {
    MyTextBox test = MyTextBox(text: "CUSTOMIZE", renderer: textPaintBlack, bgPaint: orangeBg, borderPaint: outline,)
      ..position = game.worldToScreen(Vector2(0,-40))
      ..size = Vector2(game.camera.viewport.size.x/3, game.camera.viewport.size.y/10)
      ..anchor = Anchor.center;

    add(test);

    return super.onLoad();
  }
}

//nice lil textbox
class MyTextBox extends TextBoxComponent {
  Paint? bgPaint;
  Paint? borderPaint;
  late Rect bgRect;

  MyTextBox({
    required String text, 
    required TextRenderer renderer, 
    this.bgPaint,
    this.borderPaint,
    super.align,
    super.size,
    double? timePerChar,
  }) : 
  super(
    text: text,
    textRenderer: renderer,

    boxConfig: TextBoxConfig(
      maxWidth: 400,
      timePerChar: timePerChar ?? 0.05,
      growingBox: true,
    ),
    
  );

  @override
  Future<void> onLoad() {
    bgRect = Rect.fromLTWH(0, 0, width, height);
    size.addListener(() {
      bgRect = Rect.fromLTWH(0, 0, width, height);
    });

    return super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    if (bgPaint != null) { 
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          bgRect, const Radius.circular(20)
        ),
        bgPaint!
      );
    }
    if (borderPaint != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          bgRect, const Radius.circular(20)
        ),
        borderPaint!
      );
    }
    
    super.render(canvas);
  }
}