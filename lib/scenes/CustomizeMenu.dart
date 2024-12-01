// ignore: file_names
import 'dart:async';
import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/Backend.dart';
import 'package:bball_blast/Background/ParallaxBackground.dart';
import 'package:bball_blast/config.dart';
import 'package:bball_blast/ui/CoinAmtDisplay.dart';
import 'package:bball_blast/ui/MyTextBox.dart';
import 'package:bball_blast/ui/PlayButton.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/extensions.dart';
import 'package:flame/flame.dart';
import 'package:flame/input.dart';
import 'package:flame/text.dart';
import 'package:flame_noise/flame_noise.dart';
import 'package:flutter/material.dart';

TextPaint textPaintWhite = TextPaint(
  style: const TextStyle(
    fontSize: 17,
    fontFamily: 'Score',
    color: Color.fromARGB(255, 255, 255, 255),
  )
);

TextPaint textPaintWhiteSmall = TextPaint(
  style: const TextStyle(
    fontSize: 14,
    fontFamily: 'Score',
    color: Color.fromARGB(255, 255, 255, 255),
  )
);

// ignore: camel_case_types
enum MenuState {def, ball, trails, bump, bg, notDef, buy, equip, equipped}



//GODUNIT of our customize menu
//State managesment is handled by the curState valueNotifer.
//essential icons will change it accordingly with their custom defined behavior
class CustomizeMenu extends Component with HasGameRef<BBallBlast>{
  static ValueNotifier<MenuState> curState = ValueNotifier<MenuState>(MenuState.def);

  @override
  FutureOr<void> onLoad() async {

    //container to wrap our icons
    _customizationIconContainer iconContainer = _customizationIconContainer(
      position: game.worldToScreen(Vector2(0,0)), 
      size: Vector2(game.camera.viewport.size.x/1.45, game.camera.viewport.size.y/1.5), 
      bgPaint: orangeBg, 
      borderPaint: outline
    );
    await add(iconContainer);

    MyTextBox headerBox = MyTextBox(
      text: "CUSTOMIZE", 
      renderer: textPaintWhite, 
      bgPaint: orangeBg, borderPaint: outline, 
      align: Anchor.center,
      size: Vector2(game.camera.viewport.size.x*.5, game.camera.visibleWorldRect.height/10),
    )
      ..size = Vector2(game.camera.viewport.size.x*.5, game.camera.viewport.size.y/10)
      ..position = game.worldToScreen(Vector2(-4.5,-42))
      ..anchor = Anchor.center;
    await add(headerBox);

    //play button at bottom
    PlayButton playButton = PlayButton(position: game.worldToScreen(Vector2(0, 43)), size: Vector2(game.camera.viewport.size.x/ 3.5, game.camera.viewport.size.y/8));
    await add(playButton);

    //add coin amt display
    Vector2 coinAmtSize = Vector2(game.camera.viewport.size.x * .25, game.camera.viewport.size.y/12);
    CoinAmtDisplay coinAmtDisplay = CoinAmtDisplay(coinImg: iconContainer.coinImg, position: game.worldToScreen(Vector2(8,-46)), size: coinAmtSize);
    coinAmtDisplay.anchor = Anchor.topLeft;
    await add(coinAmtDisplay);

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
    RectangleComponent rect = RectangleComponent(priority: -2, anchor: Anchor.center, position: game.worldToScreen(Vector2(0,0)), size: game.camera.viewport.size, paint: Paint() ..color = const Color.fromARGB(107, 255, 255, 255));
    await game.add(rect);
  }
}



//This is our container for the interactive part of menu
//Holds all the "icons"
//Workflow: add sprite to loadSprite, add icon to appropriate _load___Icons method
//  renderIcons iterates thru all icons and loads appropriate ones based on curMenuState
//  custom icon functionality can be defined in onReleased in icon class

int iconsPerRowDef = 2;
int iconsColBall = 3;
//container for all icons, includes logic for switching state and all
// ignore: camel_case_types
class _customizationIconContainer extends PositionComponent with HasGameRef<BBallBlast> {
  Paint bgPaint;
  Paint borderPaint;
  // ignore: prefer_const_constructors
  late Rect bgRect = Rect.fromLTRB(0, 0, 50, 50);

  //going to just preload each sprite cus there won't be too many
  //necessary sprites
  late Sprite ballIconImg; 
  late Sprite trailsIconImg;
  late Sprite bgIconImg;
  late Sprite bumpsIconImg;
  late Sprite backIconImg;
  late Sprite lockedIconCircleImg;
  late Sprite coinImg;
  late Sprite checkMarkImg;

  Map<String, Sprite> ballSprites = {};
  Map<String, Sprite> colorSprites ={};
  Map<String, Sprite> bgSprites = {};

  double? defMargin; 
  double? customIconMargin;

  Vector2? defIconSize;
  Vector2? notDefIconSize;
  Vector2? ballCustomIconSize;

  List<_icon> icons = [];
  

  //constructor
  _customizationIconContainer({
    required Vector2 position, required Vector2 size, required this.bgPaint, required this.borderPaint
  }) : super (
    position: position, 
    size: size,
    anchor: Anchor.center,
    
  ) {
    //init bgRect, defMargin, iconSize
    bgRect = Rect.fromLTWH(0,0,size.x, size.y);

    defMargin = (size.x/10) * 0.83333;
    customIconMargin = (size.x) * 0.0625;

    defIconSize = Vector2((size.x/10) * 3.75, (size.y/10) * 3.3);
    notDefIconSize = Vector2(size.x/2.5, size.y/9);
    ballCustomIconSize = Vector2(size.x/4, size.y/9);
  }


  @override
  FutureOr<void> onLoad() async {
    //init statechanger
    CustomizeMenu.curState.addListener(()=>renderIcons());

    //load sprites, icons
    await _loadAllSprites();

    await _loadItemIcons(itemList: allBalls, spriteList: ballSprites, itemName: 'ball_name'); //load balls
    await _loadItemIcons(itemList: allTrails, spriteList: colorSprites, itemName: 'trail_name'); //load trails
    await _loadItemIcons(itemList: allBumps, spriteList: colorSprites, itemName: 'bump_name'); //load bumps 
    await _loadItemIcons(itemList: allBgs, spriteList: bgSprites, itemName: 'bg_name'); //load bgs
    await _loadNecessaryIcons();


    //render icons
    await renderIcons();

    super.onLoad();
  }


  //render icons
  //iterate icons and add those of which that are of current state
  //remove those of which that are not of current state
  Future<void> renderIcons() async {
    int addedCounter = 0;

    for (int i = 0; i < icons.length; i++) {
      _icon curIcon = icons[i];

      //add curIcon if it matches menu state
      if (curIcon.stateWhenRendered == CustomizeMenu.curState.value && !(children.contains(curIcon))) {
        await addIcon(curIcon, addedCounter);

        addedCounter++;
      } 

      //add our notDef icons if we are not on def state
      else if (curIcon.stateWhenRendered == MenuState.notDef && CustomizeMenu.curState.value != MenuState.def) {
        await addIcon(curIcon, i);
      }

      //make sure to remove if it's in the component and not in cur state
      if (children.contains(curIcon) && curIcon.stateWhenRendered != CustomizeMenu.curState.value) {
        if (curIcon.stateWhenRendered == MenuState.notDef && CustomizeMenu.curState.value == MenuState.def) {
          curIcon.removeFromParent();
        } else if (curIcon.stateWhenRendered != MenuState.notDef) {
          curIcon.removeFromParent();
        }
      }
    }
  }

  //helper to load icons
  Future<void> _loadNecessaryIcons() async {
    //main functionality icons
    _icon ballIcon = _icon(sprite: ballIconImg, stateWhenRendered: MenuState.def, stateToLeadTo: MenuState.ball);
    _icon trailsIcon = _icon(sprite: trailsIconImg, stateWhenRendered: MenuState.def, stateToLeadTo: MenuState.trails);
    _icon bgIcon = _icon(sprite: bgIconImg, stateWhenRendered: MenuState.def, stateToLeadTo: MenuState.bg);
    _icon bumpsIcon = _icon(sprite: bumpsIconImg, stateWhenRendered: MenuState.def, stateToLeadTo: MenuState.bump);

    _icon backIcon = _icon(sprite: backIconImg, stateWhenRendered: MenuState.notDef, stateToLeadTo: MenuState.def);

    //locked icon 
    //_icon lockedIconCircle = _icon(sprite: lockedIconCircleImg, stateWhenRendered: MenuState.ball, stateToLeadTo: MenuState.buy);

    //add to our list
    icons.addAll({ballIcon, trailsIcon, bgIcon, bumpsIcon, backIcon, });
  }


  //helper to load itemIcons
  Future<void> _loadItemIcons({required List<Map<String, Object?>> itemList, required Map<String, Sprite> spriteList, required String itemName}) async {
    //set "stateWhenRendered" properly with this var and if statement
    MenuState whenRender = MenuState.ball; 
    if (itemName == "ball_name") {
      whenRender = MenuState.ball;
    }
    else if (itemName == "trail_name") {
      whenRender = MenuState.trails;
    }
    else if (itemName == "bump_name") {
      whenRender = MenuState.bump;
    } else if (itemName == "bg_name") {
      whenRender = MenuState.bg;
    }


    for (int i = 0 ; i < itemList.length; i++ ) {
      var curItem = itemList[i];
      _icon newIcon;

      //get name, create icon
      String name = curItem[itemName] as String;
      name = name.trim();

      //show proper sprite if unlcoked
      if (curItem['acquired'] == 1){
        newIcon = _icon(sprite: spriteList[name]!, stateWhenRendered: whenRender, stateToLeadTo: (curItem['equipped'] == 1 ? MenuState.equipped : MenuState.equip), name: name);
      } 
      //else show mystery, get proper price
      else {
        newIcon = _icon(sprite: lockedIconCircleImg, stateWhenRendered: whenRender, stateToLeadTo: MenuState.buy, name: name);
      }

      icons.add(newIcon);
    }
  }




  Future<void> addIcon(_icon icon, int iconNum) async {

    //def icon setup
    if (icon.stateWhenRendered == MenuState.def) {
      //get row and col of icon
      int row = ((iconNum / iconsPerRowDef).floor()); 
      int col = (iconNum % iconsPerRowDef);

      icon.size = defIconSize!;
      icon.position = Vector2((defMargin! * (col + 1)) + (icon.size.x * col), (defMargin! * (row+1)) + (icon.size.y * row));
    }

    //ball icon setup
    else if (icon.stateWhenRendered == MenuState.ball || icon.stateWhenRendered == MenuState.trails || icon.stateWhenRendered == MenuState.bump
    || icon.stateWhenRendered == MenuState.bg ) {
      //get row and col of icon
      int row = ((iconNum / iconsColBall).floor()); 
      int col = (iconNum % iconsColBall);

      icon.size = ballCustomIconSize!;
      icon.position = Vector2((customIconMargin! * (col + 1)) + (icon.size.x * col), ((row == 0 ? customIconMargin! : customIconMargin! * 2) * (row+1)) + (icon.size.y * row));

    }


    //notDef icon setup
    if (CustomizeMenu.curState.value != MenuState.def && icon.stateWhenRendered == MenuState.notDef) {
      icon.size = notDefIconSize!;
      icon.anchor = Anchor.center;
      icon.position = Vector2(size.x/2, (3.5*size.y)/4 );
    } 

    //so we get a proper render!
    //icon.bgRect = Rect.fromLTWH(0,0,icon.size.x, icon.size.y);
    
    await add(icon);

    //add check mark to equpped ball
    if (icon.stateWhenRendered != MenuState.bg && icon.stateToLeadTo == MenuState.equipped) {
      await icon.addCheckMark(checkMarkImg);
    }

    //add price if locked
    if (icon.stateToLeadTo == MenuState.buy) {
      await icon.addPrice(coinImg);
    } 

  }


  Future<void> refreshIcons(MenuState state) async {
    //list to store icons to remove
    List<_icon> iconsToRemove = [];

    //add to removal list for proper removal from icons list
    for (int i = 0; i < icons.length; i++) {
      if (icons[i].stateWhenRendered == state) {
        iconsToRemove.add(icons[i]);
      }
    }

    //actually remove here
    for (_icon icon in iconsToRemove) {
      icon.removeFromParent();
      icons.remove(icon);
    }

    //reload icons and re-render them
    if (state == MenuState.ball){
      _loadItemIcons(itemList: allBalls, spriteList: ballSprites, itemName: 'ball_name');
    }
    else if (state == MenuState.trails) {
      _loadItemIcons(itemList: allTrails, spriteList: colorSprites, itemName: 'trail_name');
    }
    else if (state == MenuState.bump) {
      _loadItemIcons(itemList: allBumps, spriteList: colorSprites, itemName: 'bump_name');
    }
    else if (state == MenuState.bg) {
      _loadItemIcons(itemList: allBgs, spriteList: bgSprites, itemName: 'bg_name');
    }

    renderIcons();
  }

  //render da nice rect
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

  //helper to load necessary sprites 
  Future<void> _loadAllSprites() async {
    //main functionality imgs
    ballIconImg = await game.loadSprite("ballMenuIcon.png");
    trailsIconImg = await game.loadSprite("trailsIcon.png");
    bgIconImg = await game.loadSprite("bgIcon.png");
    bumpsIconImg = await game.loadSprite("bumpsIcon.png");
    backIconImg = await game.loadSprite("backIcon.png");
    coinImg = await game.loadSprite("coin.png");

    //locked img
    lockedIconCircleImg = await game.loadSprite("lockedIconCircle.png");
    checkMarkImg = await game.loadSprite("checkMark.png");

    //ball imgs
    ballSprites["smileyBall"] = await game.loadSprite("smileyBall.png");
    ballSprites["whiteBall"] = await game.loadSprite("whiteBall.png");
    ballSprites["basketball"] = await game.loadSprite("basketball.png");

    //colors
    Vector2 colorImgSrcSize = Vector2(200,185);
    final colorImg = await Flame.images.load('colorSpriteSheet.png');
    colorSprites["white"] = Sprite(colorImg, srcPosition: Vector2(0,0), srcSize: colorImgSrcSize);
    colorSprites["orange"] = Sprite(colorImg, srcPosition: Vector2(colorImgSrcSize.x*colorSprites.length + 5*colorSprites.length,0), srcSize: colorImgSrcSize);
    colorSprites["blue"] = Sprite(colorImg, srcPosition: Vector2(colorImgSrcSize.x*colorSprites.length + 5*colorSprites.length,0), srcSize: colorImgSrcSize);
    colorSprites["pink"] = Sprite(colorImg, srcPosition: Vector2(612,0), srcSize: colorImgSrcSize);
    colorSprites["green"] = Sprite(colorImg, srcPosition: Vector2(815,0), srcSize: colorImgSrcSize);

    //bgs
    bgSprites["sky"] = Sprite(await Flame.images.load('skyBackground/sky.png'));
    bgSprites["ocean"] = Sprite(await Flame.images.load('oceanBg/bgbg.png'));
    bgSprites["space"] = Sprite(await Flame.images.load('spaceBg/l6.png'));
    bgSprites["bricks"] = Sprite(await Flame.images.load('bricksBg.png'));
  }
}




//icon
// ignore: camel_case_types
class _icon extends ButtonComponent with HasGameRef<BBallBlast> {
  late Rect bgRect;
  Sprite sprite;

  MenuState stateWhenRendered;
  MenuState stateToLeadTo;

  String? name;

  //constructor
  _icon({
    required this.sprite, required this.stateWhenRendered, required this.stateToLeadTo, this.name
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

    //change menu state - recall render, on release for smoothness
    onReleased = () async {
      button!.scale = Vector2.all(.95);

      //only refresh render on nonbuy/equip/equipped icons
      if (stateToLeadTo != MenuState.buy && stateToLeadTo != MenuState.equip && stateToLeadTo != MenuState.equipped){
        CustomizeMenu.curState.value = stateToLeadTo;
      }


      //reduce coins appropriately, set to unlocked
      if (stateToLeadTo == MenuState.buy) {
        String tableName = "";
        if (stateWhenRendered == MenuState.ball) {
          tableName = "balls";
        }
        else if (stateWhenRendered == MenuState.trails) {
          tableName = "trails";
        }
        else if (stateWhenRendered == MenuState.bump) {
          tableName = "bumps";
        }
        else if (stateWhenRendered == MenuState.bg) {
          tableName = "bgs";
        }

        //verify we can buy it, then call Backend
        if (coinAmt > newBallCost) {
          await Backend.buyItem(tableName, name!);
          stateToLeadTo = MenuState.equip;

          (parent as _customizationIconContainer).refreshIcons(stateWhenRendered);
        }
        //else shakeEffect for invalid action
        else {
          shakeEffect();
        }
      }


      //change equpped ball when one is pressed
      else if (stateToLeadTo == MenuState.equip) {
        //modify DB
        if (stateWhenRendered == MenuState.ball) {
          await Backend.equipBall(name!);
        } 
        else if (stateWhenRendered == MenuState.trails) {
          await Backend.equipTrail(name!);
        }
        else if (stateWhenRendered == MenuState.bump) {
          await Backend.equipBump(name!);
        }


        stateToLeadTo = MenuState.equipped;

        //refresh icons
        (parent as _customizationIconContainer).refreshIcons(stateWhenRendered);
      }
    };

    //on cancel
    onCancelled = () => button!.scale=Vector2.all(.95);

    await add(spriteIcon);
    super.onLoad();
  }

  //add price indicator (coin sprite iwth text indicating sprite)
  Future<void> addPrice(Sprite coinImg) async {
    //grab proper cost of item
    String text ="";
    if (stateWhenRendered == MenuState.ball) {
      text = newBallCost.toString();
    }
    else if (stateWhenRendered == MenuState.trails) {
      text = newTrailCost.toString();
    } 
    else if (stateWhenRendered == MenuState.bump) {
      text= newBumpCost.toString();
    } 
    else if (stateWhenRendered == MenuState.bg) {
      text = newBgCost.toString();
    }


    Vector2 coinSpriteSize = size/2.5;

    SpriteComponent coinSprite = SpriteComponent(anchor: Anchor.center, position: Vector2(size.x/5, (size.y * 1.1) + coinSpriteSize.y/2), size: coinSpriteSize, sprite: coinImg);

    TextBoxComponent priceText = TextBoxComponent(
      anchor: Anchor.center, 
      text: text, 
      textRenderer: textPaintWhiteSmall,
      boxConfig: const TextBoxConfig(growingBox: true)
    ) 
    //need this after because boxConfig override initial pos/sizing
    ..size = Vector2(coinSpriteSize.x*2,coinSpriteSize.y)
    ..position = Vector2(coinSprite.x + (coinSpriteSize.x*1.2), coinSprite.y);

    await addAll({coinSprite, priceText});
  }


  //add check mark to equipped icon
  Future<void> addCheckMark(Sprite checkMarkImg) async {
    Vector2 checkMarkSize = size;

    SpriteComponent checkMarkSprite = SpriteComponent(anchor: Anchor.center, position: bgRect.center.toVector2(), size: checkMarkSize, sprite: checkMarkImg); 
    checkMarkSprite.priority = 1;
    (button as SpriteComponent).opacity = 0.8;

    await add(checkMarkSprite);
  }

  
  //shake effect when invlaid purchase attempted
  Future<void> shakeEffect() async {
    (button as SpriteComponent).add(MoveEffect.by(
        Vector2(8, 8),
        NoiseEffectController(duration: 0.5, noise: PerlinNoise(frequency: 400)),
      ),
    );
  }
}