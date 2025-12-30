import 'package:flutter/material.dart' hide ThemeData, ThemeMode, Theme, Scaffold, AppBar, Card, IconButton, CircularProgressIndicator, Divider, Colors;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize date formatting
  await initializeDateFormatting();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(
    const ProviderScope(
      child: AIBriefingApp(),
    ),
  );
}

class AIBriefingApp extends StatelessWidget {
  const AIBriefingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadcnApp(
      title: 'AI Briefing',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      home: const HomeScreen(),
    );
  }
}
