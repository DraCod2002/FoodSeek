import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:food_seek/presentation/cameraFood/camera_screen_food.dart';
import 'package:food_seek/presentation/screens/favorities_screen.dart';
import 'package:get/get.dart';
import 'package:food_seek/presentation/screens/home_screen.dart';

class NavigationService extends GetxService {
  var currentIndex = 0.obs;
  var previusIndex = 0.obs;
  final List<CameraDescription> cameras;
  late final List<Widget> pages;
  
  // Constructor que recibe cámaras y las usa para inicializar las páginas
  NavigationService({required this.cameras}) {
    // Inicializar las páginas inmediatamente en el constructor
    pages = [
      HomeScreen(cameras: cameras),
      Placeholder(color: Colors.white,),
      FavoritesScreen()
    ];
  }

   void updateIndex(int index) {
    previusIndex.value = currentIndex.value;
    currentIndex.value = index;
    if (index == 1) {
      Get.to(() => CameraScreenFood(cameras: cameras),
      );  
    }
  }
  
  // Volver a la página anterior
  void backToPrevPage() {
    Get.back();
  }
}