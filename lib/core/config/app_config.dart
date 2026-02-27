/// Application configuration
/// Loaded from environment variables - never hardcode secrets
class AppConfig {
  static const String appName = 'الفال';
  static const String appVersion = '0.1.0';

  // ERPNext Backend
  static const String erpnextUrl = String.fromEnvironment(
    'ERPNEXT_URL',
    defaultValue: 'https://w.alfal.co',
  );

  // n8n Automation
  static const String n8nUrl = String.fromEnvironment(
    'N8N_URL',
    defaultValue: 'https://w.alfal.co:5443',
  );

  // Claude AI
  static const String claudeApiKey = String.fromEnvironment('CLAUDE_API_KEY');

  // Evolution API (WhatsApp)
  static const String evolutionApiUrl = String.fromEnvironment(
    'EVOLUTION_API_URL',
    defaultValue: 'https://w.alfal.co:8085',
  );
  static const String evolutionApiKey =
      String.fromEnvironment('EVOLUTION_API_KEY');

  // API Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Offline sync
  static const Duration syncInterval = Duration(minutes: 5);
  static const int maxRetries = 3;
}
