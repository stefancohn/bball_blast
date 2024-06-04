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
  late CircleComponent circle;
  double radius = 100;

  Paint paint = Paint()
      ..color = const Color.fromRGBO(255, 67, 54, 1)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

  ParallaxBackgroundConfig config; 

  ParallaxBackground(this.config) : super(
    priority: -1,
  );

  @override
  Future<void> onLoad() async {
    super.onLoad();

    //create layers
    final layers = config.imageLayers.entries.map(
    (e) => game.loadParallaxLayer(
      ParallaxImageData(e.key),
      velocityMultiplier: e.value,
      fill: LayerFill.height),
    );

    circle = CircleComponent(
      radius: radius,
      position: game.camera.viewport.position,
      paint: Paint() ..color = Color.fromARGB(0, 100, 100, 100),
    );

    //make parallax component
    background = ParallaxComponent(
      priority: -2,
      parallax: Parallax(
        await Future.wait(layers),
        baseVelocity: config.baseVelocity,
        size: circle.size,
      ),
      position: game.worldToScreen(game.camera.visibleWorldRect.topLeft.toVector2()),
    );

    //must add to game instead of this component due to priority naunce
    game.add(background);
    game.add(circle);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    Path upperLeft = Path();
    var circleRect = Rect.fromCircle(center: Offset(circle.position.x+radius, circle.position.y+radius), radius: radius);
    upperLeft.arcTo(circleRect, pi, pi/2,true);
    upperLeft.lineTo(background.position.x,background.position.y);
    canvas.drawPath(upperLeft, paint);
  }
}

/* HOW TO RESIZE!!!!
background.size = Vector2.all(400);
background.parallax?.resize(Vector2.all(400));
circle.radius = 200;
*/