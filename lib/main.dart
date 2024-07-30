import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/config.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Flame.device.fullScreen();
  //Flame.device.setPortrait();
  
  //open DB at default file loc and create tables
  print(await getDatabasesPath());
  final db = await openDatabase(
    join(await getDatabasesPath(), 'bball_blast.db'),
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE highscores(score INTEGER)',
      );
    },
    version: 1,
  );
  db.delete('highscores');
  runApp(
    MyApp(db: db)
  );
}


class MyApp extends StatelessWidget {
  final Database db;
  const MyApp({super.key, required this.db});

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
            deviceWidth = screenSize.width;
            deviceHeight = screenSize.height;
            

            final game = BBallBlast(database: db);

            return GameWidget(
              game: game,
            );
          },
        ),
      ),
    );
  }
}