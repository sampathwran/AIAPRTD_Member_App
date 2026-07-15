// ignore_for_file: spell_check_on_languages, spell_check_on_word
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:aiaprtd_member/firebase_options.dart';
import 'package:aiaprtd_member/core/services/notification_service.dart';
import 'package:audioplayers/audioplayers.dart';

// ==========================================
// 🎯 PROVIDERS
// ==========================================
import 'package:aiaprtd_member/core/providers/profile_provider.dart';
import 'package:aiaprtd_member/core/providers/kyc_provider.dart';
import 'package:aiaprtd_member/core/providers/auth_provider.dart';
import 'package:aiaprtd_member/core/providers/community_assistance_provider.dart';
import 'package:aiaprtd_member/core/providers/vehicle_provider.dart';
import 'package:aiaprtd_member/core/providers/payment_provider.dart';
import 'package:aiaprtd_member/core/providers/booking_provider.dart'; // Newly added BookingProvider here
import 'package:aiaprtd_member/core/providers/meter_provider.dart';
import 'package:aiaprtd_member/core/providers/theme_provider.dart';
import 'package:aiaprtd_member/core/providers/earnings_provider.dart';
import 'package:aiaprtd_member/core/providers/settings_provider.dart';
import 'package:aiaprtd_member/core/providers/sos_provider.dart';
import 'package:aiaprtd_member/core/providers/finance_provider.dart'; // Added FinanceProvider
import 'package:aiaprtd_member/core/theme/app_theme.dart';

// ==========================================
// 📄 PAGES
// ==========================================
import 'package:aiaprtd_member/features/auth/splash_screen.dart';
import 'package:aiaprtd_member/features/auth/login_screen.dart';
import 'package:aiaprtd_member/features/home/home_page.dart';
import 'package:aiaprtd_member/features/home/booking_dashboard_page.dart'; // Dashboard has been imported
import 'package:aiaprtd_member/features/home/create_job_page.dart';
import 'package:aiaprtd_member/features/home/road_pickup_page.dart';
import 'package:aiaprtd_member/features/home/sos_page.dart';
import 'package:aiaprtd_member/features/profile/profile_page.dart';
import 'package:aiaprtd_member/features/parking/parking_page.dart';
import 'package:aiaprtd_member/features/income/income_page.dart';

import 'package:aiaprtd_member/features/home/global_chat_button.dart';
import 'package:aiaprtd_member/core/providers/ads_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Override debugPrint to suppress console output and improve performance
  debugPrint = (String? message, {int? wrapWidth}) {};

  // Firebase initialization
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }

  // Initialize Local Notifications
  await NotificationService().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => KYCProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()), // Added BookingProvider to MultiProvider
        ChangeNotifierProvider(create: (_) => MeterProvider()),
        ChangeNotifierProvider(create: (_) => AdsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => EarningsProvider()),
        ChangeNotifierProvider(create: (_) => FinanceProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => SosProvider()),
        ChangeNotifierProvider(create: (_) => CommunityAssistanceProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'AIAPRTD Member',
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: [
              if (child != null) child,
              const GlobalChatButton(),
            ],
          ),
        );
      },
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomePage(),

        // Fixed the error here (Replaced ScheduledPage with BookingDashboardPage)
        '/scheduled': (context) => const BookingDashboardPage(),

        '/create-job': (context) => const CreateJobPage(),
        '/road-pickup': (context) => const RoadPickupPage(),
        '/sos': (context) => const SosPage(),
        '/profile': (context) => const ProfilePage(),
        '/parking': (context) => const ParkingPage(),
        '/income': (context) => const IncomePage(),
      },
    );
      },
    );
  }
}