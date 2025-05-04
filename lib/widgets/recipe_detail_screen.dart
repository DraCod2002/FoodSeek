import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_seek/models/recipe_model.dart';
import 'package:food_seek/services/recipe_service.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String recipeId;
  final String? userId; // Ahora aceptamos el ID del usuario para buscar en su colección

  const RecipeDetailScreen({
    Key? key,
    required this.recipeId,
    this.userId, // Opcional para mantener compatibilidad con el código existente
  }) : super(key: key);

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final RecipeService _recipeService = RecipeService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Recipe? recipe;
  bool isLoading = true;
  bool isError = false;
  String errorMessage = '';
  bool isVideoVisible = false;
  bool isDescriptionExpanded = false;
  YoutubePlayerController? _youtubeController;

  @override
  void initState() {
    super.initState();
    _loadRecipe();
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    super.dispose();
  }

  Future<void> _loadRecipe() async {
    try {
      setState(() {
        isLoading = true;
        isError = false;
      });

      // Si tenemos userId, buscamos en la colección específica de ese usuario
      if (widget.userId != null) {
        DocumentSnapshot recipeDoc = await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection('recipes')
          .doc(widget.recipeId)
          .get();
          
        if (recipeDoc.exists) {
          setState(() {
            recipe = Recipe.fromMap(recipeDoc.data() as Map<String, dynamic>, recipeDoc.id);
            isLoading = false;

            // Inicializar controlador de YouTube si hay ID de video
            if (recipe!.youtubeVideoId != null) {
              _youtubeController = YoutubePlayerController(
                initialVideoId: recipe!.youtubeVideoId!,
                flags: const YoutubePlayerFlags(
                  autoPlay: false,
                  mute: false,
                  disableDragSeek: false,
                  loop: false,
                  isLive: false,
                  forceHD: false,
                  enableCaption: true,
                ),
              );
            }
          });
          return;
        }
      } else {
        // Si no tenemos userId, usamos el método original (para usuarios autenticados viendo sus propias recetas)
        final recipeData = await _recipeService.getRecipe(widget.recipeId);
        
        if (recipeData != null) {
          setState(() {
            recipe = recipeData;
            isLoading = false;

            // Inicializar controlador de YouTube si hay ID de video
            if (recipe!.youtubeVideoId != null) {
              _youtubeController = YoutubePlayerController(
                initialVideoId: recipe!.youtubeVideoId!,
                flags: const YoutubePlayerFlags(
                  autoPlay: false,
                  mute: false,
                  disableDragSeek: false,
                  loop: false,
                  isLive: false,
                  forceHD: false,
                  enableCaption: true,
                ),
              );
            }
          });
          return;
        }
      }

      // Si llegamos aquí, no se encontró la receta
      setState(() {
        isLoading = false;
        isError = true;
        errorMessage = "No se pudo encontrar la receta";
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        isError = true;
        errorMessage = "Error al cargar la receta: ${e.toString()}";
      });
    }
  }

  Widget _buildNutritionInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          const Text(
            'Información Nutricional',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _nutritionItem(
                  'Calorías', '${recipe!.calories}', 'kcal', Colors.orange),
              _nutritionItem('Proteínas', '${recipe!.protein}g',
                  '${recipe!.proteinPercentage}%', Colors.green),
              _nutritionItem('Grasas', '${recipe!.fat}g',
                  '${recipe!.fatPercentage}%', Colors.redAccent),
              _nutritionItem('Carbohidratos', '${recipe!.carbs}g',
                  '${recipe!.carbsPercentage}%', Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _nutritionItem(
      String title, String value, String subtitle, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getNutritionIcon(title),
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  IconData _getNutritionIcon(String title) {
    switch (title) {
      case 'Calorías':
        return Icons.local_fire_department;
      case 'Proteínas':
        return Icons.fitness_center;
      case 'Grasas':
        return Icons.opacity;
      case 'Carbohidratos':
        return Icons.grain;
      default:
        return Icons.info;
    }
  }

  Widget _buildIngredientsList() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          const Text(
            'Ingredientes',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: recipe!.ingredients.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        recipe!.ingredients[index],
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreparationSteps() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          const Text(
            'Preparación',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: recipe!.preparation.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        recipe!.preparation[index],
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildYoutubeVideo() {
    if (recipe!.youtubeVideoId == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
          const Text(
            'Video Tutorial',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: isVideoVisible
                ? YoutubePlayer(
                    controller: _youtubeController!,
                    showVideoProgressIndicator: true,
                    progressIndicatorColor: Colors.amber,
                    progressColors: const ProgressBarColors(
                      playedColor: Colors.amber,
                      handleColor: Colors.amberAccent,
                    ),
                    onReady: () {
                      _youtubeController!.addListener(() {});
                    },
                  )
                : GestureDetector(
                    onTap: () {
                      setState(() {
                        isVideoVisible = true;
                      });
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: NetworkImage(
                                'https://img.youtube.com/vi/${recipe!.youtubeVideoId}/0.jpg',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF4FF),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            )
          : (isError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 70,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage,
                        style: const TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                        ),
                        child: const Text('Volver',
                            style: TextStyle(color: Colors.black)),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    // AppBar con imagen
                    SliverAppBar(
                      expandedHeight: 250,
                      floating: false,
                      pinned: true,
                      backgroundColor: Colors.transparent,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Image.network(
  recipe!.imageUrl, // Ahora imageUrl es una URL de Firebase Storage
  fit: BoxFit.cover,
  loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: CircularProgressIndicator(
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded / 
                loadingProgress.expectedTotalBytes!
              : null,
          color: Colors.amber,
        ),
      ),
    );
  },
  errorBuilder: (context, error, stackTrace) {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.image_not_supported,
          size: 60,
          color: Colors.grey,
        ),
      ),
    );
  },
)
                      ),
                      leading: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0x91FFFFFF),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          color: const Color(0xFF212121),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      actions: [
                        Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0x91FFFFFF),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.favorite_border),
                            color: const Color(0xFF212121),
                            onPressed: () {
                              // Implementar funcionalidad de favoritos
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Añadido a favoritos'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    // Contenido de la receta
                    SliverToBoxAdapter(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFEDF4FF),
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(30)),
                        ),
                        transform: Matrix4.translationValues(0, -30, 0),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Título y detalles
                            Container(
                              padding: const EdgeInsets.all(16),
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
                                  Text(
                                    recipe!.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          recipe!.category,
                                          style: const TextStyle(
                                            color: Colors.purple,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(Icons.timer,
                                          color: Colors.grey[600], size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${recipe!.cookingTime} min',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(Icons.restaurant,
                                          color: Colors.grey[600], size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        recipe!.cuisine,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Descripción',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        isDescriptionExpanded =
                                            !isDescriptionExpanded;
                                      });
                                    },
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          recipe!.description,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[700],
                                          ),
                                          maxLines:
                                              isDescriptionExpanded ? null : 3,
                                          overflow: isDescriptionExpanded
                                              ? null
                                              : TextOverflow.ellipsis,
                                        ),
                                        if (recipe!.description.length > 100)
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              isDescriptionExpanded
                                                  ? 'Ver menos'
                                                  : 'Ver más',
                                              style: const TextStyle(
                                                color: Colors.amber,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Información nutricional
                            _buildNutritionInfo(),
                            const SizedBox(height: 16),

                            // Video de YouTube si existe
                            if (recipe!.youtubeVideoId != null) ...[
                              _buildYoutubeVideo(),
                              const SizedBox(height: 16),
                            ],

                            // Lista de ingredientes
                            _buildIngredientsList(),
                            const SizedBox(height: 16),

                            // Pasos de preparación
                            _buildPreparationSteps(),
                          ],
                        ),
                      ),
                    ),
                  ],
                )),
    );
  }
}
