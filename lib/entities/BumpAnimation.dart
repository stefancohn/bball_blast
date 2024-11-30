// ignore: file_names
import 'dart:async';
import 'dart:ui';

import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/Backend.dart';
import 'package:bball_blast/entities/Ball.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flame_noise/flame_noise.dart';
import 'package:flutter/material.dart';

class BumpAnimation extends Component with HasGameRef<BBallBlast>, HasPaint {
  Ball ball;

  BumpAnimation({required this.ball});

  @override
  FutureOr<void> onLoad() {
    //set paint color based on useri nput
    paint = Paint()..color = Colors.white;
    if (bumpPath == "orange") {
      paint.color = Colors.orange;
    } else if (bumpPath == "blue") {
      paint.color = Colors.blue;
    } else if (bumpPath == "green") {
      paint.color = Colors.green;
    } else if (bumpPath == "pink") {
      paint.color = Colors.pink;
    }
    
    return super.onLoad();
  }

  //make camera shake, add falling particles
  Future<void> wallBumpAnimation({required bool isLeft}) async {
    //MAKE SCREEN SHAKE
    game.camera.viewfinder.add(
      MoveEffect.by(
        Vector2(5, 5),
        NoiseEffectController(duration: 0.2, noise: PerlinNoise(frequency: 400)),
      ),
    );


    //PARTICLE
    //vars for particle
    int particleCount = 10;
    double xPosForParticle;
    List<Vector2> accelForParticle = List.filled(10, Vector2.all(0)); 
    for(int i =0; i < particleCount; i++) {accelForParticle[i] = Vector2.random()..scale(100);} //set 10 diff vals

    //Set vars correctly depending on which wall
    if (isLeft) {
      xPosForParticle = BBallBlast.gameplay.wallLeft.body.position.x;
    } else {
      xPosForParticle = BBallBlast.gameplay.wallRight.body.position.x;
      for (int i=0;i<particleCount;i++) {accelForParticle[i].x*=-1;}//change x direction if on right
    }

    //our particle 
    final particle = ParticleSystemComponent(
      particle: Particle.generate(
        count: particleCount,  // Number of particles
        lifespan: 2,  // How long the particles last
        generator: (i) => AcceleratedParticle(
          acceleration: accelForParticle.elementAt(i),
          position: Vector2(xPosForParticle, ball.body.position.y ),  // Where the impact happened
          child: ComputedParticle(
            renderer: (canvas, particle) {
              //so the color slowly fades away
              paint.color = paint.color.withOpacity(1-particle.progress);

              //our circle for particle
              canvas.drawCircle(
                Offset.zero,
                1,
                paint
              );
            }
          ),
        ),
      ),
    );

    game.world.add(particle);
  }
}