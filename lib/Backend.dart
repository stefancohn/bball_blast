import 'package:bball_blast/BBallBlast.dart';
import 'package:sqflite/sqflite.dart';

String ballImgPath = "";

class Backend {
  static Database db = BBallBlast.db;

  static Future<void> acquireImgPaths() async {
    //set ballImgPath
    var dbList = await db.query('balls', where: 'equipped=?', whereArgs:[1]);
    if (dbList.isNotEmpty) {
      ballImgPath = dbList.first['filepath'] as String;
    }
  }
}