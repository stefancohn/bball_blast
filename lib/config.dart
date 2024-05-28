import 'package:flame/game.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';

double gameWidth = 720;
double gameHeight = 1280;
const double gravity = 95;

TextPaint textPaint = TextPaint(
  style: TextStyle(
    fontSize: 48.0,
    fontFamily: 'Arial',
    color: BasicPalette.blue.color,
  ),
);
