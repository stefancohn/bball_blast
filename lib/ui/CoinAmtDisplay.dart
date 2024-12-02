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
  final TextPaint _textPaintSmall = TextPaint(
    style: const TextStyle(
      fontSize: 15.0,
      fontFamily: 'Score',
      color: Color.fromARGB(255, 255, 255, 255),
      
    ),
  );

  @override
  FutureOr<void> onLoad() async {
    coinSize = Vector2(size.x/1.8, size.y);
    //Add coin 
    coin = SpriteComponent(sprite: coinImg, size: coinSize,);
    await add(coin!);

    coinText = TextComponent(
      text: coinAmt.toString(),
      textRenderer: (coinAmt < 99 ? _textPaint : _textPaintSmall),
    )
      ..anchor = Anchor.centerLeft
      ..size = Vector2(size.x*3/4, size.y)
      ..position = Vector2(coinSize.x*1.15, size.y/1.5);
    await add(coinText!);

    return super.onLoad();
  }

  @override
  void update(double dt) {
    //dynamically update text
    if (coinText != null && int.parse(coinText!.text) != coinAmt) {
      coinText!.text = coinAmt.toString();
      coinText!.position = Vector2(coinSize.x*1.15, size.y/2);
    }
    super.update(dt);
  }
}