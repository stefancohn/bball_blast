import 'dart:async';
import 'dart:ui';

import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/Background/GradientBackground.dart';
import 'package:bball_blast/config.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:sqflite/sqflite.dart';


class Gameover extends PositionComponent with HasGameRef<BBallBlast>{
 late TextComponent gameOverText;
 late ButtonComponent restartButton;
 
 late Sprite replayImage;
 SpriteComponent? replaySprite;

 late Vector2 replaySpriteSize = Vector2(game.camera.viewport.size.x/3, game.camera.viewport.size.x/3);

 late List highscoresList;


 Gameover() : super();

 @override
 Future<void> onLoad() async {
  //get DB to start working 
  await _configureHighscore();

  replayImage = await game.loadSprite('replayButton.png');


  /*Paint gradientBlend = Paint()
    ..colorFilter = const ColorFilter.mode(
      Color.fromARGB(255, 8, 168, 255), // Change this to the desired color
      BlendMode.modulate,
    );*/

  //replay button spirte
  replaySprite = SpriteComponent(
    sprite: replayImage, 
    size: replaySpriteSize,
    position: game.worldToScreen(Vector2(0, 28)),
    anchor: Anchor.center
  );

  //matching gradient bg
  GradientBackground gradientBg = GradientBackground(
    colors: [const Color.fromARGB(255, 255, 0, 0), const Color.fromARGB(255, 255, 128, 0),const Color.fromARGB(255, 251, 255, 21)],
    size: replaySpriteSize,
    position: replaySprite!.position,
    anchor: Anchor.center
  );

  //convert the raw map we get from our SQL db query into a nicely formatted,
  //displayable string for high scores
  String highscoreString = "High Scores:\n\n";
  for (int i = 0; i < highscoresList.length; i++){
    highscoreString = "$highscoreString${i+1}) ${highscoresList[i]['score']}\n";
  }

  //text
   gameOverText = TextBoxComponent(
     text: highscoreString,
     textRenderer: textPaintBlack,
     position: game.worldToScreen(Vector2(0, -15)),
     align: Anchor.center,
     anchor: Anchor.center,
     size: game.camera.viewport.size
   );

  //restart button
   restartButton = ButtonComponent(
     position: replaySprite!.position,
     button: PositionComponent(
       size: replaySprite!.size,
     ),
     onPressed: ()=>game.loadGameScene(),
     anchor: Anchor.center
   );

    //add to game
   await game.add(gameOverText);
   await game.add(restartButton);
   await game.add(replaySprite!);
   await game.add(gradientBg);
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

    //if dbList isn't full, lets grab the smallest score, check if our current score
    //is larger than any existing score
    if (dbList.length > 3) {
      //get int from list of maps
      int curScore = score['score']! as int;
      int lowestHs = dbList[dbList.length-1]['score']! as int;
      
      //check if smallest high score is less than new score
      if (curScore > lowestHs) {
        shouldInsert = true;
        db.delete('highscores', where: 'score=?', whereArgs: [lowestHs]);
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

 @override
  void update(double dt) {
    super.update(dt);
  }
}
