/// Configuration du backend Supabase.
///
/// Source de vérité : [supabase_secrets.dart] (gitignore, à remplir
/// manuellement). Fallback : variables `--dart-define` pour CI/CD.
///
/// Pour un build App Store depuis Xcode, remplis supabase_secrets.dart.
/// Pour un CI (GitHub Actions, Codemagic…), utilise :
///   flutter build ipa \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJhbGci...
library;

import 'supabase_secrets.dart';

abstract class SupabaseConfig {
  static const String _envUrl =
      String.fromEnvironment('SUPABASE_URL');
  static const String _envKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  // Priorité : fichier de secrets (Xcode/local) → --dart-define (CI/CD)
  static String get url =>
      kSupabaseUrl.isNotEmpty && kSupabaseUrl != 'https://XXXX.supabase.co'
          ? kSupabaseUrl
          : _envUrl;

  static String get anonKey =>
      kSupabaseAnonKey.isNotEmpty && kSupabaseAnonKey != 'eyJhbGci...'
          ? kSupabaseAnonKey
          : _envKey;

  /// Vrai si l'URL et la clé sont renseignées (pas les valeurs placeholder).
  static bool get isConfigured =>
      url.isNotEmpty &&
      url != 'https://XXXX.supabase.co' &&
      anonKey.isNotEmpty &&
      anonKey != 'eyJhbGci...';
}
