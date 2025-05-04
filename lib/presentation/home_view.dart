import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:food_seek/services/navigation_service.dart';

class HomeView extends StatelessWidget {
  final List<CameraDescription> cameras;

  HomeView({super.key, required this.cameras});

  // Inicializa el servicio pasando las cámaras
  final NavigationService navigationService =
      Get.put(NavigationService(cameras: Get.arguments ?? []), permanent: true);

  @override
  Widget build(BuildContext context) {
    // Asegúrate de que navigationService esté usando las cámaras correctas
    if (Get.arguments == null) {
      Get.delete<NavigationService>();
      Get.put(NavigationService(cameras: cameras), permanent: true);
    }

    return Obx(() => Scaffold(
          body: navigationService.pages[navigationService.currentIndex.value],
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: Color(0xFFFFFFFF),
            currentIndex: navigationService.currentIndex.value,
            onTap: navigationService.updateIndex,
            items: [
              BottomNavigationBarItem(
                icon: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.receipt_long_outlined, size: 30),
                    Text(
                      'Recipes',
                      style: TextStyle(color: Color(0xDE0D0D0D)),
                    ),
                  ],
                ),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/icons/scan.png',
                      width: 33,
                      height: 33,
                    ),
                    Text(
                      'Scan food',
                      style: TextStyle(color: Color(0xDE0D0D0D)),
                    ),
                  ],
                ),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.bar_chart, size: 30),
                    Text(
                      'Progress',
                      style: TextStyle(color: Color(0xDE0D0D0D)),
                    ),
                  ],
                ),
                label: '',
              ),
            ],
            selectedItemColor: const Color.fromARGB(255, 0, 0, 0),
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
          ),
        ));
  }
}
