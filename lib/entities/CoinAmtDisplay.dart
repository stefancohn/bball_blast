import 'dart:async';
import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/Backend.dart';
import 'package:flutter/material.dart' hide Gradient;
import 'package:flame/components.dart';

class CoinAmtDisplay extends PositionComponent with HasGameRef<BBallBlast> {
  Sprite coinImg;
  Vector2 coinSize = Vector2(30,30);
  SpriteComponent? coin;
  TextComponent? coinText;


  CoinAmtDisplay({ required this.coinImg, required Vector2 position, required Vector2 size}) : 
  super(position: position, size: size);

  final TextPaint _textPaint = TextPaint(
    style: const TextStyle(
      fontSize: 25.0,
      fontFamily: 'Score',
      color: Color.fromARGB(255, 255, 255, 255),
      
    ),
  );

  @override
  FutureOr<void> onLoad() async {
    coinSize = Vector2(size.x/2, size.y);
    //Add coin 
    coin = SpriteComponent(sprite: coinImg, size: coinSize,);
    await add(coin!);

    coinText = TextComponent(
      text: coinAmt.toString(),
      textRenderer: _textPaint,
      anchor: Anchor.topLeft,
    )
      ..size = Vector2(size.x*3/4, size.y)
      ..position = Vector2(coinSize.x*1.1, size.y/3);
    await add(coinText!);

    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (coinText != null ) {
      coinText!.text = coinAmt.toString();
    }
    super.update(dt);
  }
}