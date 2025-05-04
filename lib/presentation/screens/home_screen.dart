import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:food_seek/models/recipe_model.dart';
import 'package:food_seek/presentation/cameraFood/camera_screen_food.dart';
import 'package:food_seek/services/auth_service.dart';
import 'package:food_seek/services/recipe_service.dart';
import 'package:food_seek/widgets/recipe_detail_screen.dart';
import 'package:food_seek/widgets/user_recipe_card.dart';
import 'package:get/get.dart';

class HomeScreen extends StatelessWidget {
  final List<CameraDescription> cameras;
  const HomeScreen({super.key, required this.cameras});

  // Método para generar un color aleatorio consistente basado en el nombre del usuario
  Color getColorFromName(String name) {
    if (name.isEmpty) return Colors.blue;
    final int hash = name.codeUnitAt(0) % 5;
    final colors = [
      Colors.red.shade400,
      Colors.green.shade400,
      Colors.purple.shade400,
      Colors.orange.shade400,
      Colors.teal.shade400,
    ];
    return colors[hash];
  }

  // Método para obtener el avatar del usuario
  Widget getUserAvatar(AuthService authService) {
    final user = authService.getCurrentUser();
    final String userName = authService.getUserName();

    if (user != null && user.photoURL != null) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(user.photoURL!),
      );
    } else {
      return CircleAvatar(
        radius: 30,
        backgroundColor: getColorFromName(userName),
        child: Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    AuthService authService = AuthService();
    RecipeService recipeService = RecipeService();

    return Scaffold(
      backgroundColor: const Color(0xFFEDF4FF),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Header fijo con perfil y notificaciones
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              getUserAvatar(authService),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Hello,'.tr,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 24,
                                        ),
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        authService.getUserName(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 24,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Check Amazing Recipes...'.tr,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                      Icons.notifications_none_outlined,
                                      color: Colors.black),
                                  iconSize: 30,
                                  onPressed: () {},
                                ),
                              ),
                              // Red notification dot
                              Positioned(
                                right: 11,
                                top: 11,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 10,
                                    minHeight: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // Contenido scrollable desde el banner AR Scanner
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // AR Scanner banner
                          Container(
                            height: 160,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(20),
                              image: DecorationImage(
                                image:
                                    AssetImage('assets/images/header_food.jpg'),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  Colors.black.withOpacity(0.5),
                                  BlendMode.darken,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Get Your Recipes'.tr,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      Text(
                                        'Easier With AR'.tr,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      Text(
                                        'Food Scanner'.tr,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Get.to(() =>
                                          CameraScreenFood(cameras: cameras));
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.qr_code_scanner,
                                            color: Colors.black),
                                        SizedBox(width: 4),
                                        Text(
                                          'Scan Now'.tr,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Recipes section with count
                          StreamBuilder<List<Recipe>>(
                            stream: recipeService.getUserRecipes(),
                            builder: (context, snapshot) {
                              int recipeCount = 0;
                              if (snapshot.hasData) {
                                recipeCount = snapshot.data!.length;
                              }

                              return Row(
                                children: [
                                  const Text(
                                    'My recipes',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '($recipeCount)',
                                    style: const TextStyle(
                                      color: Color.fromARGB(255, 199, 150, 2),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 16),

                          // Lista de recetas del usuario
                          StreamBuilder<List<Recipe>>(
                            stream: recipeService.getUserRecipes(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.orange),
                                );
                              }

                              if (snapshot.hasError) {
                                return Center(
                                  child: Text('Error: ${snapshot.error}'),
                                );
                              }

                              final recipes = snapshot.data ?? [];

                              if (recipes.isEmpty) {
                                return Container(
                                  margin: EdgeInsets.only(
                                      bottom: 120 + bottomInset),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // Contenedor con imágenes y diseño atractivo
                                        Container(
                                          padding: const EdgeInsets.all(40),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.05),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            children: [
                                              Container(
                                                width: 120,
                                                height: 120,
                                                decoration: BoxDecoration(
                                                  color: Colors.orange
                                                      .withOpacity(0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.restaurant_menu,
                                                  size: 60,
                                                  color: Colors.orange,
                                                ),
                                              ),
                                              const SizedBox(height: 20),
                                              Text(
                                                '¡Comienza tu aventura culinaria!',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey[800],
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 12),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20),
                                                child: Text(
                                                  'Escanea ingredientes o platillos para descubrir deliciosas recetas personalizadas',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    color: Colors.grey[600],
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              const SizedBox(height: 24),

                                              // Estadísticas de ejemplo para que no se vea vacío
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  _buildStatItem(
                                                      context,
                                                      '0',
                                                      'Recetas',
                                                      Icons.food_bank),
                                                  Container(
                                                    height: 40,
                                                    width: 1,
                                                    color: Colors.grey[300],
                                                    margin: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 15),
                                                  ),
                                                  _buildStatItem(
                                                      context,
                                                      '0',
                                                      'Favoritos',
                                                      Icons.favorite),
                                                ],
                                              ),

                                              const SizedBox(height: 30),
                                              Image.asset(
                                                'assets/icons/arrow_scan.png',
                                                width: 45,
                                                height: 45,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                padding: EdgeInsets.only(
                                  bottom: 120 + bottomInset,
                                ),
                                itemCount: recipes.length,
                                itemBuilder: (context, index) {
                                  final recipe = recipes[index];
                                  return Dismissible(
                                    key: Key(recipe.id),
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      color: Colors.red,
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                      ),
                                    ),
                                    direction: DismissDirection.endToStart,
                                    confirmDismiss: (direction) async {
                                      return await showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Eliminar Receta'),
                                          content: Text(
                                              '¿Estás seguro de eliminar "${recipe.name}"?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(false),
                                              child: const Text('Cancelar'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(true),
                                              child: const Text(
                                                'Eliminar',
                                                style: TextStyle(
                                                    color: Colors.red),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    onDismissed: (direction) {
                                      recipeService.deleteRecipe(recipe.id);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Receta "${recipe.name}" eliminada'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    },
                                    child: UserRecipeCard(
                                      recipe: recipe,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                RecipeDetailScreen(
                                                    recipeId: recipe.id),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildStatItem(
    BuildContext context, String value, String label, IconData icon) {
  return Column(
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.amber,
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
    ],
  );
}
