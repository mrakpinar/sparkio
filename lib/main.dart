import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  await ThemeService.instance.load();
  await MobileAds.instance.initialize();
  runApp(const SparkioApp());
}

class SparkioApp extends StatelessWidget {
  const SparkioApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF3B82F6);
    const primaryDark = Color(0xFF1E40AF);
    const accent = Color(0xFF22D3EE);

    const darkBackground = Color(0xFF0F172A);
    const darkSurface = Color(0xFF020617);
    const darkCard = Color(0xFF020617);
    const darkTextPrimary = Color(0xFFE5E7EB);
    const darkTextSecondary = Color(0xFF94A3B8);
    const darkDivider = Color(0xFF1E293B);

    const lightBackground = Color(0xFFF8FAFC);
    const lightSurface = Color(0xFFFFFFFF);
    const lightCard = Color(0xFFF1F5F9);
    const lightTextPrimary = Color(0xFF0F172A);
    const lightTextSecondary = Color(0xFF475569);
    const lightDivider = Color(0xFFE2E8F0);

    final darkScheme = const ColorScheme(
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryDark,
      onPrimaryContainer: Colors.white,
      secondary: accent,
      onSecondary: Color(0xFF0F172A),
      secondaryContainer: Color(0xFF0E7490),
      onSecondaryContainer: Colors.white,
      background: darkBackground,
      onBackground: darkTextPrimary,
      surface: darkSurface,
      onSurface: darkTextPrimary,
      surfaceVariant: darkCard,
      onSurfaceVariant: darkTextSecondary,
      outline: darkDivider,
      shadow: Colors.black,
      error: Color(0xFFEF4444),
      onError: Colors.white,
    );

    final lightScheme = const ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFDBEAFE),
      onPrimaryContainer: lightTextPrimary,
      secondary: accent,
      onSecondary: Color(0xFF0F172A),
      secondaryContainer: Color(0xFFCFFAFE),
      onSecondaryContainer: lightTextPrimary,
      background: lightBackground,
      onBackground: lightTextPrimary,
      surface: lightSurface,
      onSurface: lightTextPrimary,
      surfaceVariant: lightCard,
      onSurfaceVariant: lightTextSecondary,
      outline: lightDivider,
      shadow: Colors.black12,
      error: Color(0xFFDC2626),
      onError: Colors.white,
    );

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.instance.mode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'SPARKIO',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Inter',
            colorScheme: lightScheme,
            scaffoldBackgroundColor: lightBackground,
            appBarTheme: const AppBarTheme(
              backgroundColor: lightBackground,
              elevation: 0,
              centerTitle: true,
            ),
            cardTheme: CardThemeData(
              color: lightCard,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            textTheme: ThemeData(brightness: Brightness.light).textTheme
                .copyWith(
                  titleLarge: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                  titleMedium: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  bodyMedium: const TextStyle(fontSize: 14, height: 1.35),
                ),
            dividerTheme: const DividerThemeData(color: lightDivider),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: lightCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: primary,
                side: const BorderSide(color: lightDivider),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            chipTheme: const ChipThemeData(
              selectedColor: primary,
              backgroundColor: lightCard,
              labelStyle: TextStyle(color: lightTextPrimary),
              secondaryLabelStyle: TextStyle(color: Colors.white),
            ),
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: lightSurface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Inter',
            colorScheme: darkScheme,
            scaffoldBackgroundColor: darkBackground,
            appBarTheme: const AppBarTheme(
              backgroundColor: darkBackground,
              elevation: 0,
              centerTitle: true,
            ),
            cardTheme: CardThemeData(
              color: darkCard,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            textTheme: ThemeData(brightness: Brightness.dark).textTheme
                .copyWith(
                  titleLarge: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                  titleMedium: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  bodyMedium: const TextStyle(fontSize: 14, height: 1.35),
                ),
            dividerTheme: const DividerThemeData(color: darkDivider),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: darkCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: darkTextPrimary,
                side: const BorderSide(color: darkDivider),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            chipTheme: const ChipThemeData(
              selectedColor: primary,
              backgroundColor: Color(0xFF0B1220),
              labelStyle: TextStyle(color: darkTextPrimary),
              secondaryLabelStyle: TextStyle(color: Colors.white),
            ),
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: darkSurface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
            ),
          ),
          themeMode: mode == ThemeMode.dark ? ThemeMode.dark : ThemeMode.light,
          home: const HomeScreen(),
        );
      },
    );
  }
}
