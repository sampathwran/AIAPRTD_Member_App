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
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AIAPRTD Member',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
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
  }
}