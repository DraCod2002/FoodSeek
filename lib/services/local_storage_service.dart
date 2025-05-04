import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class LocalStorageService {
  // Guardar imagen localmente
  Future<String> saveImageLocally(String sourcePath) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(sourcePath)}';
      final String localPath = '${appDir.path}/recipes/$fileName';
      
      // Crear directorio si no existe
      final Directory dir = Directory('${appDir.path}/recipes');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      // Copiar archivo
      final File sourceFile = File(sourcePath);
      final File newFile = await sourceFile.copy(localPath);
      
      return localPath;
    } catch (e) {
      print("Error guardando imagen localmente: $e");
      throw e;
    }
  }
  
  // Método para eliminar una imagen local
  Future<void> deleteImageLocally(String localPath) async {
    try {
      final File imageFile = File(localPath);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
    } catch (e) {
      print("Error eliminando imagen local: $e");
      throw e;
    }
  }
}