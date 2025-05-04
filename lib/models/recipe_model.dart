import 'package:cloud_firestore/cloud_firestore.dart';

class Recipe {
  final String id;
  final String name;
  final String category;
  final int calories;
  final int protein;
  final int proteinPercentage;
  final int fat;
  final int fatPercentage;
  final int carbs;
  final int carbsPercentage;
  final int cookingTime;
  final String cuisine;
  final String description;
  final List<String> ingredients;
  final List<String> preparation;
  final String imageUrl;
  final String? youtubeVideoId;
  final DateTime createdAt;
  final bool isFavorite; // Añadido campo isFavorite
  final String? userId; // ID del usuario que creó la receta
  final String? userName; // Nombre del usuario que creó la receta
  final String? storagePath; // Ruta de almacenamiento de la imagen

  Recipe({
    required this.id,
    required this.name,
    required this.category,
    required this.calories,
    required this.protein,
    required this.proteinPercentage,
    required this.fat,
    required this.fatPercentage,
    required this.carbs,
    required this.carbsPercentage,
    required this.cookingTime,
    required this.cuisine,
    required this.description,
    required this.ingredients,
    required this.preparation,
    required this.imageUrl,
    this.youtubeVideoId,
    required this.createdAt,
    this.isFavorite = false, // Valor por defecto
    this.userId,
    this.userName,
    this.storagePath,
  });

  // Convertir de Firestore a objeto Recipe
  factory Recipe.fromMap(Map<String, dynamic> map, String id) {
    return Recipe(
      id: id,
      name: map['name'] ?? 'Receta sin nombre',
      category: map['category'] ?? 'Sin categoría',
      calories: map['calories'] ?? 0,
      protein: map['protein'] ?? 0,
      proteinPercentage: map['proteinPercentage'] ?? 0,
      fat: map['fat'] ?? 0,
      fatPercentage: map['fatPercentage'] ?? 0,
      carbs: map['carbs'] ?? 0,
      carbsPercentage: map['carbsPercentage'] ?? 0,
      cookingTime: map['cookingTime'] ?? 0,
      cuisine: map['cuisine'] ?? 'Internacional',
      description: map['description'] ?? 'Sin descripción',
      ingredients: List<String>.from(map['ingredients'] ?? []),
      preparation: List<String>.from(map['preparation'] ?? []),
      imageUrl: map['imageUrl'] ?? '',
      youtubeVideoId: map['youtubeVideoId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isFavorite: map['isFavorite'] ?? false,
      userId: map['userId'],
      userName: map['userName'],
      storagePath: map['storagePath'],
    );
  }

  // Convertir de objeto Recipe a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'calories': calories,
      'protein': protein,
      'proteinPercentage': proteinPercentage,
      'fat': fat,
      'fatPercentage': fatPercentage,
      'carbs': carbs,
      'carbsPercentage': carbsPercentage,
      'cookingTime': cookingTime,
      'cuisine': cuisine,
      'description': description,
      'ingredients': ingredients,
      'preparation': preparation,
      'imageUrl': imageUrl,
      'youtubeVideoId': youtubeVideoId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isFavorite': isFavorite,
      'userId': userId,
      'userName': userName,
      'storagePath': storagePath,
    };
  }
}