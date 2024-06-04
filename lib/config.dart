import 'package:flame/game.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';

double gameWidth = 375;
double gameHeight = 812;
double deviceWidth = 0;
double deviceHeight = 0;
double gameScale =0;
const double gravity = 95;

TextPaint textPaint = TextPaint(
  style: TextStyle(
    fontSize: 48.0,
    fontFamily: 'Arial',
    color: BasicPalette.blue.color,
  ),
);

//30 brush stroke