// ignore: file_names
import 'dart:async';

import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/config.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

TextPaint textPaintWhite = TextPaint(
  style: const TextStyle(
    fontSize: 20,
    fontFamily: 'Score',
    color: Color.fromARGB(255, 255, 255, 255),
  )
);

// ignore: camel_case_types
enum menuState {def, ball, trail, bump, bg}



//GODUNIT of our customize menu
class CustomizeMenu extends Component with HasGameRef<BBallBlast>{

  @override
  FutureOr<void> onLoad() async {
    MyTextBox headerBox = MyTextBox(
      text: "CUSTOMIZE", 
      renderer: textPaintWhite, 
      bgPaint: orangeBg, borderPaint: outline, 
      align: Anchor.center,
      size: Vector2(game.camera.viewport.size.x/1.8, game.camera.visibleWorldRect.height/10),
    )
      ..size = Vector2(game.camera.viewport.size.x/1.8, 50)
      ..position = game.worldToScreen(Vector2(0,-45))
      ..anchor = Anchor.center;
    await add(headerBox);


    //container to wrap our icons
    _customizationIconContainer iconContainer = _customizationIconContainer(
      position: game.worldToScreen(Vector2(0,1.5)), 
      size: Vector2(game.camera.viewport.size.x/1.45, game.camera.viewport.size.y/1.3), 
      bgPaint: orangeBg, 
      borderPaint: outline
    );
    await add(iconContainer);

    setPriority(children);

    return super.onLoad();
  }

  //method to stack everything nicely
  void setPriority(ComponentSet children) {
    for (int i = 0 ; i < children.length; i++) {
      //put textBoxes at 1
      if (children.elementAt(i) is MyTextBox) {
        children.elementAt(i).priority = 1;
      }

      //icon containers at 0
      if (children.elementAt(i) is _customizationIconContainer) {
        children.elementAt(i).priority = 0;
      }
    }
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




//container for all icons, includes logic for switching state and all
class _customizationIconContainer extends PositionComponent {
  Paint bgPaint;
  Paint borderPaint;
  late Rect bgRect = Rect.fromLTRB(0, 0, 50, 50);

  double? margin; 
  Vector2? iconSize;

  menuState currentState = menuState.def;

  List<_icon> icons = [];
  

  //constructor
  _customizationIconContainer({
    required Vector2 position, required Vector2 size, required this.bgPaint, required this.borderPaint
  }) : super (
    position: position, 
    size: size,
    anchor: Anchor.center,
    
  ) {
    //init bgRect, margin, iconSize
    bgRect = Rect.fromLTWH(0,0,size.x, size.y);

    margin = size.x/10;
    iconSize = Vector2((size.x/10) * 3.75, 100);
  }

  @override
  FutureOr<void> onLoad() {
    _icon icon = _icon(bgPaint: whiteBg, borderPaint: outline, text: "Ball");
    addIcon(icon);
  

    super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    //render bg rectangle
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        bgRect, Radius.circular(boxRadius)
      ),
      bgPaint
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        bgRect, Radius.circular(boxRadius)
      ),
      borderPaint
    );
        
    super.render(canvas);
  }

  void addIcon(_icon icon) async {
    icon.size = iconSize!;
    icon.position = Vector2(margin!, margin!);
    //so we get a proper render!
    icon.bgRect = Rect.fromLTWH(0,0,icon.size.x, icon.size.y);
    
    icons.add(icon);
    await add(icon);
  }
}




//icon
class _icon extends PositionComponent with HasGameRef<BBallBlast> {
  Paint bgPaint;
  Paint borderPaint;
  late Rect bgRect;

  String text;

  //constructor
  _icon({required this.bgPaint, required this.borderPaint, required this.text}) : super (
    anchor: Anchor.topLeft,
  ) {
    //init bgRect
    bgRect = Rect.fromLTWH(0,0,size.x, size.y);
  }

  @override
  FutureOr<void> onLoad() async {
    bgRect = Rect.fromLTWH(0, 0, size.x, size.y);

    SpriteComponent ballIcon = SpriteComponent(sprite: await game.loadSprite("ballMenuIcon.png"), size: size, position: size/2, anchor: Anchor.center);

    await add(ballIcon);
    super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    //render bg rectangle
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        bgRect, Radius.circular(boxRadius)
      ),
      bgPaint
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        bgRect, Radius.circular(boxRadius)
      ),
      borderPaint
    );    

    super.render(canvas);
  }
}