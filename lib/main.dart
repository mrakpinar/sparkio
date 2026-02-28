import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/theme_service.dart';
import 'services/iap_service.dart';
import 'services/ad_service.dart';
import 'services/locale_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/onboarding_screen.dart';
import 'app_strings.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseAnalytics.instance;
  await NotificationService.instance.init();
  await NotificationService.instance.showRemoteNotification(
    title: message.notification?.title,
    body: message.notification?.body,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await NotificationService.instance.init();
  await ThemeService.instance.load();
  await LocaleService.instance.load();
  if (!AdService.hideAdsForScreenshots) {
    await MobileAds.instance.initialize();
  }
  await IapService.instance.init();
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);
  await messaging.setAutoInitEnabled(true);
  await messaging.subscribeToTopic('all_users');
  final token = await messaging.getToken();
  if (kDebugMode) {
    // ignore: avoid_print
    print('FCM: token=$token');
  }
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('FCM: token_refresh=$newToken');
    }
  });
  FirebaseMessaging.onMessage.listen((message) async {
    await NotificationService.instance.showRemoteNotification(
      title: message.notification?.title,
      body: message.notification?.body,
    );
  });
  runApp(const SparkioApp());
}

class SparkioApp extends StatelessWidget {
  const SparkioApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF8B5CF6);
    const primaryDark = Color(0xFF5B35C8);
    const accent = Color(0xFFF43F8C);
    const tertiary = Color(0xFF22D3EE);

    const darkBackground = Color(0xFF090C16);
    const darkSurface = Color(0xFF111624);
    const darkCard = Color(0xFF1A2233);
    const darkTextPrimary = Color(0xFFF4F6FF);
    const darkTextSecondary = Color(0xFFA2ACCB);
    const darkDivider = Color(0xFF2B3450);

    const lightBackground = Color(0xFFF3F0FA);
    const lightSurface = Color(0xFFFFFFFF);
    const lightCard = Color(0xFFEDE9F8);
    const lightTextPrimary = Color(0xFF17192A);
    const lightTextSecondary = Color(0xFF5F6684);
    const lightDivider = Color(0xFFD6D8E8);

    final darkScheme = const ColorScheme(
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryDark,
      onPrimaryContainer: Color(0xFFEDE4FF),
      secondary: accent,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF5A203C),
      onSecondaryContainer: Color(0xFFFFDCEB),
      tertiary: tertiary,
      onTertiary: Color(0xFF032B33),
      tertiaryContainer: Color(0xFF124651),
      onTertiaryContainer: Color(0xFFC4F3FF),
      background: darkBackground,
      onBackground: darkTextPrimary,
      surface: darkSurface,
      onSurface: darkTextPrimary,
      surfaceVariant: darkCard,
      onSurfaceVariant: darkTextSecondary,
      outline: darkDivider,
      shadow: Colors.black,
      error: Color(0xFFFF5D73),
      onError: Colors.white,
    );

    final lightScheme = const ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE8DEFF),
      onPrimaryContainer: lightTextPrimary,
      secondary: accent,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFFFD9EA),
      onSecondaryContainer: lightTextPrimary,
      tertiary: tertiary,
      onTertiary: Color(0xFF07303A),
      tertiaryContainer: Color(0xFFCFF5FF),
      onTertiaryContainer: Color(0xFF07303A),
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
        return ValueListenableBuilder<Locale?>(
          valueListenable: LocaleService.instance.locale,
          builder: (context, locale, _) {
            return MaterialApp(
              title: 'SPARKIO',
              debugShowCheckedModeBanner: false,
              locale: locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
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
              color: lightSurface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
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
              fillColor: lightCard.withOpacity(0.6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: lightDivider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: lightDivider.withOpacity(0.8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: primary, width: 1.2),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: primary,
                side: BorderSide(color: primary.withOpacity(0.35)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            chipTheme: ChipThemeData(
              selectedColor: primary,
              backgroundColor: lightCard.withOpacity(0.75),
              labelStyle: const TextStyle(color: lightTextPrimary),
              secondaryLabelStyle: const TextStyle(color: Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: lightDivider.withOpacity(0.7)),
              ),
            ),
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: lightSurface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
            ),
            snackBarTheme: SnackBarThemeData(
              backgroundColor: lightSurface,
              contentTextStyle: const TextStyle(color: lightTextPrimary),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: lightDivider.withOpacity(0.8)),
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
                borderRadius: BorderRadius.circular(20),
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
              fillColor: darkCard.withOpacity(0.88),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: darkDivider.withOpacity(0.7)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: darkDivider.withOpacity(0.75)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: primary, width: 1.2),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: darkTextPrimary,
                side: BorderSide(color: darkDivider.withOpacity(0.9)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            chipTheme: ChipThemeData(
              selectedColor: primary,
              backgroundColor: darkCard,
              labelStyle: const TextStyle(color: darkTextPrimary),
              secondaryLabelStyle: const TextStyle(color: Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: darkDivider.withOpacity(0.7)),
              ),
            ),
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: darkSurface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
            ),
            snackBarTheme: SnackBarThemeData(
              backgroundColor: darkCard,
              contentTextStyle: const TextStyle(color: darkTextPrimary),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: darkDivider.withOpacity(0.9)),
              ),
            ),
          ),
              themeMode: mode == ThemeMode.dark ? ThemeMode.dark : ThemeMode.light,
              home: const _LaunchGate(),
            );
          },
        );
      },
    );
  }
}

const String _kOnboardingCompletedKey = 'onboarding_completed_v1';

class _LaunchGate extends StatefulWidget {
  const _LaunchGate();

  @override
  State<_LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<_LaunchGate> {
  bool? _onboardingCompleted;

  @override
  void initState() {
    super.initState();
    _loadOnboardingState();
  }

  Future<void> _loadOnboardingState() async {
    final sp = await SharedPreferences.getInstance();
    final completed = sp.getBool(_kOnboardingCompletedKey) ?? false;
    if (!mounted) return;
    setState(() => _onboardingCompleted = completed);
  }

  Future<void> _completeOnboarding() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kOnboardingCompletedKey, true);
    if (!mounted) return;
    setState(() => _onboardingCompleted = true);
  }

  @override
  Widget build(BuildContext context) {
    final completed = _onboardingCompleted;
    if (completed == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (completed) {
      return const HomeScreen();
    }

    return OnboardingScreen(onFinished: _completeOnboarding);
  }
}




