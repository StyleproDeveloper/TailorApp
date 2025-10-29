import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tailorapp/Core/Constants/ColorPalatte.dart';
import 'package:tailorapp/GlobalVariables.dart';
import 'package:tailorapp/Routes/App_route.dart';
import 'package:tailorapp/Features/Splash/SplashScreen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async{
   SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: ColorPalatte.white,
    statusBarIconBrightness: Brightness.dark,
  ));
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalVariables.loadShopId();
  runApp(const ProviderScope(child: MyApp()));
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
