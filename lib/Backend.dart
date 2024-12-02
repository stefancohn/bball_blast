import 'package:bball_blast/BBallBlast.dart';
import 'package:sqflite/sqflite.dart';

String ballImgPath = "";
String trailPath = "";
String bumpPath="";
List<Map<String, Object?>> acquiredBgs = List.empty();


//get all balls, trails
List<Map<String,Object?>> allBalls = List.empty(); 
List<Map<String,Object?>> allTrails = List.empty();
List<Map<String,Object?>> allBumps = List.empty();
List<Map<String,Object?>> allBgs = List.empty();

//for calculating cost; start at 25 coins.
//every item bought increments cost in that category by 25
int iterateCost= 10;
int newBallCost = 0; 
int newTrailCost=0;
int newBumpCost =0;
int newBgCost=0;

int coinAmt = 0;

class Backend {
  static Database db = BBallBlast.db;

  //so equipped ball gets shown
  static Future<void> acquireBallPath() async {
    //set ballImgPath
    var dbList = await db.query('balls', where: 'equipped=?', whereArgs:[1]);
    if (dbList.isNotEmpty) {
      ballImgPath = dbList.first['ball_name'] as String;
    }
    ballImgPath = "$ballImgPath.png";
  }

  //so equpped trail gets shown
  static Future<void> acquireTrail() async {
    //set trailPath
    var dbList = await db.query('trails', where: 'equipped=?', whereArgs:[1]);
    if (dbList.isNotEmpty) {
      trailPath = dbList.first['trail_name'] as String;
    }
  }

  //so equipped bump gets shown
  static Future<void> acquireBump() async {
    //set bumpPath
    var dbList = await db.query('bumps', where: 'equipped=?', whereArgs:[1]);
    if (dbList.isNotEmpty) {
      bumpPath = dbList.first['bump_name'] as String;
    }
  }

  //all acquired BGs get returned
  static Future<void> getAllAcquiredBgs() async {
    acquiredBgs = await db.query('bgs',where: 'acquired=?',whereArgs: [1]);
  }



  //GRAB ALL ROWS FOR DESIRED ITEM
  static Future<void> loadBallsForMenu() async {
    List<Map<String, Object?>> dbList = await db.query('balls');
    allBalls = dbList;

    //calculated cost to get new ball
    newBallCost = newBallCost < 50 ? iterateCost * dbList.where((ball) => ball['acquired'] == 1).length : 50;
  }

  static Future<void> loadTrailsForMenu() async {
    List<Map<String, Object?>> dbList = await db.query('trails');
    allTrails = dbList;

    //calculated cost to get new ball
    newTrailCost = newTrailCost < 50 ? iterateCost * dbList.where((trail) => trail['acquired'] == 1).length : 50;
  }

  static Future<void> loadBumpsForMenu() async {
    List<Map<String, Object?>> dbList = await db.query('bumps');
    allBumps = dbList;

    //calculated cost to get new ball
    newBumpCost = newBumpCost < 50 ? iterateCost * dbList.where((bump) => bump['acquired'] == 1).length : 50;
  }

  static Future<void> loadBgsForMenu() async {
    List<Map<String, Object?>> dbList = await db.query('bgs');
    allBgs = dbList;

    //calculated cost to get new ball
    newBgCost = (newBgCost < 50 ? iterateCost * (dbList.where((bump) => bump['acquired'] == 1).length) : 50);
  }




  //update DB, reload allBalls and coins
  static Future<void> buyItem(String tableName, String itemName) async {
    String rowName = tableName.substring(0, tableName.length-1);
    //transaction - all queries either happen or all don't happen
    await db.transaction((txn) async {
      //update coins
      await txn.rawUpdate("UPDATE coins SET coin = ?", [coinAmt-newBallCost]);

      //update balls
      await txn.rawUpdate("UPDATE $tableName SET acquired = 1 WHERE ${rowName}_name = ?", [itemName]);
    },);

    //reload appropriate menu and coins since they were updated
    if (tableName == 'balls'){
      await loadBallsForMenu();
    }
    else if (tableName == 'trails') {
      await loadTrailsForMenu();
    }
    else if (tableName == 'bumps') {
      await loadBumpsForMenu();
    } 
    else if (tableName == 'bgs') {
      await loadBgsForMenu();
      await getAllAcquiredBgs(); //need to reload this bc new bgs were acquired
    }

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

  static Future<void> equipTrail(String trailName) async {
    await db.transaction((txn) async {
      //remove current equpped ball
      await txn.rawUpdate("UPDATE trails SET equipped = 0 WHERE equipped = 1");

      //set desired ball to equpped
      await txn.rawUpdate("UPDATE trails SET equipped = 1 WHERE trail_name = ?", [trailName]);
    });

    //re-update balls list, set new path
    await loadTrailsForMenu();
    await acquireTrail();
  }

  static Future<void> equipBump(String bumpName) async {
    await db.transaction((txn) async {
      //remove current equipped ball
      await txn.rawUpdate("UPDATE bumps SET equipped = 0 WHERE equipped = 1");

      //set desired bump to equipped
      await txn.rawUpdate("UPDATE bumps SET equipped = 1 WHERE bump_name=?", [bumpName]);
    });

    //re-update list, set new path
    await loadBumpsForMenu();
    await acquireBump();
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







  //create our tables on creation
  static Future<void> createTables(Database db) async {
    //hs
    await db.execute(
      'CREATE TABLE highscores(score INTEGER)',
    );

    //coins
    await db.execute(
      'CREATE TABLE coins(coin INTEGER)',
    );

    //balls
    await db.execute(
      '''
      CREATE TABLE balls(
        ball_name VARCHAR(50) PRIMARY KEY NOT NULL, 
        acquired BOOLEAN NOT NULL DEFAULT FALSE, 
        equipped BOOLEAN NOT NULL DEFAULT FALSE
      )
      '''
    );

    //trails
    await db.execute(
      '''
      CREATE TABLE trails(
        trail_name VARCHAR(50) PRIMARY KEY NOT NULL,
        acquired BOOLEAN NOT NULL DEFAULT FALSE,
        equipped BOOLEAN NOT NULL DEFAULT FALSE
      )
      '''
    );

    //bumps
    await db.execute(
      '''
      CREATE TABLE bumps(
        bump_name VARCHAR(50) PRIMARY KEY NOT NULL,
        acquired BOOLEAN NOT NULL DEFAULT FALSE,
        equipped BOOLEAN NOT NULL DEFAULT FALSE
      )
      '''
    );

    //backgrounds
    await db.execute(
      '''
      CREATE TABLE bgs(
        bg_name VARCHAR(50) PRIMARY KEY NOT NULL,
        acquired BOOLEAN NOT NULL DEFAULT FALSE
      )
      '''
    );
  }

  //insert our rows on creation
  static Future<void> insertRows(Database db) async {
    await db.transaction((txn) async {
      //Insert coin
      await txn.insert('coins', {
        'coin' : 0
      });


      //Insert ball rows
      await txn.insert('balls', {
        'ball_name': 'whiteBall',
        'acquired' : true,
        'equipped' : true,
      });
      await txn.insert('balls', {
        'ball_name': 'basketball',
        'acquired' : false,
        'equipped' : false,
      });
      await 
      txn.insert('balls', {
        'ball_name' : 'smileyBall',
        'acquired' : false,
        'equipped' : false,
      });


      //Insert trails rows
      await txn.insert('trails', {
        'trail_name': 'white',
        'acquired' : true,
        'equipped' : true,
      });
      await txn.insert('trails', {
        'trail_name': 'orange',
        'acquired' : false,
        'equipped' : false,
      });
      await txn.insert('trails', {
        'trail_name': 'blue',
        'acquired' : false,
        'equipped' : false,
      });
      await txn.insert('trails', {
        'trail_name': 'pink',
        'acquired' : false,
        'equipped' : false,
      });
      await txn.insert('trails', {
        'trail_name': 'green',
        'acquired' : false,
        'equipped' : false,
      });


      //Insert bumps rows
      await txn.insert('bumps', {
        'bump_name': 'white',
        'acquired' : true,
        'equipped' : true,
      });
      await txn.insert('bumps', {
        'bump_name': 'orange',
        'acquired' : false,
        'equipped' : false,
      });
      await txn.insert('bumps', {
        'bump_name': 'blue',
        'acquired' : false,
        'equipped' : false,
      });
      await txn.insert('bumps', {
        'bump_name': 'pink',
        'acquired' : false,
        'equipped' : false,
      });
      await txn.insert('bumps', {
        'bump_name': 'green',
        'acquired' : false,
        'equipped' : false,
      });


      //Insert bg rows
      await txn.insert('bgs', {
        'bg_name': 'sky',
        'acquired' : true,
      });
      await txn.insert('bgs', {
        'bg_name': 'bricks',
        'acquired' : true,
      });
      await txn.insert('bgs', {
        'bg_name': 'space',
        'acquired' : false,
      });
      await txn.insert('bgs', {
        'bg_name': 'ocean',
        'acquired' : false,
      });
    });
  }
}