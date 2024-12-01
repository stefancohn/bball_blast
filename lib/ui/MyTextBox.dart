//nice lil textbox
import 'dart:ui';

import 'package:bball_blast/config.dart';
import 'package:flame/components.dart';
import 'package:flame/text.dart';

class MyTextBox extends TextBoxComponent {
  Paint? bgPaint;
  Paint? borderPaint;
  late Rect bgRect;
  TextBoxConfig? config;

  MyTextBox({
    required String text, 
    required TextRenderer renderer, 
    this.bgPaint,
    this.borderPaint,
    super.align,
    super.size,
    double? timePerChar,
    TextBoxConfig? config,
  }) : 
  super(
    text: text,
    textRenderer: renderer,

    boxConfig: config ?? TextBoxConfig(
      maxWidth: 400,
      timePerChar: timePerChar ?? 0.05,
      growingBox: false,
    ),
    
  );

  @override
  Future<void> onLoad() {
    //super.boxConfig.growingBox = false;

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
          bgRect, Radius.circular(boxRadius)
        ),
        bgPaint!
      );
    }
    if (borderPaint != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          bgRect, Radius.circular(boxRadius)
        ),
        borderPaint!
      );
    }
    
    super.render(canvas);
  }
}