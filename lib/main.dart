// ==========================================
// 1. IMPORTS SECTION
// ==========================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // 👈 🎯 `flutterfire configure` එක සාර්ථක වුණාම මේ රතු ඉර ඔටෝමැටිකලිම නැතිවෙලා යනවා මචං!

// 📦 ඔයාගේ ඇප් එකේ ස්ක්‍රීන්ස් සහ ප්‍රොවයිඩර්ස් ටික මෙතනින් හරියටම ලින්ක් වෙනවා
import 'member_provider.dart';
import 'splash_screen.dart';
import 'login_screen.dart';
import 'home/home_page.dart';

// ==========================================
// 2. MAIN METHOD WITH FIREBASE INITIALIZATION
// ==========================================
void main() async {
  // 🎯 Flutter Engine එක මුලින්ම සූදානම් කරගන්නවා
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Firebase එක ඇප් එකත් එක්ක නූලටම කනෙක්ට් කරන කෝඩ් එක
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    // 🧠 මුළු ඇප් එකටම MemberProvider එක මෙතනින් සෙට් කරනවා
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MemberProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

// ==========================================
// 3. MY APP CLASS WITH THEME & ROUTES
// ==========================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AIAPRTD Member App',
      debugShowCheckedModeBanner: false, // 🔴 රතු Debug ටැග් එක අයින් කලා

      // 🎨 ඇප් එකේ තීම් එක (සංගමයේ නිල් පාටට සහ සුදු පසුබිමට ගැලපෙන්න හැදුවා)
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          primary: const Color(0xFF1E3A8A),
          surface: Colors.white, // 👈 🎯 'background' වෙනුවට 'surface' දාලා Error එක සම්පූර්ණයෙන්ම හැදුවා මචං!
        ),
        useMaterial3: true,
      ),

      // 🚀 ඇප් එක මුලින්ම ඕපන් වෙද්දී යන්න ඕන පේජ් එක (Splash Screen)
      initialRoute: '/',

      // 🗺️ ඇප් එකේ තියෙන පේජ්ස් වල පාරවල් (Named Routes)
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}