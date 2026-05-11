import '../../core/api_client.dart';
import '../models/chat_message.dart';

class ChatRepository {
  final ApiClient _client = ApiClient();

  Future<List<ChatMessage>> getChatHistory() async {
    final resp = await _client.get('/api/chat/history');
    if (resp == null) return <ChatMessage>[];

    final list = resp is List ? resp : (resp is Map && resp['data'] is List ? resp['data'] as List : <dynamic>[]);

    return list.map<ChatMessage>((e) {
      if (e is Map<String, dynamic>) return ChatMessage.fromJson(e);
      return ChatMessage.fromJson(Map<String, dynamic>.from(e as Map));
    }).toList();
  }

  Future<ChatMessage> sendMessage(String message, {String? imageUrl}) async {
    final body = {'message': message, 'image_url': imageUrl};
    final resp = await _client.post('/api/chat/send', body);

    // resp expected to be an object (inserted row)
    if (resp is Map<String, dynamic>) {
      return ChatMessage.fromJson(resp);
    }

    // If wrapped in data
    if (resp is Map && resp['data'] is Map) {
      return ChatMessage.fromJson(Map<String, dynamic>.from(resp['data']));
    }

    throw Exception('Unexpected response from sendMessage');
  }

  // ── DM (1-on-1) endpoints — required for Phase 3 ───────────────────────────
  Future<List<ChatMessage>> getDirectHistory(String friendId) async {
    final resp = await _client.get('/api/chat/dm/history?friend_id=$friendId');
    if (resp == null) return <ChatMessage>[];

    final list = resp is List ? resp : (resp is Map && resp['data'] is List ? resp['data'] as List : <dynamic>[]);
    return list.map<ChatMessage>((e) {
      if (e is Map<String, dynamic>) return ChatMessage.fromJson(e);
      return ChatMessage.fromJson(Map<String, dynamic>.from(e as Map));
    }).toList(growable: false);
  }

  Future<ChatMessage> sendDirectMessage(String friendId, String message, {String? imageUrl}) async {
    final body = {'receiver_id': friendId, 'message': message, 'image_url': imageUrl};
    final resp = await _client.post('/api/chat/dm/send', body);

    if (resp is Map<String, dynamic>) {
      return ChatMessage.fromJson(resp);
    }
    if (resp is Map && resp['data'] is Map) {
      return ChatMessage.fromJson(Map<String, dynamic>.from(resp['data']));
    }
    throw Exception('Unexpected response from sendDirectMessage');
  }
}
