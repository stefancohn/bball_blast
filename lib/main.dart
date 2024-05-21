import 'package:bball_blast/BBallBlast.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Flame.device.fullScreen();

  BBallBlast game = BBallBlast();
  runApp(
    GameWidget(game : kDebugMode ? BBallBlast() : game)
  );
}