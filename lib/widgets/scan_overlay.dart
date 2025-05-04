import 'package:flutter/material.dart';

class ScanOverlay extends StatelessWidget {
  const ScanOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        width: 320, 
        height: 315,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: ScanCorner(alignment: Alignment.topLeft),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: ScanCorner(alignment: Alignment.topRight),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: ScanCorner(alignment: Alignment.bottomLeft),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: ScanCorner(alignment: Alignment.bottomRight),
            ),
          ],
        ),
      ),
    );
  }
}

class ScanCorner extends StatelessWidget {
  final Alignment alignment;

  const ScanCorner({super.key, required this.alignment});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
       borderRadius: BorderRadius.circular(2.5),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            top: alignment == Alignment.topLeft || alignment == Alignment.topRight
                ? BorderSide(color: Colors.white70, width: 4)
                : BorderSide.none,
            left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft
                ? BorderSide(color: Colors.white70, width: 4)
                : BorderSide.none,
            bottom: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight
                ? BorderSide(color: Colors.white70, width: 4)
                : BorderSide.none,
            right: alignment == Alignment.topRight || alignment == Alignment.bottomRight
                ? BorderSide(color: Colors.white70, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
