import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart' hide Gradient;

double gameWidth = 375;
double gameHeight = 812;
double deviceWidth = 0;
double deviceHeight = 0;
double gameScale =0;
const double gravity = 95;

TextPaint textPaint = TextPaint(
  style: const TextStyle(
    fontSize: 48.0,
    fontFamily: 'Score',
    color: Color.fromARGB(255, 255, 255, 255),
  )
);

double outlineWidth = 3;
double circleRadius = 4;
Paint outline = Paint()
    ..color = const Color.fromARGB(255, 0, 0, 0)
    ..strokeWidth = outlineWidth
    ..style = PaintingStyle.stroke;

Paint insideWhite = Paint() 
  ..color = const Color.fromARGB(255, 255, 255, 255)
  ..style = PaintingStyle.fill;

//30 brush stroke