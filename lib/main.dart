import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'data/local/sembast_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env
  await dotenv.load(fileName: '.env', mergeWith: {});

  // Initialize local DB (sembast — pure Dart, no WASM) and seed demo data
  await SembastHelper.instance.database;
  await SembastHelper.instance.seedIfEmpty();

  // Initialize Supabase if credentials are saved
  final prefs = await SharedPreferences.getInstance();
  final url = prefs.getString('supabase_url') ?? dotenv.env['SUPABASE_URL'] ?? '';
  final key = prefs.getString('supabase_anon_key') ?? dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (url.isNotEmpty && key.isNotEmpty) {
    try {
      await Supabase.initialize(url: url, anonKey: key);
    } catch (_) {}
  }

  runApp(const ProviderScope(child: AttendanceTrackerApp()));
}
