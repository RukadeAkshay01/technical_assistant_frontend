class AppConfig {
  // API Configuration
  static const String baseUrl = 'http://192.168.7.251:8000/v1';  // Android Emulator localhost
  // static const String baseUrl = 'http://localhost:8000/v1';  // For web/desktop testing

  // API Endpoints
  static const String messagesEndpoint = '/messages';
  static const String ttsEndpoint = '/tts';
  static const String statsEndpoint = '/stats';

  // User Configuration
  static const String userId = 'demo_user';
  static const String conversationId = 'demo_convo';
}