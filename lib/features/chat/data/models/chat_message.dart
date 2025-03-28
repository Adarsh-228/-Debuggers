class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final MessageType type;
  final Map<String, dynamic>? metadata; // For product data, references etc.

  ChatMessage({
    required this.content,
    required this.isUser,
    this.type = MessageType.text,
    this.metadata,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

enum MessageType {
  text,
  product,
  error,
  suggestion,
  reference, // For model-provided references
}
