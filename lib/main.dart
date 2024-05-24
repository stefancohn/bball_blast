import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/config.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Flame.device.fullScreen();
  //Flame.device.setPortrait();

  runApp(
    MyApp()
  );
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "BBall Blast",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            // Get screen dimensions using MediaQuery, if screenSize greater than stated, change it for camera sake
            final screenSize = MediaQuery.of(context).size;
            if (screenSize.width > gameWidth) {
              gameWidth = screenSize.width;
            }
            if (screenSize.height > gameHeight) {
              gameHeight = screenSize.height;
            }

            final game = BBallBlast();

            return GameWidget(
              game: game,
            );
          },
        ),
      ),
    );
  }
}