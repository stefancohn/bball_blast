import 'dart:async';
import 'dart:math';
import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/Background/ParallaxBackgroundConfig.dart';
import 'package:flame/components.dart';
import 'package:flame/parallax.dart';

class ParallaxBackground extends Component with HasGameRef<BBallBlast>{
  //components
  ClipComponent? rectMask;
  late ClipComponent currentMask;
  late ParallaxComponent firstBg;
  late List<ParallaxComponent> backgroundList;

  //calculations stuffs
  double radius = 50;
  double rectGrowthRate = 400;
  late double posAdjustRate = (rectGrowthRate + (5))/2;

  //positional vars
  late Vector2 topLeft = game.camera.viewport.position;
  late Vector2 screenSize = game.camera.viewport.size;
  late Vector2 middlePos = game.camera.viewport.position + game.camera.viewport.size/2;
  late Vector2 leftCenter = Vector2(game.camera.viewport.position.x, game.camera.viewport.position.y + game.camera.viewport.size.y/2);
  late double right = game.camera.viewport.size.x;
  late double bottom = game.camera.viewport.size.y;

  Random rand = Random();

  late int currentBgIdx;

  //OceanBg config numbers
  Vector2 fishSpeed = Vector2(6, 0);
  Vector2 reefSpeed = Vector2(8,0);

  ParallaxBackground() : super(
    priority: -2,
  );

  @override
  Future<void> onLoad() async {
    super.onLoad();

    backgroundList = await _loadParallaxSetup();

    //get random background to set onLoad
    currentBgIdx = rand.nextInt(backgroundList.length);
    firstBg = backgroundList[currentBgIdx];

    //must add to game instead of this component due to priority naunce
    game.add(firstBg);
  }

  bool expansionCheckKill = false;
  @override
  void update(double dt) {
    super.update(dt);
    
    //null check b/c rectMask does not get set first
    if (rectMask != null) {
      //if we should stop expanding the rect mask
      if(_stopRectMaskExpansion(dt)){
        //Get rid of our first bg
        if (firstBg.parent != null){
          firstBg.removeFromParent();
        } 

        //make deep copy of rectMask as currentMask, remove rectMask and replace it w/ currentMask
        currentMask = _createRectMask(rectMask!.children.elementAt(0) as ParallaxComponent, game.camera.viewport.size);
        game.remove(rectMask!);
        game.add(currentMask);
        rectMask = null;
      }
    }
  }


  ///
  ///OTHER METHODS
  ///
  
  //check to see how rectangle should expand to properly fill world 
  bool _stopRectMaskExpansion(double dt) {
    double rectMaskRight = rectMask!.size.x + (rectMask!.position.x - game.camera.viewport.position.x); //helper var
    bool stopFlag = true;

    //move rect to ensure it is properly in the left 
    if (rectMask!.position.x > topLeft.x) {
      rectMask!.position.x -= dt*rectGrowthRate;
      stopFlag = false;
    }
    //move rect to ensure it is properly on the top
    if (rectMask!.position.y > topLeft.y) {
      rectMask!.position.y -= dt*rectGrowthRate;
      stopFlag = false;
    }
    //check if rect has surpassed right side of world
    if (rectMaskRight <= right) {
      //if not increase height
      rectMask!.size.x += dt * rectGrowthRate;
      stopFlag = false;
    } 
    //check if rect has surpassed bottom
    if (rectMask!.size.y <= game.camera.viewport.size.y) {
      //if not increase height
      rectMask!.size.y += dt * rectGrowthRate;
      stopFlag = false;
    }

    return stopFlag; 
  }

  //LOAD ALL CONFIGS AND PARALLAX COMPONENTs
  Future<List<ParallaxComponent>> _loadParallaxSetup() async {

    //CONFIGS
    ParallaxBackgroundConfig skyConfig = ParallaxBackgroundConfig(
      imageLayers: {'skyBackground/sky.png' : Vector2.all(0), 'skyBackground/clouds.png' : Vector2(3,-2),},
      baseVelocity: Vector2(1,0),
    );

    ParallaxBackgroundConfig bricksConfig = ParallaxBackgroundConfig(
      imageLayers: {'brickBackground.png' : Vector2(10,0)},
      baseVelocity: Vector2(2,0),
    );

    ParallaxBackgroundConfig oceanConfig = ParallaxBackgroundConfig(
      imageLayers: {"oceanBg/bgbg.png" : Vector2(0,0), "oceanBg/fr.png" : fishSpeed, "oceanBg/gf.png" : fishSpeed * -1, 
      "oceanBg/r2.png" : reefSpeed, "oceanBg/r1.png": reefSpeed, "oceanBg/r3.png": reefSpeed, "oceanBg/r4.png" : reefSpeed,
      "oceanBg/r5.png" : reefSpeed, "oceanBg/r6.png" : reefSpeed, "oceanBg/r7.png" : reefSpeed, "oceanBg/r8.png" : reefSpeed,
      "oceanBg/r9.png" : reefSpeed},

      baseVelocity: Vector2(1,0),
    );

    ParallaxBackgroundConfig spaceConfig = ParallaxBackgroundConfig(
      imageLayers: {"spaceBg/l6.png" : Vector2(0,0), "spaceBg/l5.png" : Vector2(6,0), "spaceBg/l4.png" : Vector2(9,0), 
      "spaceBg/l3.png" : Vector2(7,0), "spaceBg/l2.png" : Vector2(1,0), "spaceBg/l1.png" : Vector2(2,0)},

      baseVelocity: Vector2(1,0),
    );

    //GET LAYER FOR PARALLAX COMPONENT BY INPUTTIN CONFIG INTO
    //LAYER CREATION
    final skyLayers = _createLayers(skyConfig);
    final bricksLayers = _createLayers(bricksConfig);
    final oceanLayers = _createLayers(oceanConfig);
    final spaceLayers = _createLayers(spaceConfig);

    //BGs/parallaxComponents
    ParallaxComponent skyBackground = ParallaxComponent(
      parallax: Parallax(
        await Future.wait(skyLayers),
        baseVelocity: skyConfig.baseVelocity,
        size: game.camera.viewport.size,
      ),
      position: game.camera.viewport.position,
      priority: -2
    );

    ParallaxComponent bricksBackground = ParallaxComponent(
      parallax: Parallax(
        await Future.wait(bricksLayers),
        baseVelocity: bricksConfig.baseVelocity,
        size: game.camera.viewport.size,
      ),
      priority: -2,
      position: game.camera.viewport.position,
    );

    ParallaxComponent oceanBackground = ParallaxComponent(
      parallax: Parallax(
        await Future.wait(oceanLayers),
        baseVelocity: oceanConfig.baseVelocity,
        size: game.camera.viewport.size,
      ),
      priority: -2,
      position: game.camera.viewport.position,
    );

    ParallaxComponent spaceBackground = ParallaxComponent(
      parallax: Parallax(
        await Future.wait(spaceLayers),
        baseVelocity: spaceConfig.baseVelocity,
        size: game.camera.viewport.size,
      ),
      priority: -2,
      position: game.camera.viewport.position,
    );

    List<ParallaxComponent> backgroundList = [skyBackground, bricksBackground, oceanBackground, spaceBackground];
    return backgroundList;
  }

  //create layers here
  _createLayers(ParallaxBackgroundConfig config) {
    final layers = config.imageLayers.entries.map(
    (e) => game.loadParallaxLayer(
      ParallaxImageData(e.key),
      velocityMultiplier: e.value,
      fill: LayerFill.height),
    );
    return layers;
  }

  void spawnRectMask() {
    //get random rectMask to set onLoad 
    int maskBgIdx = rand.nextInt(backgroundList.length-1);
    if (maskBgIdx == currentBgIdx) {
      maskBgIdx++;
    }
    currentBgIdx = maskBgIdx;
    rectMask = _createRectMask(backgroundList[maskBgIdx], Vector2.all(radius));
    
    game.add(rectMask!);
  }

  //load the rectangle mask
  ClipComponent _createRectMask(ParallaxComponent bgImg, Vector2 size) {
    bgImg.position = Vector2.all(0);

    return ClipComponent.rectangle(
      position: topLeft,
      size: size,
      children: [bgImg],
      priority: -1
    );
  }
}

/* HOW TO RESIZE!!!!
background.size = Vector2.all(400);
background.parallax?.resize(Vector2.all(400));
circle.radius = 200;
*/