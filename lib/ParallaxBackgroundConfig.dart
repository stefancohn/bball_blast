import 'package:flame/components.dart';

class ParallaxBackgroundConfig {
  Map<String, Vector2> imageLayers; //includes velocity of each layer
  Vector2 baseVelocity;
  double? position;
  double? size;

  ParallaxBackgroundConfig({
    required this.imageLayers,
    required this.baseVelocity,
    this.position,
    this.size,
  });
}