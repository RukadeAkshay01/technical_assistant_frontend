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
      // First, get the conversation history
      final messages = await getConversationHistory();
      
      // Initialize counters
      int jobsCompleted = 0;
      double totalEarnings = 0;
      double totalExpenses = 0;
      int activeJobs = 0;
      Map<int, double> monthlyEarnings = {};

      // Process each message to extract stats
      for (final message in messages) {
        if (!message.isUser && message.metadata != null) {
          final meta = message.metadata!;
          
          // Extract job counts and amounts from metadata
          if (meta.containsKey('structured')) {
            final structured = meta['structured'] as Map<String, dynamic>?;
            if (structured != null) {
              // Count completed jobs
              if (structured.containsKey('intent') && 
                  structured['intent'] == 'job_completed') {
                jobsCompleted++;
              }
              
              // Add earnings
              if (structured.containsKey('amount')) {
                final amount = double.tryParse(structured['amount'].toString()) ?? 0.0;
                if (structured['type'] == 'income') {
                  totalEarnings += amount;
                  
                  // Add to monthly earnings
                  final month = DateTime.now().month - 1; // 0-based month
                  monthlyEarnings[month] = (monthlyEarnings[month] ?? 0) + amount;
                } else if (structured['type'] == 'expense') {
                  totalExpenses += amount;
                }
              }
              
              // Count active jobs
              if (structured.containsKey('status') && 
                  structured['status'] == 'active') {
                activeJobs++;
              }
            }
          }
        }
      }

      // Convert monthly earnings to list format
      final monthlyEarningsList = monthlyEarnings.entries
          .map((e) => MonthlyEarning(month: e.key, earning: e.value))
          .toList()
        ..sort((a, b) => a.month.compareTo(b.month));

      // Create and return StatsData object
      return StatsData(
        jobsCompleted: jobsCompleted,
        totalEarnings: totalEarnings,
        totalExpenses: totalExpenses,
        activeJobs: activeJobs,
        monthlyEarnings: monthlyEarningsList,
      );
    } catch (e) {
      throw Exception('Error calculating stats: $e');
    }
  }

  Future<List<Message>> getConversationHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/conversations/$userId/$conversationId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
        if (!data.containsKey('messages')) {
          print('Warning: Response does not contain messages key. Response: $data');
          return [];
        }
        final List<dynamic> messagesJson = data['messages'] as List<dynamic>;
        return messagesJson.map((dynamic msg) {
          final Map<String, dynamic> msgMap = msg as Map<String, dynamic>;
          // Convert Firestore message format to our Message model
          final Map<String, dynamic> payload = msgMap['payload'] as Map<String, dynamic>;
          return Message(
            text: payload['text'] as String,
            isUser: msgMap['direction'] == 'user',
            timestamp: msgMap['created_at'] != null 
                ? DateTime.parse(msgMap['created_at'] as String)
                : DateTime.now(),
            metadata: payload['meta'] as Map<String, dynamic>?,
          );
        }).toList();
      } else {
        throw Exception('Failed to load history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading history: $e');
    }
  }
}
