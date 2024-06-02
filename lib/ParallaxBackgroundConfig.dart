import 'package:flame/components.dart';

class ParallaxBackgroundConfig {
  List<String> filepaths;
  List<Vector2> layerVelocities;
  double? position;
  double? size;

  ParallaxBackgroundConfig({
    required this.filepaths,
    required this.layerVelocities,
    this.position,
    this.size,
  });
}