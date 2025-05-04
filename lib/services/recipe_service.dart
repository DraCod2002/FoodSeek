import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:food_seek/models/recipe_model.dart';

class RecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Obtener todas las recetas del usuario actual
  Stream<List<Recipe>> getUserRecipes() {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('recipes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Recipe.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Obtener todas las recetas favoritas del usuario actual
  Stream<List<Recipe>> getFavoriteRecipes() {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('recipes')
        .where('isFavorite', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Recipe.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
  
  // Añadir o quitar receta de favoritos
  Future<void> toggleFavorite(String recipeId, bool isFavorite) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception("Usuario no autenticado");
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('recipes')
          .doc(recipeId)
          .update({
        'isFavorite': isFavorite,
      });
    } catch (e) {
      print("Error actualizando favorito: $e");
      throw e;
    }
  }

  // Actualizar un campo específico de una receta
  Future<void> updateRecipeField(String recipeId, String field, dynamic value) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception("Usuario no autenticado");
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('recipes')
          .doc(recipeId)
          .update({
        field: value,
      });
    } catch (e) {
      print("Error actualizando campo de receta: $e");
      throw e;
    }
  }

  // Guardar una nueva receta
  Future<String> saveRecipe(Map<String, dynamic> recipeData, String imagePath) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception("Usuario no autenticado");
      }

      // Subir la imagen a Firebase Storage
      String fileName = 'recipe_${DateTime.now().millisecondsSinceEpoch}.jpg';
      String storagePath = 'users/$userId/recipes/$fileName';
      File imageFile = File(imagePath);
      
      // Subir imagen a Firebase Storage
      TaskSnapshot uploadTask = await _storage.ref(storagePath).putFile(imageFile);
      
      // Obtener la URL de descarga
      String imageUrl = await uploadTask.ref.getDownloadURL();

      // Crear un nuevo documento en Firestore
      DocumentReference docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('recipes')
          .add({
        ...recipeData,
        'imageUrl': imageUrl, // Ahora guardamos la URL de Firebase Storage
        'storagePath': storagePath, // Guardar la ruta de almacenamiento para eliminar después
        'createdAt': Timestamp.now(),
        'isFavorite': false, // Inicialmente no es favorito
      });

      return docRef.id;
    } catch (e) {
      print("Error guardando receta: $e");
      throw e;
    }
  }

  // Eliminar una receta
  Future<void> deleteRecipe(String recipeId) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception("Usuario no autenticado");
      }

      // Obtener la receta para conseguir la ruta de la imagen
      DocumentSnapshot recipeDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('recipes')
          .doc(recipeId)
          .get();

      // Eliminar la imagen de Firebase Storage si existe
      if (recipeDoc.exists) {
        String? storagePath = recipeDoc.get('storagePath');
        if (storagePath != null && storagePath.isNotEmpty) {
          try {
            await _storage.ref(storagePath).delete();
          } catch (e) {
            print("Error eliminando imagen de Storage: $e");
          }
        }
      }

      // Eliminar el documento de Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('recipes')
          .doc(recipeId)
          .delete();
    } catch (e) {
      print("Error eliminando receta: $e");
      throw e;
    }
  }

  // Obtener una receta específica
  Future<Recipe?> getRecipe(String recipeId) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        return null;
      }

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('recipes')
          .doc(recipeId)
          .get();
      
      if (doc.exists) {
        return Recipe.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print("Error obteniendo receta: $e");
      return null;
    }
  }
}