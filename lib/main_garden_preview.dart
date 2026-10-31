import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/app_data.dart';
import 'screens/garden/garden_screen.dart';
import 'theme/app_theme.dart';

/// Developer entry point: preview every flower GLB without changing diary data.
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppData(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const GardenScreen(assetPreview: true),
      ),
    ),
  );
}
