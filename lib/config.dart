import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Gradient;

double gameWidth = 375;
double gameHeight = 812;
double deviceWidth = 1;
double deviceHeight = 1;
double gameScale =0;

double fps = 60;

const double gravity = 95;
const double startingYForComponents = -75;

TextPaint textPaint = TextPaint(
  style: const TextStyle(
    fontSize: 30,
    fontFamily: 'Score',
    color: Color.fromARGB(255, 255, 255, 255),
  )
);
TextPaint textPaintBlack = TextPaint(
  style: const TextStyle(
    fontSize: 35,
    fontFamily: 'Score',
    color: Color.fromARGB(255, 0, 0, 0),
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

Paint orangeBg = Paint()
    ..color = const Color.fromRGBO(253, 111, 0, 100)
    ..style = PaintingStyle.fill;

//30 brush stroke