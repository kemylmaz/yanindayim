// Durum yönetimi ve sohbet mantığını içeren chat_controller.dart dosyası

import 'package:flutter_riverpod/flutter_riverpod.dart';

// AI Servisimizi import ediyoruz
import '../../../core/services/ai_services.dart';

// Mesaj Modelimiz
class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

// Ekranın Durumu (Mesaj listesi ve Yükleniyor durumu)
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  ChatState({required this.messages, this.isLoading = false});
}

// Riverpod Provider'ımız
final chatControllerProvider = StateNotifierProvider<ChatController, ChatState>(
  (ref) {
    return ChatController(ref.read(aiServiceProvider));
  },
);

class ChatController extends StateNotifier<ChatState> {
  final AIService _aiService;

  ChatController(this._aiService)
    : super(
        ChatState(
          messages: [
            // İlk açılışta AI'ın atacağı karşılama mesajı
            ChatMessage(
              text:
                  "Merhaba. İnternet bağlantısı olmadan da yanındayım. AFAD ve Kızılay verileriyle sana yardım etmeye hazırım. Ne öğrenmek istersin?",
              isUser: false,
            ),
          ],
        ),
      );

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 1. Kullanıcı mesajını ekle ve yükleniyor durumuna geç
    state = ChatState(
      messages: [
        ...state.messages,
        ChatMessage(text: text, isUser: true),
      ],
      isLoading: true,
    );

    // 2. RAG destekli AI'dan yanıt al
    final response = await _aiService.generateResponse(text);

    // 3. AI yanıtını ekle ve yükleniyor durumunu bitir
    state = ChatState(
      messages: [
        ...state.messages,
        ChatMessage(text: response, isUser: false),
      ],
      isLoading: false,
    );
  }
}
