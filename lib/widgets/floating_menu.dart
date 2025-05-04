import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_seek/presentation/pages/recipe_page.dart';
import 'package:image_picker/image_picker.dart';

class FloatingMenu extends StatelessWidget {
  const FloatingMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100, // Ajusta la altura sobre el FloatingActionButton
      left: MediaQuery.of(context).size.width * 0.23,
      right: MediaQuery.of(context).size.width * 0.23,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color.fromARGB(69, 0, 0, 0),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _menuButton(
              context, 
              FontAwesomeIcons.bowlFood, 
              "Buscar receta", 
              _handleFoodButton,
              iconColor: const Color.fromARGB(255, 255, 255, 255), // Color ámbar para este icono
              textColor: const Color.fromARGB(255, 255, 255, 255),// Color ámbar para este texto
            ),
            _menuButton(
              context, 
              Icons.image, 
              "Galería", 
              () => _pickImageFromGallery(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuButton(
    BuildContext context, 
    IconData icon, 
    String label, 
    VoidCallback onTap, {
    Color iconColor = const Color(0xD5FFFFFF), // Color por defecto
    Color textColor = const Color(0xD5FFFFFF), // Color por defecto
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 24),
          Text(
            label, 
            style: TextStyle(color: textColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _handleFoodButton() {
    // Implementa la lógica para el botón de alimentos
    debugPrint("Botón de alimentos presionado");
  }

  Future<void> _pickImageFromGallery(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null && context.mounted) {
        // Navegar a RecipePage con la ruta de la imagen seleccionada
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipePage(imagePath: image.path),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error al seleccionar imagen de la galería: $e");
    }
  }
}