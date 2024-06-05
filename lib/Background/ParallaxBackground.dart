import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/Background/ParallaxBackgroundConfig.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/parallax.dart';

class ParallaxBackground extends Component with HasGameRef<BBallBlast>{
  //components related to ensuring circle display
  late ParallaxComponent bricksBackground;
  late ParallaxComponent background2;
  late ClipComponent rectMask;

  //calculations stuffs
  double radius = 100;
  double rectGrowthRate = 300;
  late double posAdjustRate = (rectGrowthRate + (5))/2;

  //positional vars
  late Vector2 topLeft = game.camera.viewport.position;
  late Vector2 screenSize = game.camera.viewport.size;
  late Vector2 middlePos = game.camera.viewport.position + game.camera.viewport.size/2;
  late Vector2 leftCenter = Vector2(game.camera.viewport.position.x, game.camera.viewport.position.y + game.camera.viewport.size.y/2);
  late double right = game.camera.viewport.size.x;
  late double bottom = game.camera.viewport.size.y;

  ParallaxBackgroundConfig config; 

  ParallaxBackground(this.config) : super(
    priority: -2,
  );

  @override
  Future<void> onLoad() async {
    super.onLoad();


    ParallaxBackgroundConfig bgCf = ParallaxBackgroundConfig(
      imageLayers: {'skyBackground/sky.png' : Vector2.all(0), 'skyBackground/clouds.png' : Vector2(3,-2),},
      baseVelocity: Vector2(1,0),
    );

    //create layers
    final layers = _createLayers(config);
    final layer2 = _createLayers(bgCf);

    //make parallax component
    background = ParallaxComponent(
      parallax: Parallax(
        await Future.wait(layers),
        baseVelocity: config.baseVelocity,
        size: game.camera.viewport.size*(11/10),
      ),
    );

    background2 = ParallaxComponent(
      parallax: Parallax(
        await Future.wait(layer2),
        baseVelocity: bgCf.baseVelocity,
        size: game.camera.viewport.size,
      ),
      position: game.camera.viewport.position,
      priority: -2
    );

    rectMask = ClipComponent.rectangle(
      position: topLeft,
      size: Vector2.all(radius),
      children: [background],
      priority: -1
    );

    //must add to game instead of this component due to priority naunce
    game.add(rectMask);
    game.add(background2);
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

  @override
  void update(double dt) {
    super.update(dt);

    _checkRectMaskExpansion(dt); //TODO: add bool to optimize this & further functionality 
  }


  ///
  ///OTHER METHODS
  ///
  
  //check to see how rectangle should expand to properly fill world 
  void _checkRectMaskExpansion(double dt) {
    double rectMaskRight = rectMask.size.x + (rectMask.position.x - game.camera.viewport.position.x); 

    //move rect to ensure it is properly in the left 
    if (rectMask.position.x > topLeft.x) {
      rectMask.position.x -= dt*rectGrowthRate;
    }
    //move rect to ensure it is properly on the top
    if (rectMask.position.y > topLeft.y) {
      rectMask.position.y -= dt*rectGrowthRate;
    }
    //check if rect has surpassed right side of world
    if (rectMaskRight <= right) {
      //if not increase height
      rectMask.size.x += dt * rectGrowthRate;
    } 
    //check if rect has surpassed bottom
    if (rectMask.size.y <= game.camera.viewport.size.y) {
      //if not increase height
      rectMask.size.y += dt * rectGrowthRate;
    }
  }

  //LOAD ALL CONFIGS AND IMAGES
}

/* HOW TO RESIZE!!!!
background.size = Vector2.all(400);
background.parallax?.resize(Vector2.all(400));
circle.radius = 200;
*/