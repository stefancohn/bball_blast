import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';

class GradientBackground extends RectangleComponent {
  Paint? gradientPaint;

  List<Color> colors;
  List<double> colorStops = [0, 0.5, 1];

  double? fadeOutSpeed;
  bool fadeOutCalled = false;
  
  GradientBackground({
    required this.colors, required Vector2 super.size, required Vector2 super.position, super.anchor, super.priority = -1, this.fadeOutSpeed
  });

  @override
  FutureOr<void> onLoad() {
    gradientPaint = Paint()
    ..shader = Gradient.linear(
      Offset.zero,
      Offset(0, position.y),
      colors,
      colorStops,
      TileMode.mirror,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    _animateGradient(dt);

    if (fadeOutCalled) {
      _fadeOut((fadeOutSpeed!/dt) * dt);
    }
  }


  //essentially create our own animation loop :D 
  bool insertNewFlag = false;
  void _animateGradient(double dt) {
    //increase the colorStop
    for (int i =0; i < colorStops.length; i++) {
      colorStops[i] += 0.3*dt; 
    }

    //once a color reaches a color beyond "the end" we 
    //add that same color to the beginning at the list at a 
    //position off the "gradient" and we have a flag so that 
    //this function doesn't repeatedly get called
    var lastColor = colors[colors.length-1];
    var lastStop = colorStops[colorStops.length-1];
    if (lastStop >= 1 && !insertNewFlag) {
      colorStops.insert(0, -0.5);
      colors.insert(0, lastColor);
      insertNewFlag = true;
    }
    
    //once the second to last color reaches "the end" we have 
    //to calibrate our list by removing the previous last color
    //and shifting the colors and stops one to the right!
    var secondToLastStop = colorStops[colorStops.length-2];
    if (secondToLastStop >= 1) {
      colorStops.remove(lastStop);
      colors.remove(lastColor);
      var lastElement = colors.removeLast();
      colors.insert(0, lastElement);
      insertNewFlag = false;
    }

    //must recreate gradient paint and reassign ti to 
    //logoGradientBackground
    gradientPaint = Paint()
      ..shader = Gradient.linear(
        Offset.zero,
        const Offset(0, 350),
        colors,
        colorStops,
        TileMode.clamp
      );

    super.paint = gradientPaint!;
  }

  //fade out function inner workings
  double alpha = 255;
  void _fadeOut(double duration) {
    for (int i =0; i < colors.length; i++) {
      if (alpha > 0) {
        alpha -= duration;
      } else {
        alpha = 0;
      }
      colors[i] = Color.fromARGB(alpha.round(), colors[i].red, colors[i].green, colors[i].blue);
    }
  }

  //called from the outside to intialize the fade out
  void fadeOut() {
    fadeOutCalled = true;
  }

  Paint getSuperPaint() {
    return super.paint; 
  }
}