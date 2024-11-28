import 'dart:async';
import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/Backend.dart';
import 'package:flutter/material.dart' hide Gradient;
import 'package:flame/components.dart';

class CoinAmtDisplay extends PositionComponent with HasGameRef<BBallBlast> {
  Sprite coinImg;
  Vector2 coinSize = Vector2(30,30);
  SpriteComponent? coin;


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

    return super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    if (coin != null) {
      _textPaint.render(canvas, "$coinAmt", Vector2(coin!.size.x + 5, 5));
    }
    super.render(canvas);
  }
}