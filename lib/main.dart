import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/app_data.dart';
import 'data/auth_session.dart';
import 'data/garden_nav_controller.dart';
import 'screens/auth/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const CareGardenApp());
}

class CareGardenApp extends StatelessWidget {
  const CareGardenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppData()),
        ChangeNotifierProvider(create: (_) => AuthSession()),
        ChangeNotifierProvider(create: (_) => GardenNavController()),
      ],
      child: MaterialApp(
        title: '마음정원',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        builder: (context, child) {
          return Container(
            color: const Color(0xFFF0F0F0), // 넓은 화면일 때 바깥 배경색
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: child,
              ),
            ),
          );
        },
        home: const LoginScreen(),
      ),
    );
  }
}
