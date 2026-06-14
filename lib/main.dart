import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// ඔබේ Providers
import 'member_provider.dart';
import 'personal/vehicle_info_provider.dart';

// ඔබේ Pages
import 'splash_screen.dart';
import 'login_screen.dart';
import 'home/home_page.dart';
import 'home/scheduled_page.dart';
import 'home/create_job_page.dart';
import 'home/road_pickup_page.dart';
import 'home/sos_page.dart';
import 'profile/profile_page.dart';
import 'parking/parking_page.dart';
import 'incom/income_page.dart';

void main() async {
  // Flutter bindings නිවැරදිව ආරම්භ කිරීම
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase දෝෂය මගහැරීමට මෙය වඩාත් ආරක්ෂිත ක්‍රමයයි
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }

  // ඇප් එකේ ප්‍රධාන කොටස ධාවනය කිරීම
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MemberProvider()),
        ChangeNotifierProvider(create: (_) => VehicleInfoProvider()),
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
        primarySwatch: Colors.blue,
        useMaterial3: true, // මෙය මගින් UI එක නවීන පෙනුමක් ලබාගන්නවා
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomePage(),
        '/scheduled': (context) => const ScheduledPage(),
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