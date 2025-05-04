import 'package:flutter/material.dart';

class ImageScannerAnimation extends AnimatedWidget {
  final bool stopped;
  final double width;

  const ImageScannerAnimation({
    Key? key,
    required this.stopped,
    required this.width,
    required Animation<double> animation,
  }) : super(key: key, listenable: animation);

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = listenable as Animation<double>;
    // Calculate position based on the container height
    final scannerPosition = animation.value * width;
    
    // Define colors for the scanner effect
    Color color1 = Colors.amber.withOpacity(0.5);
    Color color2 = Colors.amber.withOpacity(0.0);

    if (animation.status == AnimationStatus.reverse) {
      color1 = Colors.amber.withOpacity(0.0);
      color2 = Colors.amber.withOpacity(0.5);
    }

    return Positioned(
      top: scannerPosition,
      left: 0,
      right: 0,
      child: Opacity(
        opacity: stopped ? 0.0 : 1.0,
        child: Container(
          height: 4.0, // Thin line for scanner effect
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.3),
                blurRadius: 8.0,
                spreadRadius: 4.0,
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: const [0.1, 0.9],
              colors: [color1, color2],
            ),
          ),
        ),
      ),
    );
  }
}