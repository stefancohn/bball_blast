import 'dart:async';

import 'package:bball_blast/BBallBlast.dart';
import 'package:flame/components.dart';

class PauseOverlay extends PositionComponent with HasGameRef<BBallBlast>{

  @override
  FutureOr<void> onLoad() {
    game.pauseEngine();
  }
}