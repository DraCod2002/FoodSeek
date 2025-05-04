import 'package:flutter/material.dart';

final ThemeData theme = ThemeData(
  useMaterial3: true,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    elevation: 0.0,
    surfaceTintColor: Colors.black,
  ),
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    brightness: Brightness.light,
    background: Colors.white,
    onBackground: Colors.black,
    surfaceTint: Colors.white12,
    primary: Colors.black,
    onPrimary: Colors.white,
  ),
);
