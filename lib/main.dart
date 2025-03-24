import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'services/sync_service.dart';
import 'constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lade die .env-Datei
  try {
    await dotenv.load(fileName: ".env");
    // Debug-Ausgabe, um die geladenen Werte zu überprüfen
    debugPrint("✅ SUPABASE_URL: ${dotenv.env['SUPABASE_URL']}");
    debugPrint("✅ SUPABASE_ANON_KEY: ${dotenv.env['SUPABASE_ANON_KEY']}");
  } catch (e) {
    debugPrint("❌ Fehler beim Laden der .env-Datei: $e");
    rethrow;
  }

  runApp(const LMSSmartHelperAppInitial());
}

class LMSSmartHelperAppInitial extends StatelessWidget {
  const LMSSmartHelperAppInitial({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FutureBuilder(
        future: setupApp(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text(
                  'Fehler beim Starten der App: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } else if (snapshot.hasData) {
            final syncService = snapshot.data as SyncService;
            return LMSSmartHelperApp(syncService: syncService);
          }
          return const SizedBox.shrink(); // Fallback
        },
      ),
    );
  }
}

Future<SyncService> setupApp() async {
  try {
    // ✅ Supabase initialisieren
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
    );

    // Prüfe, ob die Supabase-Werte korrekt geladen wurden
    if (dotenv.env['SUPABASE_URL'] == null ||
        dotenv.env['SUPABASE_ANON_KEY'] == null) {
      throw Exception(
          'SUPABASE_URL oder SUPABASE_ANON_KEY fehlen in der .env-Datei.');
    }

    // ✅ Exportpfad asynchron abrufen
    String exportFolderPath = await AppConstants.getExportPath();

    // ✅ Sync-Service starten
    SyncService syncService = SyncService(exportFolderPath: exportFolderPath);
    await syncService.start();

    return syncService;
  } catch (e) {
    debugPrint("❌ Fehler beim Starten der App: $e");
    rethrow;
  }
}

class LMSSmartHelperApp extends StatelessWidget {
  final SyncService syncService;
  const LMSSmartHelperApp({super.key, required this.syncService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LMS Smart Helper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF2213B),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF2213B),
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          fillColor: Color.fromARGB(255, 243, 128, 128),
          filled: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          labelStyle: TextStyle(color: Colors.white),
          hintStyle: TextStyle(color: Colors.white70),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFFF2213B),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFFF2213B),
          elevation: 0,
          selectedItemColor: Colors.white,
          unselectedItemColor: Color(0xFFF2213B),
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          labelLarge: TextStyle(color: Colors.white),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
