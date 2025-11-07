import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:typed_data';
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with AutomaticKeepAliveClientMixin {

  final List<Message> _messages = [];
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  final AudioPlayer _audioPlayer = AudioPlayer();  // from just_audio

  bool _isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('AI Assistant'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ChatBubble(message: message)
                    .animate()
                    .fadeIn()
                    .slideX(
                  begin: message.isUser ? 0.3 : -0.3,
                  duration: const Duration(milliseconds: 200),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          ChatInput(
            onSendMessage: _handleSendMessage,
            enabled: !_isLoading,
          ),
        ],
      ),
    );
  }

  Future<void> _handleSendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(Message(text: text, isUser: true, timestamp: DateTime.now()));
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final response = await _apiService.sendMessage(text);

      setState(() => _messages.add(response));
      _scrollToBottom();

      print("🎤 Requesting TTS...");
      final audioBase64 = await _apiService.getAudioBase64(response.text);

      final Uint8List audioBytes = base64Decode(audioBase64);
      print("🎧 Audio bytes length: ${audioBytes.length}");

      /// ✅ Convert to in-memory audio URI (Fixes Cleartext Error)
      final uri = Uri.dataFromBytes(
        audioBytes,
        mimeType: "audio/mpeg",
      );

      await _audioPlayer.stop();
      await _audioPlayer.setUrl(uri.toString());
      await _audioPlayer.play();

      print("✅ Played successfully");

    } catch (e) {
      print("❌ ERROR: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error playing audio: $e")),
        );
      }
    }

    setState(() => _isLoading = false);
    _scrollToBottom();
  }



  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
