// ignore_for_file: spell_check_on_languages, spell_check_on_word
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// ==========================================
// 🎯 PROVIDERS
// ==========================================
import 'providers/profile_provider.dart';
import 'providers/kyc_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/vehicle_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/booking_provider.dart'; // 💡 අලුත් BookingProvider එක මෙතනට දැම්මා
import 'providers/meter_provider.dart';
import 'providers/theme_provider.dart';

// ==========================================
// 📄 PAGES
// ==========================================
import 'splash_screen.dart';
import 'login_screen.dart';
import 'home/home_page.dart';
import 'home/booking_dashboard_page.dart'; // 💡 Dashboard එක Import කරලා තියෙනවා
import 'home/create_job_page.dart';
import 'home/road_pickup_page.dart';
import 'home/sos_page.dart';
import 'profile/profile_page.dart';
import 'parking/parking_page.dart';
import 'income/income_page.dart';

import 'home/global_chat_button.dart';
import 'providers/ads_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => KYCProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()), // 💡 BookingProvider එක MultiProvider එකට ඇතුලත් කළා
        ChangeNotifierProvider(create: (_) => MeterProvider()),
        ChangeNotifierProvider(create: (_) => AdsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
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
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
            scaffoldBackgroundColor: Colors.grey.shade50,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
            ),
            cardTheme: const CardThemeData(
              color: Colors.white,
              surfaceTintColor: Colors.white,
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: Colors.blue,
              unselectedItemColor: Colors.grey,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            cardTheme: const CardThemeData(
              color: Color(0xFF1E1E1E),
              surfaceTintColor: Color(0xFF1E1E1E),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Color(0xFF1E1E1E),
              selectedItemColor: Colors.blue,
              unselectedItemColor: Colors.grey,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Color(0xFF1E1E1E),
            ),
            useMaterial3: true,
          ),
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

        // 💡 🎯 මෙතන තමයි Error එක හැදුවේ (ScheduledPage වෙනුවට BookingDashboardPage දැම්මා)
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