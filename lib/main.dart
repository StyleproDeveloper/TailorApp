import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/GlobalVariables.dart';
import 'package:tailorapp/Routes/App_route.dart';
import 'package:tailorapp/Features/Splash/SplashScreen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  try {
    print('🚀 App starting...');
    WidgetsFlutterBinding.ensureInitialized();
    print('✅ WidgetsFlutterBinding initialized');
    
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: ColorPalatte.white,
      statusBarIconBrightness: Brightness.dark,
    ));
    
    // Load GlobalVariables in background - don't block app startup
    GlobalVariables.loadShopId().then((_) {
      print('✅ GlobalVariables loaded');
    }).catchError((e) {
      print('⚠️ Error loading GlobalVariables: $e');
      // Don't block app startup if this fails
    });
    
    runApp(const ProviderScope(child: MyApp()));
    print('✅ App running');
  } catch (e, stackTrace) {
    print('❌ Error in main(): $e');
    print('❌ Stack trace: $stackTrace');
    // Still try to run the app even if there's an error
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Error starting app', style: TextStyle(fontSize: 20)),
              Text('$e', style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
      onUnknownRoute: (settings) {
        // Handle unknown routes by redirecting to splash
        return MaterialPageRoute(
          builder: (context) => const Splashscreen(),
        );
      },
    );
  }
}
