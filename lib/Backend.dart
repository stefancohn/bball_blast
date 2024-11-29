import 'package:bball_blast/BBallBlast.dart';
import 'package:sqflite/sqflite.dart';

String ballImgPath = "";

//get all balls
List<Map<String, Object?>> allBalls = List.empty(); 

//for calculating cost; start at 25 coins.
//every item bought increments cost in that category by 25
int newBallCost = 0; 

int coinAmt = 0;

class Backend {
  static Database db = BBallBlast.db;


  static Future<void> acquireBallPath() async {
    //set ballImgPath
    var dbList = await db.query('balls', where: 'equipped=?', whereArgs:[1]);
    if (dbList.isNotEmpty) {
      ballImgPath = dbList.first['ball_name'] as String;
    }
    ballImgPath = "$ballImgPath.png";
  }


  static Future<void> loadBallsForMenu() async {
    List<Map<String, Object?>> dbList = await db.query('balls');
    allBalls = dbList;

    //calculated cost to get new ball
    newBallCost = 25 * dbList.where((ball) => ball['acquired'] == 1).length;
  }


  //update DB, reload allBalls and coins
  static Future<void> buyBall(String ballName) async {
    //transaction - all queries either happen or all don't happen
    await db.transaction((txn) async {
      //update coins
      await txn.rawUpdate("UPDATE coins SET coin = ?", [coinAmt-newBallCost]);

      //update balls
      await txn.rawUpdate("UPDATE balls SET acquired = 1 WHERE ball_name = ?", [ballName]);
    },);

    //reload ball menu and coins since they were updated
    await loadBallsForMenu();
    await initializeCoinAmt();
  }


  static Future<void> equipBall(String ballName) async {
    await db.transaction((txn) async {
      //remove current equpped ball
      await txn.rawUpdate("UPDATE balls SET equipped = 0 WHERE equipped = 1");

      //set desired ball to equpped
      await txn.rawUpdate("UPDATE balls SET equipped = 1 WHERE ball_name = ?", [ballName]);
    });

    //re-update balls list, set new ballimgpath
    await loadBallsForMenu();
    await acquireBallPath();
  }


  //set amount of coins var
  static Future<void> initializeCoinAmt() async {
    var dbList = await db.query('coins',);

    //set coinAmt correctly
    if (dbList.isEmpty) {
      coinAmt = 0;
    } else {
      coinAmt = dbList[0]['coin'] as int;
    }
  }


  //add one to coin count in player DB 
  static Future<void> iteratePlayerCoins() async {
    //grab current score
    var dbList = await db.query('coins',);

    //if there isn't a score, must add
    if(dbList.isEmpty) {
      await db.insert(
        'coins',
        {"coin" : 1},
        conflictAlgorithm: ConflictAlgorithm.ignore
      );
    }
    //else just iterate by one
    else {
      await db.rawUpdate('UPDATE coins SET coin = coin +1');
    }
  }


  //for testing
  static Future<void> addLotsOfCoins() async {
    await db.rawUpdate("UPDATE coins set coin = 9999");
    await initializeCoinAmt();
  } 
}