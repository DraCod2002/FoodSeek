import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:food_seek/presentation/pages/recipe_page.dart';
import 'package:food_seek/services/navigation_service.dart';
import 'package:food_seek/widgets/floating_menu.dart';
import 'package:food_seek/widgets/scan_overlay.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class CameraScreenFood extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraScreenFood({super.key, required this.cameras});

  @override
  State<CameraScreenFood> createState() => _CameraScreenFoodState();
}

class _CameraScreenFoodState extends State<CameraScreenFood> {
  late CameraController cameraController;
  late Future<void> cameraValue;
  bool isFlashOn = false;
  void startCamera(int camera) {
    cameraController = CameraController(
        widget.cameras[camera], ResolutionPreset.high,
        enableAudio: false);
    cameraValue = cameraController.initialize();
  }

  @override
  void initState() {
    startCamera(0);
    super.initState();
  }

  Future<void> _takePicture() async {
    try {
      final XFile image = await cameraController.takePicture();
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecipePage(imagePath: image.path),
        ),
      );
    } catch (e) {
      debugPrint("Error al tomar la foto: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: const Color(0x31FFFFFF),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: FloatingActionButton(
            backgroundColor: Colors.transparent,
            shape: const CircleBorder(),
            elevation: 0,
            onPressed: _takePicture,
            child: Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.7),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: Stack(children: [
          FutureBuilder(
            future: cameraValue,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return RotatedBox(
                  quarterTurns: 1,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: AspectRatio(
                          aspectRatio: cameraController.value.aspectRatio,
                          child: CameraPreview(cameraController),
                        ),
                      ),
                      ScanOverlay(),
                    ],
                  ),
                );
              } else {
                return Center(
                  child: LoadingAnimationWidget.flickr(
                    leftDotColor: Colors.orange,
                    rightDotColor: Colors.white,
                    size: 30,
                  ),
                );
              }
            },
          ),
          // Flash
          SafeArea(
              child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: EdgeInsets.only(right: 5, top: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                      onTap: () {
                        setState(() {
                          isFlashOn = !isFlashOn;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            color: const Color(0x25000000),
                            shape: BoxShape.circle),
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: isFlashOn
                              ? Icon(Icons.flash_on_rounded,
                                  color: Colors.white, size: 30)
                              : Icon(Icons.flash_off_rounded,
                                  color: Colors.white, size: 30),
                        ),
                      ))
                ],
              ),
            ),
          )),
          // Cerrar
          SafeArea(
              child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 6, top: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        Get.find<NavigationService>().updateIndex(0);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            color: const Color(0x25000000),
                            shape: BoxShape.circle),
                        child: Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(Icons.close,
                                color: Colors.white, size: 30)),
                      ))
                ],
              ),
            ),
          )),
          // Menú flotante encima del botón de captura
          FloatingMenu()
        ]));
  }
}