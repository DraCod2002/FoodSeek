import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:food_seek/main.dart';
import 'package:get/get.dart';

class NetworkManager extends StatefulWidget {
  final Widget child;
  const NetworkManager({super.key, required this.child});

  @override
  NetworkManagerState createState() => NetworkManagerState();
}

class NetworkManagerState extends State<NetworkManager> {
  late StreamSubscription _subscription;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();

    _subscription = Connectivity().onConnectivityChanged.listen((results) async {
      bool hasInternet = await _checkInternetAccess(); // Verifica acceso real

      if (mounted) {
        setState(() {
          _isOffline = !hasInternet;
        });

        if (_isOffline) {
          _showNoConnectionDialog();
        }
      }
    });

    // Verifica al iniciar si hay acceso real a internet
    _checkInternetOnStart();
  }

  // ✅ Verifica si hay acceso real a Internet
  Future<bool> _checkInternetAccess() async {
    try {
      final result = await InternetAddress.lookup('google.com'); // Ping a Google
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } on SocketException catch (_) {
      return false;
    }
    return false;
  }

  // ✅ Comprueba la conexión al iniciar
  Future<void> _checkInternetOnStart() async {
    bool hasInternet = await _checkInternetAccess();
    if (!hasInternet) {
      if (mounted) {
        setState(() {
          _isOffline = true;
        });
        _showNoConnectionDialog();
      }
    }
  }

  // ✅ Mostrar mensaje de error
  void _showNoConnectionDialog() {
    if (!mounted) return;

    Future.delayed(Duration(milliseconds: 100), () {
      if (!mounted) return;

      showDialog(
        context: navigatorKey.currentContext!,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                backgroundColor: const Color(0xE0FFFFFF),
                title: Column(
                  children: [
                    Icon(Icons.wifi, size: 50),
                    const SizedBox(height: 10),
                    Text(
                      "Sin conexión".tr,
                      textAlign: TextAlign.center,
                      style: TextStyle( fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                content: Text(
                  "No hay conexión a Internet. Verifica tu conexión y vuelve a intentarlo.".tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black87),
                ),
                actions: [
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color.fromARGB(224, 255, 132, 0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        bool hasInternet = await _checkInternetAccess();
                        if (hasInternet) {
                          Navigator.of(context).pop(); // Cierra el diálogo
                        } else {
                          setDialogState(() {}); // Mantiene el diálogo abierto si sigue sin conexión
                        }
                      },
                      child: const Text(
                        "Intentar de nuevo",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
