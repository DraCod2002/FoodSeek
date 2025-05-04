import 'package:country_flags/country_flags.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_seek/presentation/pages/terms_and_conditions_page.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomBottomSheet {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.transparent, // Para que el gradiente se aplique correctamente
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),

      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFFFFFFF),
              ],
            ),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(192, 207, 207, 207),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                // Cambiar idioma
                ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(
                      'Change language'.tr,
                      
                    ),
                    onTap: () {
                      _changeLanguage(context);
                    }),
                ListTile(
                  leading: const Icon(Icons.discord),
                  title: Text(
                    'Join the Discord channel'.tr,
                    
                  ),
                  onTap: () {
                    _launchURL('https://discord.gg/NEy4Z8qm');
                  },
                ),
                // Síguenos en TikTok
                ListTile(
                  leading: const Icon(Icons.tiktok),
                  title: Text(
                    'Follow us on TikTok'.tr,
                    
                  ),
                  onTap: () {
                    _launchURL('https://www.tiktok.com/@mrnopolis/');
                  },
                ),

                // Política de privacidad
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: Text(
                    'Privacy policy'.tr,
                    
                  ),
                  onTap: () {
                    _launchURL(
                        'https://viebaai.netlify.app/');
                  },
                ),

                // Términos de uso
                ListTile(
                  leading: const Icon(Icons.description),
                  title: Text(
                    'Terms of use'.tr,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => TermsAndConditionsPage()),
                    );
                    // Acción para términos de uso
                  },
                ),
                ListTile(
                leading: Icon(Icons.exit_to_app, color: Colors.red),
                title:
                    Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  await GoogleSignIn().signOut();
                  await FirebaseAuth.instance.signOut();
                },
              ),
              ],
            ),
          ),
        );
      },
    );
  }
}

void _changeLanguage(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        title: Text(
          'Select a language'.tr,
          style: TextStyle(color: Colors.black),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _languageOption('English'.tr, 'us', Locale('en', 'US'), context),
            _languageOption('Spanish'.tr, 'es', Locale('es', 'ES'), context),
            _languageOption('Portuguese'.tr, 'br', Locale('pt', 'BR'), context),
          ],
        ),
      );
    },
  );
}

Widget _languageOption(
    String language, String flagAsset, Locale locale, BuildContext context) {
  bool isSelected = Get.locale == locale;
  return ListTile(
    leading: CountryFlag.fromCountryCode(
      flagAsset.toUpperCase(),
      width: 30,
      height: 20,
      shape: const RoundedRectangle(2),
    ),
    title: Text(
      language,
      style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
    ),
    trailing: isSelected ? Icon(Icons.check, color: Colors.green) : null,
    onTap: () {
      Get.updateLocale(locale);
      _saveLanguagePreference(locale);
      Navigator.pop(context);
    },
  );
}

void _saveLanguagePreference(Locale locale) {
  final box = GetStorage();
  box.write('language', locale.toString());
}

void _launchURL(String url) async {
  final Uri uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    ScaffoldMessenger.of(Get.context!).showSnackBar(
      SnackBar(content: Text('No se pudo abrir el enlace')),
    );
  }
}
