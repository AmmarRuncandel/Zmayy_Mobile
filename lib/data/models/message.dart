/// Mirrors `utils/supabase/types.ts` → `Message`.
class Message {
  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final String createdAt;

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      content: json['content'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'sender_id': senderId,
    'receiver_id': receiverId,
    'content': content,
    'created_at': createdAt,
  };
}
