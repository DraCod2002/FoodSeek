import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_seek/widgets/recipe_detail_screen.dart';

class PublicRecipesScreen extends StatefulWidget {
  const PublicRecipesScreen({super.key});

  @override
  State<PublicRecipesScreen> createState() => _PublicRecipesScreenState();
}

class _PublicRecipesScreenState extends State<PublicRecipesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Map<String, dynamic>> recipes = [];                                                                                                                                                                                                                                          
  bool isLoading = true;
  String? searchQuery;
  String currentCategory = 'All';
  
  // Categorías predefinidas para filtrar recetas
  final List<String> categories = [
    'All',
    'Breakfast',
    'Lunch',
    'Dinner',
    'Dessert',
    'Pasta',
    'Rice',
    'Soup',
    'Salad',
    'Vegan',
    'Meat'
  ];

  @override
  void initState() {
    super.initState();
    // Cargar todas las recetas al iniciar
    loadRecipes();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  // Método para cargar recetas desde Firebase
  Future<void> loadRecipes() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      // Consulta para obtener todas las recetas de todos los usuarios
      QuerySnapshot allUsersSnapshot = await _firestore.collection('users').get();
      
      List<Map<String, dynamic>> fetchedRecipes = [];
      
      // Iteramos sobre todos los usuarios
      for (var userDoc in allUsersSnapshot.docs) {
        // Para cada usuario, obtenemos su colección de recetas
        QuerySnapshot recipesSnapshot = await userDoc.reference
            .collection('recipes')
            .get();
        
        // Iteramos sobre todas las recetas del usuario
        for (var recipeDoc in recipesSnapshot.docs) {
          Map<String, dynamic> recipeData = recipeDoc.data() as Map<String, dynamic>;
          
          // Añadimos el ID del documento y el ID del usuario para referencia
          recipeData['id'] = recipeDoc.id;
          recipeData['userId'] = userDoc.id;
          
          // Filtramos por categoría si es necesario
          if (currentCategory == 'All' || 
              recipeData['category']?.toLowerCase() == currentCategory.toLowerCase()) {
            
            // Filtramos por búsqueda si hay una consulta
            if (searchQuery == null || 
                searchQuery!.isEmpty || 
                recipeData['name'].toString().toLowerCase().contains(searchQuery!.toLowerCase())) {
              
              fetchedRecipes.add(recipeData);
            }
          }
        }
      }
      
      setState(() {
        recipes = fetchedRecipes;
        isLoading = false;
      });
      
    } catch (e) {
      print('Error al cargar recetas: $e');
      setState(() {
        isLoading = false;
      });
      
      // Mostrar mensaje de error si algo sale mal
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al cargar las recetas. Intenta nuevamente.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Método para buscar recetas
  void searchRecipes(String query) {
    setState(() {
      searchQuery = query;
    });
    loadRecipes();
  }
  
  // Método para cambiar la categoría
  void changeCategory(String category) {
    setState(() {
      currentCategory = category;
    });
    loadRecipes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Explorar Recetas',
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de búsqueda
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar recetas',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onSubmitted: (value) {
                searchRecipes(value);
              },
            ),
          ),
          
          // Categorías horizontales
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = currentCategory == category;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: GestureDetector(
                    onTap: () => changeCategory(category),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.orange : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          category,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Título de categoría actual
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              currentCategory == 'All' ? 'Todas las Recetas' : 'Recetas de $currentCategory',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Lista de recetas
          Expanded(
            child: _buildRecipesList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecipesList() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }
    
    if (recipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.no_food,
              size: 72,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery != null && searchQuery!.isNotEmpty
                  ? 'No se encontraron recetas para "$searchQuery"'
                  : 'No hay recetas disponibles en esta categoría',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecipeDetailScreen(
                  recipeId: recipe['id'],
                  userId: recipe['userId'], // Pasamos el ID del usuario para buscar en su colección
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen de la receta
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    recipe['imageUrl'] ?? 'https://via.placeholder.com/400x300?text=No+Image',
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 180,
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / 
                                  loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.orange,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        color: Colors.grey[200],
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Información de la receta
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              recipe['name'] ?? 'Sin nombre',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (recipe['youtubeVideoId'] != null)
                            const Icon(
                              Icons.play_circle_filled,
                              color: Colors.redAccent,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.timer, color: Colors.grey, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${recipe['cookingTime'] ?? 0} min',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.restaurant, color: Colors.grey, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                recipe['cuisine'] ?? 'Variada',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              recipe['category'] ?? 'General',
                              style: const TextStyle(
                                color: Colors.purple,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Información nutricional básica
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildNutritionBadge('🔥', '${recipe['calories'] ?? 0} kcal'),
                          _buildNutritionBadge('🥩', '${recipe['protein'] ?? 0} g'),
                          _buildNutritionBadge('🍞', '${recipe['carbs'] ?? 0} g'),
                          _buildNutritionBadge('🧈', '${recipe['fat'] ?? 0} g'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildNutritionBadge(String emoji, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}