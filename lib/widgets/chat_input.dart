import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

class ChatInput extends StatefulWidget {
  final Function(String text) onSendMessage;
  final bool enabled;

  const ChatInput({
    super.key,
    required this.onSendMessage,
    required this.enabled,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final SpeechToText _speech = SpeechToText();
  final TextEditingController _controller = TextEditingController();

  bool _isListening = false;

  Future<void> _toggleMic() async {
    if (!_isListening) {
      if (!await Permission.microphone.request().isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Microphone permission denied")),
        );
        return;
      }

      final available = await _speech.initialize(
        onStatus: (status) => print("status: $status"),
        onError: (e) => print("error: $e"),
      );

      if (!available) return;

      setState(() => _isListening = true);

      _speech.listen(
        localeId: "en-IN",       // Hinglish style
        onResult: (result) {
          _controller.text = result.recognizedWords;
        },
      );
    } else {
      setState(() => _isListening = false);
      _speech.stop();

      if (_controller.text.isNotEmpty) {
        widget.onSendMessage(_controller.text);
        _controller.clear();
      }
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSendMessage(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: widget.enabled,
                decoration: InputDecoration(
                  hintText: _isListening ? "Listening..." : "Type a message...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              icon: Icon(
                _isListening ? Icons.stop : Icons.mic,
                color: _isListening ? Colors.red : Colors.grey,
              ),
              onPressed: widget.enabled ? _toggleMic : null,
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: widget.enabled ? _sendMessage : null,
            ),
          ],
        ),
      ),
    );
  }
}
