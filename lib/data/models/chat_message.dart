class ChatMessage {
  final String id;
  final String senderId;
  final String content;
  final String createdAt;
  final String? senderUsername;

  ChatMessage({required this.id, required this.senderId, required this.content, required this.createdAt, this.senderUsername});

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    String? extractUsername(dynamic val) {
      if (val == null) return null;
      if (val is Map && val['username'] != null) return val['username'].toString();
      return null;
    }

    return ChatMessage(
      id: json['id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      senderUsername: json['sender_username'] as String? ?? extractUsername(json['sender_profile']),
    );
  }
}
