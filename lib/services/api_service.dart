import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';
import '../config/app_config.dart';
import '../models/stats_data.dart';
import 'dart:typed_data';


class ApiService {
  final String baseUrl = AppConfig.baseUrl;
  final String userId = AppConfig.userId;
  final String conversationId = AppConfig.conversationId;

  // ---------------- SEND MESSAGE ----------------
  Future<Message> sendMessage(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${AppConfig.messagesEndpoint}'), // ✅ /v1/messages
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_id": userId,
          "conversation_id": conversationId,
          "text": text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Message.fromBackend(data);
      } else {
        throw Exception("Failed to send message: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error sending message: $e");
    }
  }

  // ---------------- TTS (AUDIO) ----------------
  Future<String> getAudioBase64(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${AppConfig.ttsEndpoint}'), // ✅ /v1/tts
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_id": userId,
          "text": text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["audio_base64"];
      } else {
        throw Exception("Failed to fetch audio: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetch audio: $e");
    }
  }

  // ---------------- GET CONVERSATION HISTORY ----------------
  // ---------------- GET CONVERSATION HISTORY ----------------
  Future<List<Message>> getConversationHistory() async {
    try {
      final url = Uri.parse(
          '$baseUrl/v1/conversations/$userId/$conversationId');

      print("Fetching conversation from: $url");
      final response = await http.get(url);

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> messagesJson = decoded['messages'] ?? [];

        return messagesJson.map((msg) {
          return Message(
            text: msg["payload"]["text"] ?? "",
            isUser: msg["direction"] == "user",
            timestamp: msg["created_at"] != null
                ? DateTime.parse(msg["created_at"]) // ✅ FIX HERE
                : DateTime.now(),
            metadata: msg["payload"]["meta"]?["structured"],
          );
        }).toList();
      } else {
        throw Exception("Failed to load history: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error loading history: $e");
    }
  }

  Future<String> transcribeSTT(Uint8List audioBytes) async {
    final response = await http.post(
      Uri.parse("$baseUrl/v1/stt"),
      headers: {"Content-Type": "application/octet-stream"},
      body: audioBytes,
    );

    final data = jsonDecode(response.body);
    return data["transcript"] ?? "";
  }





  // ---------------- STATS (based on history) ----------------
  Future<StatsData> getStatsData() async {
    try {
      final history = await getConversationHistory();

      int jobsCompleted = 0;
      double totalEarnings = 0;
      double totalExpenses = 0;
      int activeJobs = 0;
      Map<int, double> monthlyEarnings = {};

      for (var msg in history) {
        if (!msg.isUser && msg.metadata != null) {
          final structured = msg.metadata!;

          if (structured["intent"] == "job_completed") jobsCompleted++;
          if (structured["status"] == "active") activeJobs++;

          // ✅ SAFELY HANDLE NULL AMOUNT
          final rawAmount = structured["amount"];
          final amount = (rawAmount == null)
              ? 0.0
              : double.tryParse(rawAmount.toString()) ?? 0.0;

          if (amount > 0) {
            if (structured["type"] == "income") {
              totalEarnings += amount;
            } else if (structured["type"] == "expense") {
              totalExpenses += amount;
            }
          }
        }
      }

      return StatsData(
        jobsCompleted: jobsCompleted,
        totalEarnings: totalEarnings,
        totalExpenses: totalExpenses,
        activeJobs: activeJobs,
        monthlyEarnings: const [],
      );
    } catch (e) {
      throw Exception("Error calculating stats: $e");
    }
  }

}