import 'dart:developer' as developer;

import '../../core/api_client.dart';
import '../models/chat_message.dart';

class ChatRepository {
  final ApiClient _client = ApiClient();

  /// ENDPOINT MUTLAK: GET /api/chat/history
  Future<List<ChatMessage>> getChatHistory() async {
    final resp = await _client.get('/api/chat/history');
    if (resp == null) {
      developer.log('[Chat Sync] Riwayat chat kosong', level: 800);
      return <ChatMessage>[];
    }

    final list = _extractList(resp);

    developer.log('[Chat Sync] Ditemukan ${list.length} pesan', level: 800);

    return list.map<ChatMessage>((e) {
      if (e is Map<String, dynamic>) return ChatMessage.fromJson(e);
      return ChatMessage.fromJson(Map<String, dynamic>.from(e as Map));
    }).toList();
  }

  /// ENDPOINT MUTLAK: POST /api/chat/send
  /// Backend Next.js menerima: { content, receiver_id? }
  /// CATATAN: image_url TIDAK ADA di schema Supabase
  Future<ChatMessage> sendMessage(String message, {String? imageUrl}) async {
    final body = <String, dynamic>{
      'content': message,
    };
    
    developer.log('[Chat Send] Mengirim pesan global: ${message.substring(0, message.length > 50 ? 50 : message.length)}...', level: 800);
    
    final resp = await _client.post('/api/chat/send', body);

    // resp expected to be an object (inserted row)
    if (resp is Map<String, dynamic>) {
      return ChatMessage.fromJson(resp);
    }

    // If wrapped in data
    if (resp is Map && resp['data'] is Map) {
      return ChatMessage.fromJson(Map<String, dynamic>.from(resp['data'] as Map));
    }

    throw Exception('Unexpected response from sendMessage');
  }

  // ── DM (1-on-1) endpoints ───────────────────────────────────────────────────
  
  Future<List<ChatMessage>> getDirectHistory(String friendId) async {
    try {
      // Try DM endpoint with friend_id query parameter
      final resp = await _client.get('/api/chat/history?friend_id=$friendId');
      if (resp == null) {
        developer.log('[DM Sync] Riwayat DM kosong dengan friend: $friendId', level: 800);
        return <ChatMessage>[];
      }

      final list = _extractList(resp);
      developer.log('[DM Sync] Ditemukan ${list.length} pesan dengan friend: $friendId', level: 800);
      
      return list.map<ChatMessage>((e) {
        if (e is Map<String, dynamic>) return ChatMessage.fromJson(e);
        return ChatMessage.fromJson(Map<String, dynamic>.from(e as Map));
      }).toList(growable: false);
    } catch (e) {
      // FALLBACK: If DM endpoint doesn't exist, use global chat history
      developer.log('[DM Sync] DM endpoint not available, falling back to global chat', level: 800);
      return getChatHistory();
    }
  }

  Future<ChatMessage> sendDirectMessage(String friendId, String message, {String? imageUrl}) async {
    // CRITICAL FIX: Kolom 'image_url' TIDAK ADA di tabel messages Supabase
    // Hanya kirim 'content' dan 'receiver_id'
    final body = <String, dynamic>{
      'content': message,
      'receiver_id': friendId,
    };
    
    developer.log('[DM Send] Mengirim DM ke friend: $friendId | Message: ${message.substring(0, message.length > 30 ? 30 : message.length)}...', level: 800);
    
    final resp = await _client.post('/api/chat/send', body);

    if (resp is Map<String, dynamic>) {
      return ChatMessage.fromJson(resp);
    }
    if (resp is Map && resp['data'] is Map) {
      return ChatMessage.fromJson(Map<String, dynamic>.from(resp['data'] as Map));
    }
    throw Exception('Unexpected response from sendDirectMessage');
  }

  /// Defensif JSON extractor - handles various response formats
  List<dynamic> _extractList(dynamic resp) {
    if (resp == null) return <dynamic>[];
    if (resp is List) return resp;
    if (resp is Map) {
      final map = Map<String, dynamic>.from(resp);
      // Try common wrapper keys
      if (map['data'] is List) return map['data'] as List;
      if (map['messages'] is List) return map['messages'] as List;
      if (map['items'] is List) return map['items'] as List;
    }
    return <dynamic>[];
  }
}
