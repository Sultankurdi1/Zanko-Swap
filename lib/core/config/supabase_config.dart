class SupabaseConfig {
  static const String url = 'https://sbjkeyhihfypoieexfga.supabase.co';

  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNiamtleWhpaGZ5cG9pZWV4ZmdhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk4ODUwODcsImV4cCI6MjEwNTQ2MTA4N30.grSaOxsePJh5Cu8TGzfO9cI20c4yI1CFmvoUekdAMQw';

  static bool get isConfigured {
    return url.isNotEmpty &&
        !url.contains('YOUR_PROJECT_ID') &&
        anonKey.isNotEmpty &&
        !anonKey.contains('YOUR_ANON_KEY_HERE');
  }
}
