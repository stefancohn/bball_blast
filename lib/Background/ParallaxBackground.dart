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
  late ParallaxComponent background;
  late ClipComponent circle;

  //calculations stuffs
  double radius = 100;
  double circleGrowthRate = 250;
  late double posAdjustRate = (circleGrowthRate + (5))/2;

  //positional vars
  late Vector2 topLeft = game.camera.viewport.position;
  late Vector2 screenSize = game.camera.viewport.size;
  late Vector2 middlePos = game.camera.viewport.position + game.camera.viewport.size/2;
  late Vector2 leftCenter = Vector2(game.camera.viewport.position.x, game.camera.viewport.position.y + game.camera.viewport.size.y/2);

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
        size: game.camera.viewport.size,
      ),
    );

    ParallaxComponent background2 = ParallaxComponent(
      parallax: Parallax(
        await Future.wait(layer2),
        baseVelocity: bgCf.baseVelocity,
        size: game.camera.viewport.size,
      ),
      position: game.camera.viewport.position,
      priority: -2
    );

    circle = ClipComponent.rectangle(
      position: topLeft,
      size: Vector2.all(radius),
      children: [background],
      priority: -1
    );

    //must add to game instead of this component due to priority naunce
    game.add(circle);
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

    //if (circle.size.x >= game.camera.viewport.size.x) {
      //rectangle.size.y += circleGrowthRate * dt;
    //} else {
      circle.size = Vector2(circle.size.x+dt*circleGrowthRate, circle.size.y + dt*circleGrowthRate);
      //circle.position = Vector2(circle.position.x - dt*posAdjustRate, circle.position.y - dt*posAdjustRate);
    //}
  }

}

/* HOW TO RESIZE!!!!
background.size = Vector2.all(400);
background.parallax?.resize(Vector2.all(400));
circle.radius = 200;
*/