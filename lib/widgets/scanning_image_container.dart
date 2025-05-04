import 'dart:io';
import 'package:flutter/material.dart';
import 'package:food_seek/widgets/image_scanner_animation.dart';

class ScanningImageContainer extends StatefulWidget {
  final String imagePath;
  final bool isAnalyzing;
  final Widget? child;

  const ScanningImageContainer({
    Key? key,
    required this.imagePath,
    required this.isAnalyzing,
    this.child,
  }) : super(key: key);

  @override
  State<ScanningImageContainer> createState() => _ScanningImageContainerState();
}

class _ScanningImageContainerState extends State<ScanningImageContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _animationStopped = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Add listener to control the animation cycling
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        animateScanAnimation(true);
      } else if (status == AnimationStatus.dismissed) {
        animateScanAnimation(false);
      }
    });

    // Start animation if initially analyzing
    if (widget.isAnalyzing) {
      animateScanAnimation(false);
    }
  }

  @override
  void didUpdateWidget(ScanningImageContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle changes in isAnalyzing state
    if (widget.isAnalyzing != oldWidget.isAnalyzing) {
      if (widget.isAnalyzing) {
        _animationStopped = false;
        animateScanAnimation(false);
      } else {
        _animationStopped = true;
        _animationController.stop();
      }
    }
  }

  void animateScanAnimation(bool reverse) {
    if (mounted && widget.isAnalyzing) {
      if (reverse) {
        _animationController.reverse(from: 1.0);
      } else {
        _animationController.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        Image.file(
          File(widget.imagePath),
          fit: BoxFit.cover,
        ),
        
        // Dark overlay for better visibility
        Container(
          color: Colors.black.withOpacity(0.6),
        ),
        
        // Scanner animation
        if (widget.isAnalyzing)
          ImageScannerAnimation(
            stopped: _animationStopped,
            width: MediaQuery.of(context).size.height,
            animation: _animationController,
          ),
        
        // Child widget (loading indicator, text, etc.)
        if (widget.child != null) widget.child!,
      ],
    );
  }
}