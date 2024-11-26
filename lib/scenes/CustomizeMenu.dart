// ignore: file_names
import 'dart:async';

import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/Background/ParallaxBackground.dart';
import 'package:bball_blast/config.dart';
import 'package:bball_blast/entities/PlayButton.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/input.dart';
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
enum MenuState {def, ball, trails, bump, bg, notDef}



//GODUNIT of our customize menu
class CustomizeMenu extends Component with HasGameRef<BBallBlast>{
  static ValueNotifier<MenuState> curState = ValueNotifier<MenuState>(MenuState.def);

  @override
  FutureOr<void> onLoad() async {
    MyTextBox headerBox = MyTextBox(
      text: "CUSTOMIZE", 
      renderer: textPaintWhite, 
      bgPaint: orangeBg, borderPaint: outline, 
      align: Anchor.center,
      size: Vector2(game.camera.viewport.size.x/1.8, game.camera.visibleWorldRect.height/10),
    )
      ..size = Vector2(game.camera.viewport.size.x/1.8, game.camera.viewport.size.y/10)
      ..position = game.worldToScreen(Vector2(0,-45))
      ..anchor = Anchor.center;
    await add(headerBox);


    //container to wrap our icons
    _customizationIconContainer iconContainer = _customizationIconContainer(
      position: game.worldToScreen(Vector2(0,0)), 
      size: Vector2(game.camera.viewport.size.x/1.45, game.camera.viewport.size.y/1.5), 
      bgPaint: orangeBg, 
      borderPaint: outline
    );
    await add(iconContainer);

    //play button at bottom
    PlayButton playButton = PlayButton(position: game.worldToScreen(Vector2(0, 43)), size: Vector2(game.camera.viewport.size.x/ 3, game.camera.viewport.size.y/8));
    await add(playButton);

    addParalaxBg();

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

      //parallax containers at -1
      if (children.elementAt(i) is ParallaxBackground) {
        children.elementAt(i).priority = -1;
      }
    }
  }

  //helper to make parallax bg the bg with a gray overlay
  void addParalaxBg() async{
    ParallaxBackground parallax = ParallaxBackground();
    await add(parallax);
    RectangleComponent rect = RectangleComponent(priority: -2, anchor: Anchor.center, position: game.worldToScreen(Vector2(0,0)), size: game.camera.viewport.size, paint: Paint() ..color = Color.fromARGB(107, 255, 255, 255));
    await game.add(rect);
  }
}


int iconsPerRowDef = 2;
//container for all icons, includes logic for switching state and all
// ignore: camel_case_types
class _customizationIconContainer extends PositionComponent with HasGameRef<BBallBlast> {
  Paint bgPaint;
  Paint borderPaint;
  // ignore: prefer_const_constructors
  late Rect bgRect = Rect.fromLTRB(0, 0, 50, 50);

  late Sprite ballIconImg; 
  late Sprite trailsIconImg;
  late Sprite bgIconImg;
  late Sprite bumpsIconImg;
  late Sprite backIconImg;

  double? margin; 

  Vector2? defIconSize;
  Vector2? notDefIconSize;

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

    margin = (size.x/10) * 0.83333;

    defIconSize = Vector2((size.x/10) * 3.75, (size.y/10) * 3.3);
    notDefIconSize = Vector2(size.x/2.5, size.y/9);
  }


  @override
  FutureOr<void> onLoad() async {
    //init statechanger
    CustomizeMenu.curState.addListener(()=>renderIcons());

    //load sprites, icons
    await _loadAllSprites();
    await _loadAllIcons();

    //render icons
    await renderIcons();

    super.onLoad();
  }


  //render icons
  //iterate icons and add those of which that are of current state
  //remove those of which that are not of current state
  Future<void> renderIcons() async {
    for (int i = 0; i < icons.length; i++) {
      _icon curIcon = icons[i];

      //add curIcon if it matches menu state
      if (curIcon.stateWhenRendered == CustomizeMenu.curState.value) {
        await addIcon(curIcon, i);
      }

      //add our notDef icons if we are not on def state
      else if (curIcon.stateWhenRendered == MenuState.notDef && CustomizeMenu.curState.value != MenuState.def) {
        await addIcon(curIcon, i);
      }

      //make sure to remove if it's in the component and not in cur state
      else if (children.contains(curIcon)) {
        curIcon.removeFromParent();
      }

    }
  }

  //helper to load icons
  Future<void> _loadAllIcons() async {
    _icon ballIcon = _icon(bgPaint: whiteBg, borderPaint: outline, sprite: ballIconImg, stateWhenRendered: MenuState.def, stateToLeadTo: MenuState.ball);
    _icon trailsIcon = _icon(bgPaint: whiteBg, borderPaint: outline, sprite: trailsIconImg, stateWhenRendered: MenuState.def, stateToLeadTo: MenuState.trails);
    _icon bgIcon = _icon(bgPaint: whiteBg, borderPaint: outline, sprite: bgIconImg, stateWhenRendered: MenuState.def, stateToLeadTo: MenuState.bg);
    _icon bumpsIcon = _icon(bgPaint: whiteBg, borderPaint: outline, sprite: bumpsIconImg, stateWhenRendered: MenuState.def, stateToLeadTo: MenuState.bump);
    _icon backIcon = _icon(bgPaint: whiteBg, borderPaint: outline, sprite: backIconImg, stateWhenRendered: MenuState.notDef, stateToLeadTo: MenuState.def);

    //add to our list
    icons.addAll({ballIcon, trailsIcon, bgIcon, bumpsIcon, backIcon});
  }


  //helper to load all of our sprites 
  Future<void> _loadAllSprites() async {
    ballIconImg = await game.loadSprite("ballMenuIcon.png");
    trailsIconImg = await game.loadSprite("trailsIcon.png");
    bgIconImg = await game.loadSprite("bgIcon.png");
    bumpsIconImg = await game.loadSprite("bumpsIcon.png");
    backIconImg = await game.loadSprite("backIcon.png");
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

  Future<void> addIcon(_icon icon, int iconNum) async {
    //def icon setup
    if (CustomizeMenu.curState.value == MenuState.def) {
      int row = ((iconNum / iconsPerRowDef).floor()); 
      int col = (iconNum % iconsPerRowDef);

      icon.size = defIconSize!;
      icon.position = Vector2((margin! * (col + 1)) + (icon.size.x * col), (margin! * (row+1)) + (icon.size.y * row));

      //so we get a proper render!
      icon.bgRect = Rect.fromLTWH(0,0,icon.size.x, icon.size.y);
    }

    //notDef icon setup
    if (CustomizeMenu.curState.value != MenuState.def && icon.stateWhenRendered == MenuState.notDef) {
      icon.size = notDefIconSize!;
      icon.anchor = Anchor.center;
      icon.position = Vector2(size.x/2, (3.5*size.y)/4 );

      //so we get a proper render!
      icon.bgRect = Rect.fromLTWH(0,0,icon.size.x, icon.size.y);
    } 
    
    await add(icon);

  }
}




//icon
class _icon extends ButtonComponent with HasGameRef<BBallBlast> {
  Paint bgPaint;
  Paint borderPaint;
  late Rect bgRect;
  Sprite sprite;

  MenuState stateWhenRendered;
  MenuState stateToLeadTo;

  //constructor
  _icon({
    required this.bgPaint, required this.borderPaint, required this.sprite, required this.stateWhenRendered, required this.stateToLeadTo
  }) : super (
    anchor: Anchor.topLeft,
  ) {
    //init bgRect
    bgRect = Rect.fromLTWH(0,0,size.x, size.y);
  }

  @override
  FutureOr<void> onLoad() async {
    //rect for util
    bgRect = Rect.fromLTWH(0, 0, size.x, size.y);

    //set spritecomponent of icon
    SpriteComponent spriteIcon = SpriteComponent(sprite: sprite, size: size, position: size/2, anchor: Anchor.center);
    super.button = spriteIcon;

    //press/release functionality
    onPressed = () { 
      button!.scale = Vector2.all(1.05);
    };
    onReleased = () {
      button!.scale = Vector2.all(.95);
      //change menu state - recall render, on release for smoothness
      CustomizeMenu.curState.value = stateToLeadTo;
    };

    await add(spriteIcon);
    super.onLoad();
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