// ignore: file_names
import 'dart:async';
import 'dart:ui';

import 'package:bball_blast/BBallBlast.dart';
import 'package:bball_blast/entities/Ball.dart';
import 'package:flame/components.dart';

class TrailEffect extends Component with HasPaint, HasGameRef<BBallBlast>{
  final trail = <Offset>[];
  final _trailLength = 20; 
  final _minSpeed = 15;

  Ball ball;

  TrailEffect({required this.ball});

  @override
  FutureOr<void> onLoad() {
    paint.color = (const Color.fromARGB(255, 255, 255, 255));
    paint.strokeWidth = 4.0;
      
    super.onLoad();
  }

  @override
  void update(double dt) {
    //make sure the ball is going fast enough to add a point to the trail
    bool goingFastEnough = (ball.body.linearVelocity.x.abs() > _minSpeed || ball.body.linearVelocity.y.abs() > _minSpeed);
    if (goingFastEnough && !BBallBlast.gameplay.ballScored) {
      final trailPoint = (ball.body.position).toOffset();
      trail.add(trailPoint);
    } 

    //remove pieces of trail if ball is not fast enough or enough points in path
    if (trail.isNotEmpty && (trail.length > _trailLength || !goingFastEnough || BBallBlast.gameplay.ballScored)) {
      trail.removeAt(0);
    }

    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    //render our trail with a fading effect 
    for (int i = 0; i < trail.length; i++) {
      final point = trail[i];
      paint.color = paint.color.withAlpha(((i / (trail.length+10)) * 255).toInt());
      canvas.drawCircle(point, 2.0, paint);
    }
  }
}