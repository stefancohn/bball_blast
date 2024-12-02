// ignore: file_names
import 'dart:async';
import 'dart:ui';

import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/Background/ParallaxBackground.dart';
import 'package:bball_blast/config.dart';
import 'package:bball_blast/ui/HomeButton.dart';
import 'package:bball_blast/ui/MyTextBox.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';


class Gameover extends PositionComponent with HasGameRef<BBallBlast>{
 late MyTextBox gameOverText;
 late ButtonComponent restartButton;
 
 late Sprite replayImage;
 SpriteComponent? replaySprite;

 late Vector2 replaySpriteSize = Vector2(game.camera.viewport.size.x/2.5, game.camera.viewport.size.x/2.5);

 late List highscoresList;

 final TextPaint _textPaintWhite = TextPaint(
  style:  const TextStyle(
    fontSize: 25,
    fontFamily: 'Score',
    color: Color.fromARGB(255, 255, 255, 255),
  )
);
final TextPaint _textPaintWhiteSmall = TextPaint(
  style:  const TextStyle(
    fontSize: 17,
    fontFamily: 'Score',
    color: Color.fromARGB(255, 255, 255, 255),
  )
);


 Gameover() : super();

 @override
 Future<void> onLoad() async {
  //get DB to start working 
  await _configureHighscore();


  replayImage = await game.loadSprite('playButtonWhite.png');

  //replay button spirte
  replaySprite = SpriteComponent(
    sprite: replayImage, 
    size: replaySpriteSize,
    position: game.worldToScreen(Vector2(0, 7.5)),
    anchor: Anchor.center
  );

  //convert the raw map we get from our SQL db query into a nicely formatted,
  //displayable string for high scores
  String highscoreString = "High Scores:\n\n";
  for (int i = 0; i < highscoresList.length; i++){
    highscoreString = "$highscoreString${i+1}) ${highscoresList[i]['score']}\n";
  }

  //text)
   gameOverText = MyTextBox(
     text: highscoreString,
     renderer: (game.camera.viewport.size.x < 140 ? _textPaintWhite : _textPaintWhiteSmall),
     align: Anchor.center,
     config: const TextBoxConfig(growingBox: false),
     bgPaint: orangeBg2,
     borderPaint: Paint()..color=Colors.black,
     size: Vector2(game.camera.viewport.size.x*.65, game.camera.viewport.size.y*.33)
   )..position = game.worldToScreen(Vector2(0, -25)) ..anchor=Anchor.center;

  //restart button
   restartButton = ButtonComponent(
     position: replaySprite!.position,
     button: PositionComponent(
       size: replaySprite!.size,
     ),
     onPressed: ()=>game.loadGameScene(),
     anchor: Anchor.center
   );

   //home button
   HomeButton homeButton = HomeButton(
    position: game.worldToScreen(Vector2(0,30)),
    size: restartButton.size*.8,
   );

  //add to game
  await addParallaxBg();
  await game.addAll([gameOverText, restartButton, replaySprite!, homeButton]);
 }

 //helper to make parallax bg the bg with a gray overlay
  Future<void> addParallaxBg() async{
    ParallaxBackground parallax = ParallaxBackground();
    await add(parallax);
    RectangleComponent rect = RectangleComponent(priority: -1, anchor: Anchor.center, position: game.worldToScreen(Vector2(0,0)), size: game.camera.viewport.size, paint: Paint() ..color = const Color.fromARGB(107, 255, 255, 255));
    await game.add(rect);
  }




 Future<void> _configureHighscore() async {
    bool shouldInsert = false; 

    //grab DB and its contents
    final db = game.database;
    var dbList = await db.query('highscores', orderBy: 'score DESC');

    //Make score map to store in DB
    Map<String, Object?> score = {
      'score': BBallBlast.gameplay.score
    }; 

    //if dbList is full, lets grab the smallest score, check if our current score
    //is larger than any existing score
    if (dbList.length >= 3) {
      //get int from list of maps
      int curScore = score['score']! as int;
      int lowestHs = dbList[dbList.length-1]['score']! as int;
      
      //check if smallest high score is less than new score
      if (curScore > lowestHs) {
        shouldInsert = true;
        await db.delete('highscores', where: 'score=?', whereArgs: [lowestHs]);
      }
    } else { //if db has less than 3 entries put it inside 
      shouldInsert = true;
    }

    //insert into DB 
    if (shouldInsert) {
      await db.insert(
        'highscores',
        score,
        conflictAlgorithm: ConflictAlgorithm.ignore
      );
    }

    highscoresList = await db.query('highscores', orderBy: 'score DESC');
 }
}
