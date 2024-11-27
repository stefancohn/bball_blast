import 'package:bball_blast/BBallBlast.dart';
import 'package:sqflite/sqflite.dart';

String ballImgPath = "";

//get all balls
List<Map<String, Object?>> allBalls = List.empty(); 

//for calculating cost; start at 25 coins.
//every item bought increments cost in that category by 25
int newBallCost = 0; 

class Backend {
  static Database db = BBallBlast.db;

  static Future<void> acquireImgPaths() async {
    //set ballImgPath
    var dbList = await db.query('balls', where: 'equipped=?', whereArgs:[1]);
    if (dbList.isNotEmpty) {
      ballImgPath = dbList.first['filepath'] as String;
    }
  }

  static Future<void> loadBallsForMenu() async {
    List<Map<String, Object?>> dbList = await db.query('balls');
    allBalls = dbList;

    //calculated cost to get new ball
    newBallCost = 25 * dbList.where((ball) => ball['acquired'] == 1).length;
  }
}