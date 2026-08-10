/// Paste your Supabase project values here.
/// Dashboard → Project Settings → API Keys (or Connect → Flutter)
class SupabaseConfig {
  /// Example: https://abcdefghijklmnop.supabase.co
  static const String url = 'https://fniqkpirkencesebcrhy.supabase.co';

  /// Use the publishable / anon key (safe for the client). Never use the secret/service_role key.
  static const String publishableKey = 'sb_publishable_Cx1vv4r2SP2GEceAt4uIyA_tcuI9Qm_';

  static bool get isConfigured =>
      url.startsWith('https://') &&
      !url.contains('YOUR_SUPABASE') &&
      publishableKey.isNotEmpty &&
      !publishableKey.contains('YOUR_SUPABASE');
}
