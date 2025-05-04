import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:food_seek/secrets.dart';
import 'package:food_seek/services/recipe_service.dart';
import 'package:food_seek/widgets/scanning_image_container.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';

class RecipePage extends StatefulWidget {
  final String imagePath;
  const RecipePage({super.key, required this.imagePath});

  @override
  State<RecipePage> createState() => _RecipePageState();
}

class _RecipePageState extends State<RecipePage> {
  bool isLoading = true;
  bool isError = false;
  String errorMessage = '';
  Map<String, dynamic> recipeData = {};
  String? youtubeVideoId;
  bool isVideoVisible = false;
  bool isDescriptionExpanded = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _analyzeImage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

 Future<void> _analyzeImage() async {
  try {
    setState(() {
      isLoading = true;
      isError = false;
    });

    // Convertir imagen a base64
    final bytes = await File(widget.imagePath).readAsBytes();
    final base64Image = base64Encode(bytes);
    
    // Enviar imagen a OpenAI para análisis
    final recipeInfo = await _sendToOpenAI(base64Image);
    
    if (recipeInfo == null || recipeInfo.isEmpty || recipeInfo.containsKey('error')) {
      setState(() {
        isLoading = false;
        isError = true;
        errorMessage = recipeInfo?.containsKey('error') ?? false
            ? recipeInfo!['error'] 
            : "No se detectó una receta en esta imagen";
      });
      return;
    }

    // Buscar video en YouTube
    if (recipeInfo.containsKey('name')) {
      final videoId = await _searchYouTubeVideo(recipeInfo['name']);
      if (videoId == null) {
        final alternativeVideoId = await _searchAlternativeVideo(recipeInfo['category'], recipeInfo['cuisine']);
        recipeInfo['youtubeVideoId'] = videoId ?? alternativeVideoId;
      } else {
        recipeInfo['youtubeVideoId'] = videoId;
      }
    }

    try {
      // Guardar la receta en Firebase
      final RecipeService recipeService = RecipeService();
      await recipeService.saveRecipe(recipeInfo, widget.imagePath);
      
      // IMPORTANTE: Actualiza el estado después de la operación exitosa
      setState(() {
        recipeData = recipeInfo;
        isLoading = false;  // Asegúrate de que esto se establezca a false
        youtubeVideoId = recipeInfo['youtubeVideoId'];
      });
    } catch (e) {
      print("Error al guardar en Firebase: $e");
      // Aún actualizamos el estado para mostrar la receta aunque no se haya guardado
      setState(() {
        recipeData = recipeInfo;
        isLoading = false;
        youtubeVideoId = recipeInfo['youtubeVideoId'];
        // Opcional: Mostrar un mensaje indicando que no se guardó pero se puede ver
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La receta no se guardó permanentemente, pero puedes verla ahora'),
            backgroundColor: Colors.orange,
          ),
        );
      });
    }
  } catch (e) {
    setState(() {
      isLoading = false;
      isError = true;
      errorMessage = "Error al analizar la imagen: ${e.toString()}";
    });
  }
}
// Método alternativo de búsqueda
Future<String?> _searchAlternativeVideo(String? category, String? cuisine) async {
  if (category == null) return null;
  
  String searchQuery = "$category recetas";
  if (cuisine != null) {
    searchQuery += " $cuisine";
  }
  
  print("Intentando búsqueda alternativa: $searchQuery");
  return _searchYouTubeVideo(searchQuery);
}
  Future<Map<String, dynamic>?> _sendToOpenAI(String base64Image) async {
    const apiUrl =
        "https://pedro-m6tis0pz-swedencentral.cognitiveservices.azure.com/openai/deployments/gpt-4o/chat/completions?api-version=2025-01-01-preview";
    final headers = {
      "Content-Type": "application/json",
      'api-key': openAiApiKey,
    };
    
    final prompt = """
    Analiza esta imagen e identifica si contiene un plato de comida. Si es así, proporciona la siguiente información detallada en formato JSON:
    
    {
      "name": "Nombre completo del plato",
      "category": "Categoría del plato (arroces, pastas, carnes, postres, etc.)",
      "calories": número de calorías estimadas por porción,
      "protein": número de gramos estimados de proteínas,
      "proteinPercentage": porcentaje de proteínas del valor nutricional total,
      "fat": número de gramos estimados de grasas,
      "fatPercentage": porcentaje de grasas del valor nutricional total,
      "carbs": número de gramos estimados de carbohidratos,
      "carbsPercentage": porcentaje de carbohidratos del valor nutricional total,
      "cookingTime": tiempo estimado de preparación en minutos,
      "cuisine": "País o región de origen del plato",
      "description": "Descripción detallada del plato, incluyendo características principales, sabor y textura",
      "ingredients": ["Ingrediente 1 con cantidad", "ingrediente 2 con cantidad", ...],
      "preparation": ["Paso 1 de preparación", "Paso 2 de preparación", ...]
    }
    
    Si la imagen NO muestra claramente un plato de comida, responde con: {"error": "No es un plato de comida"}.
    
    Trata de identificar cualquier tipo de alimento preparado, incluso si la foto no es profesional o si el plato es poco común.
    Responde únicamente con el JSON, sin texto adicional ni explicaciones.
    """;

    final body = jsonEncode({
      "model": "gpt-4o",
      "messages": [
        {
          "role": "system",
          "content": prompt
        },
        {
          "role": "user",
          "content": [
            {
              "type": "image_url",
              "image_url": {
                "url": "data:image/jpeg;base64,$base64Image"
              }
            }
          ]
        }
      ],
      "temperature": 0.1,
      "max_tokens": 2000
    });

    try {
      final response = await http.post(Uri.parse(apiUrl), headers: headers, body: body);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('choices') && 
            data['choices'].isNotEmpty && 
            data['choices'][0].containsKey('message') &&
            data['choices'][0]['message'].containsKey('content')) {
          
          String content = data['choices'][0]['message']['content'];
          
          // Remove code block markers if present
          if (content.startsWith('```')) {
            final startIndex = content.indexOf('{');
            if (startIndex != -1) {
              final endIndex = content.lastIndexOf('```');
              if (endIndex != -1 && endIndex > startIndex) {
                content = content.substring(startIndex, endIndex);
              } else {
                content = content.substring(startIndex);
              }
            }
          }
          
          try {
            return json.decode(content);
          } catch (e) {
            print("Error al analizar JSON: $e");
            print("Contenido recibido: $content");
            return {'error': 'Formato de respuesta inválido'};
          }
        }
      } else {
        print("Error API: ${response.statusCode} - ${response.body}");
      }
      return {'error': 'Error en la solicitud a la API'};
    } catch (e) {
      print("Excepción en solicitud: $e");
      return {'error': 'Error de conexión'};
    }
  }

 Future<String?> _searchYouTubeVideo(String query) async {
  const apiKey = youtubeApi;
  String searchQuery = query;
  if (recipeData.containsKey('cuisine') && recipeData['cuisine'] != null) {
    searchQuery = "$query ${recipeData['cuisine']} cocina receta";
  } else {
    searchQuery = "$query receta cocina paso a paso";
  }
  
  print("Buscando video con query: $searchQuery");
  
  final encodedQuery = Uri.encodeComponent(searchQuery);
  final url = Uri.parse(
      'https://www.googleapiskey.com/youtube/v3/search?part=snippet&maxResults=1&q=$encodedQuery&type=video&key=$apiKey');

  try {
    final response = await http.get(url);
    print("Código de respuesta YouTube: ${response.statusCode}");
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['items'] != null && data['items'].isNotEmpty) {
        final videoId = data['items'][0]['id']['videoId'];
        print("Video ID encontrado: $videoId");
        
        // ¡SIMPLEMENTE DEVUELVE EL ID SIN VERIFICAR!
        return videoId;
        
        // Código original:
        // if (await _verifyVideoExists(videoId)) {
        //   return videoId;
        // } else {
        //   print("El video existe pero no es reproducible");
        // }
      }
    }
    print("No se encontró ningún video o hubo un problema");
    return null;
  } catch (e) {
    print("Excepción buscando video: $e");
    return null;
  }
}

  Future<bool> _verifyVideoExists(String videoId) async {
  const apiKey = youtubeApi;
  final url = Uri.parse(
      'https://www.googleapiskey.com/youtube/v3/videos?part=status,contentDetails&id=$videoId&key=$apiKey');
  try {
    print("Verificando video: $url");
    final response = await http.get(url);
    print("Código de respuesta verificación: ${response.statusCode}");
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print("Respuesta verificación detallada: ${response.body}");
      
      if (data['items'] != null && data['items'].isNotEmpty) {
        final status = data['items'][0]['status'];
        print("Estado del video: $status");
        
        // IMPORTANTE: La verificación es demasiado restrictiva
        // Vamos a ser menos estrictos
        return true; // ¡Devuelve true sin importar el estado!
        
        // El código original:
        // if (status['embeddable'] == true &&
        //     status['privacyStatus'] != 'private' &&
        //     !status.containsKey('uploadStatus')) {
        //   return true;
        // } else {
        //   print("Video no embebible o privado");
        // }
      } else {
        print("No se encontró información del video");
      }
    }
    return false;
  } catch (e) {
    print("Error verificando video: $e");
    return false;
  }
}

  Widget _buildVideoButton() {
    bool shouldShowButton = true;
    return AnimatedOpacity(
      // ignore: dead_code
      opacity: shouldShowButton ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Center(
        child: GestureDetector(
          onTap: () {
          if (youtubeVideoId != null) {
            setState(() {
              isVideoVisible = true;
            });
          } else {
            // Mostrar un mensaje de depuración
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se encontró un video relacionado con esta receta'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 20,
            ),
            decoration: BoxDecoration(
              color: Colors.deepOrange,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.play_circle_filled,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ver Video de la Receta',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Instrucciones paso a paso',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildYoutubePlayer() {
    if (youtubeVideoId == null) {
    return Container(); // No mostrar nada si no hay ID
  }
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.95),
        child: SafeArea(
          child: Column(
            children: [
              // Header with close button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Center(
                  child: Text(
                    "Video: ${recipeData['name'] ?? 'Receta'}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              // YouTube player (takes available space)
              Expanded(
                child: Center(
                  child: YoutubePlayer(
                    controller: YoutubePlayerController(
                      initialVideoId: youtubeVideoId!,
                      flags: const YoutubePlayerFlags(
                        autoPlay: true,
                        mute: false,
                        disableDragSeek: false,
                        loop: false,
                        isLive: false,
                        forceHD: false,
                        enableCaption: true,
                      ),
                    ),
                    showVideoProgressIndicator: true,
                    progressIndicatorColor: Colors.orange,
                    progressColors: const ProgressBarColors(
                      playedColor: Colors.orange,
                      handleColor: Colors.orangeAccent,
                    ),
                    onReady: () {
                      print("YouTube player ready");
                    },
                  ),
                ),
              ),
              
              // Bottom controls
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          isVideoVisible = false;
                        });
                      },
                      
                      label: const Text('Volver a la receta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Permite que el contenido se extienda detrás del AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "FoodSeek",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.2),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: isLoading
          ? _buildLoadingView()
          : isError
              ? _buildErrorView()
              : _buildRecipeView(),
    );
  }

  // Reemplaza la función _buildLoadingView() existente con esta nueva versión

Widget _buildLoadingView() {
  return ScanningImageContainer(
    imagePath: widget.imagePath,
    isAnalyzing: isLoading,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           // Texto de analizando con efecto de resplandor
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.2),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Text(
              "Analizando receta...",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildErrorView() {
    
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(
        File(widget.imagePath),
        fit: BoxFit.cover,
      ),
        Container(
        color: Colors.black.withOpacity(0.6),
      ),
      
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 20),
              Text(
                errorMessage,
                style: const TextStyle(fontSize: 18, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: const Text("Escanear nueva imagen"),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeView() {
    final double imageHeight = MediaQuery.of(context).size.height * 0.5;
    final double sheetMinHeight = MediaQuery.of(context).size.height * 0.6;
    
    return Stack(
      children: [
        // Imagen de fondo fija
        Container(
          height: MediaQuery.of(context).size.height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Imagen superior
              recipeData.containsKey('imageUrl') && recipeData['imageUrl'] != null
  ? Image.network(
      recipeData['imageUrl'],
      fit: BoxFit.cover,
      height: imageHeight,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,
            color: Colors.orange,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Image.file(
          File(widget.imagePath),
          fit: BoxFit.cover,
          height: imageHeight,
        );
      },
    )
  : Image.file(
      File(widget.imagePath),
      fit: BoxFit.cover,
      height: imageHeight,
    ),
              // Degradado sobre la imagen
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height * 0.6,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Panel deslizante (bottom sheet)
        DraggableScrollableSheet(
          initialChildSize: 0.6, // Altura inicial del panel (60% de la pantalla)
          minChildSize: 0.6, // Mínimo tamaño permitido
          maxChildSize: 0.9, // Máximo tamaño permitido
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 15,
                    spreadRadius: 1,
                  )
                ],
              ),
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.zero,
                children: [
                  // Indicador de arrastre
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  // Categoría y fecha
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            recipeData['category'] ?? "Sin categoría",
                            style: const TextStyle(
                              color: Colors.purple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '${DateFormat('yyyy-MM-dd').format(DateTime.now())} • Meal 2',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Nombre de la receta
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Text(
                      recipeData['name'] ?? "Plato desconocido",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Información nutricional
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildNutritionCard(
                          '${recipeData['calories'] ?? 0}',
                          'Calorías',
                          Colors.grey.shade600,
                        ),
                        _buildNutritionCard(
                          '${recipeData['protein']?.toString() ?? "0"} g',
                          '${recipeData['proteinPercentage'] ?? 26}% Proteína',
                          Colors.red.shade600,
                        ),
                        _buildNutritionCard(
                          '${recipeData['fat']?.toString() ?? "0"} g',
                          '${recipeData['fatPercentage'] ?? 44}% Grasa',
                          Colors.orange.shade600,
                        ),
                        _buildNutritionCard(
                          '${recipeData['carbs']?.toString() ?? "0"} g',
                          '${recipeData['carbsPercentage'] ?? 33}% Carbos',
                          Colors.green.shade600,
                        ),
                      ],
                    ),
                  ),

                  // Descripción
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Descripción',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedCrossFade(
                          firstChild: Text(
                            recipeData['description'] ?? 'No hay descripción disponible',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          secondChild: Text(
                            recipeData['description'] ?? 'No hay descripción disponible',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                          crossFadeState: isDescriptionExpanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 300),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                isDescriptionExpanded = !isDescriptionExpanded;
                              });
                            },
                            child: Text(
                              isDescriptionExpanded ? 'Mostrar menos' : 'Leer más',
                              style: const TextStyle(
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tiempo de cocción y tipo de cocina
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.timer,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tiempo de cocción',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    '${recipeData['cookingTime'] ?? 30} min',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.restaurant,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cocina',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    recipeData['cuisine'] ?? 'Internacional',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Ingredientes
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Ingredientes',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '1 porción',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (recipeData.containsKey('ingredients') &&
                            recipeData['ingredients'] is List)
                          ...List.generate(
                            (recipeData['ingredients'] as List).length,
                            (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '• ${(recipeData['ingredients'] as List)[index]}',
                                style: TextStyle(
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                          )
                        else
                          const Text('No hay ingredientes disponibles'),
                      ],
                    ),
                  ),

                  // Preparación
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Preparación',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (recipeData.containsKey('preparation') &&
                            recipeData['preparation'] is List)
                          ...List.generate(
                            (recipeData['preparation'] as List).length,
                            (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 25,
                                    height: 25,
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(12.5),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      (recipeData['preparation'] as List)[index],
                                      style: TextStyle(
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          const Text('No hay pasos de preparación disponibles'),
                      ],
                    ),
                  ),

                  // Espacio adicional al final para evitar que el botón flotante oculte contenido
                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        ),

        // Botón flotante para ver video
        if (youtubeVideoId != null)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: _buildVideoButton(),
          ),

        // Reproductor de video (visible solo cuando se presiona el botón)
        if (isVideoVisible && youtubeVideoId != null)
          _buildYoutubePlayer(),
      ],
    );
  }

  Widget _buildNutritionCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color..withValues(alpha: 1),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(1),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}