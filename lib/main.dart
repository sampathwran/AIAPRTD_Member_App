import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'member_provider.dart';
import 'splash_screen.dart';
import 'login_screen.dart';
import 'home/home_page.dart';
import 'home/scheduled_page.dart';
import 'home/create_job_page.dart';
import 'home/road_pickup_page.dart';
import 'home/sos_page.dart';
import 'profile/profile_page.dart'; // Profile පේජ් එක Import කළා
import 'parking/parking_page.dart';   // Parking පේජ් එක Import කළා
import 'incom/income_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => MemberProvider())],
      child: const MyApp()
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomePage(),
        '/scheduled': (context) => const ScheduledPage(),
        '/create-job': (context) => const CreateJobPage(),
        '/road-pickup': (context) => const RoadPickupPage(),
        '/sos': (context) => const SosPage(),
        '/profile': (context) => const ProfilePage(), // මෙතන route එක එකතු කළා
        '/parking': (context) => const ParkingPage(),  // මෙතන route එක එකතු කළා
        '/income': (context) => const IncomePage(),
      },
    );
  }
}