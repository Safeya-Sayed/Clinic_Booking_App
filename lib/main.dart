import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'repositories/clinic_repository.dart';
import 'repositories/firestore_clinic_repository.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/patient_home_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/assistant_home_screen.dart';
import 'repositories/booking_repository.dart';
import 'repositories/firestore_booking_repository.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);  
runApp(const MyApp());
}

  class MyApp extends StatelessWidget {
  const MyApp({super.key});
@override
Widget build(BuildContext context) {
return MultiProvider(
providers: [
ChangeNotifierProvider(
create: (_) => AuthProvider()..checkLoginStatus(),
),
Provider<ClinicRepository>(
create: (_) => FirestoreClinicRepository(),
),
  Provider<BookingRepository>(
    create: (_) => FirestoreBookingRepository(),
  ),
],
child: Consumer<AuthProvider>(
builder: (context, auth, _) {
return MaterialApp(
debugShowCheckedModeBanner: false,
title: 'Clinic App',
// theme: AppTheme.light,
routes: {
'/login': (_) => const LoginScreen(),
'/register': (_) => const RegisterScreen(),
  '/patient-home': (_) => const PatientHomeScreen(),
  '/assistant-home': (_) => const AssistantHomeScreen(),

},
  home: _buildHome(auth),
);
},
),
);
}
  Widget _buildHome(AuthProvider auth) {
    if (auth.isInitializing) return const SplashScreen();
if (!auth.isLoggedIn) return const LoginScreen();
return auth.isAssistant
? const AssistantHomeScreen()
: const PatientHomeScreen();
}
}