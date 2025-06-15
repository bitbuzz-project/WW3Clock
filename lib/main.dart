import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/main_screen.dart';
import 'providers/threat_provider.dart';
import 'providers/news_provider.dart';
import 'utils/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // TODO: Initialize Firebase when Windows compatibility is fixed
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  
  runApp(const WW3ClockApp());
}

class WW3ClockApp extends StatelessWidget {
  const WW3ClockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThreatProvider()),
        ChangeNotifierProvider(create: (_) => NewsProvider()),
      ],
      child: MaterialApp(
        title: 'WW3 Clock',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: AppColors.primaryColor,
          scaffoldBackgroundColor: AppColors.backgroundDark,
          cardColor: AppColors.cardBackground,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accentColor,
            secondary: AppColors.secondaryColor,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primaryColor,
            elevation: 0,
          ),
        ),
        home: const MainScreen(),
      ),
    );
  }
}