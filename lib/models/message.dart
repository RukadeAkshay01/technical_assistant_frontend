class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  Message({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.metadata,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    // Handle both direct API response and Firestore message format
    if (json.containsKey('payload')) {
      final payload = json['payload'] as Map<String, dynamic>;
      return Message(
        text: payload['text'] as String,
        isUser: json['direction'] == 'user',
        timestamp: json['created_at'] != null 
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
        metadata: payload['meta'] as Map<String, dynamic>?,
      );
    }
    
    return Message(
      text: json['text'] as String,
      isUser: json['isUser'] as bool? ?? false,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}