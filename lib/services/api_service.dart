import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';
import '../config/app_config.dart';
import '../models/stats_data.dart';

class ApiService {
  final String baseUrl = AppConfig.baseUrl;
  final String userId = AppConfig.userId;
  final String conversationId = AppConfig.conversationId;

  Future<Message> sendMessage(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${AppConfig.messagesEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'conversation_id': conversationId,
          'text': text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Message.fromJson(data);
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  Future<String> getAudioUrl(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${AppConfig.ttsEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'] as String;
      } else {
        throw Exception('Failed to get audio URL: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting audio URL: $e');
    }
  }

  Future<StatsData> getStatsData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${AppConfig.statsEndpoint}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return StatsData.fromJson(data);
      } else {
        throw Exception('Failed to load stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading stats: $e');
    }
  }

  Future<List<Message>> getConversationHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/v1/conversations/$userId/$conversationId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> messagesJson = data['messages'];
        return messagesJson.map((json) => Message.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading history: $e');
    }
  }
}
