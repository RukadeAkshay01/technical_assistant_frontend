class AppConfig {
  // API Configuration
  static const String baseUrl = 'https://technical-backend-598525817487.asia-south1.run.app';  // Production backend URL

  // API Endpoints
  static const String messagesEndpoint = '/v1/messages';
  static const String ttsEndpoint = '/v1/tts';
  static const String sttEndpoint = '/v1/stt';
  static const String statsEndpoint = '/v1/stats';
  static const String historyEndpoint = '/v1/conversations';


  // User Configuration
  static const String userId = 'demo_user';
  static const String conversationId = 'demo_convo';
}