import 'dart:async';
import 'package:bball_blast/BBallBlast.dart';
import 'package:flutter/material.dart' hide Gradient;
import 'package:flame/components.dart';
import 'package:sqflite/sqflite.dart';

class CoinAmtDisplay extends PositionComponent with HasGameRef<BBallBlast> {
  Sprite coinImg;
  Vector2 coinSize = Vector2(30,30);
  SpriteComponent? coin;
  int? coinAmt;

  late Database db;

  CoinAmtDisplay({ required this.coinImg, required Vector2 position, required Vector2 size}) : 
  super(position: position, size: size);

  final TextPaint _textPaint = TextPaint(
    style: const TextStyle(
      fontSize: 22.0,
      fontFamily: 'Score',
      color: Color.fromARGB(255, 255, 255, 255),
    ),
  );

  @override
  FutureOr<void> onLoad() async {
    //Add coin 
    coin = SpriteComponent(sprite: coinImg, size: coinSize, position: Vector2(0,2.5));
    await add(coin!);

    //get DB
    db = game.database;
    await initializeCoinAmt();

    return super.onLoad();
  }

  //get the amt of coins at first
  Future<void> initializeCoinAmt() async {
    var dbList = await db.query('coins',);

    //set coinAmt correctly
    if (dbList.isEmpty) {
      coinAmt = 0;
    } else {
      coinAmt = dbList[0]['coin'] as int?;
    }
  }

  @override
  void render(Canvas canvas) {
    if (coin != null && coinAmt != null) {
      _textPaint.render(canvas, "$coinAmt", Vector2(coin!.size.x + 5, 5));
    }
    super.render(canvas);
  }
}