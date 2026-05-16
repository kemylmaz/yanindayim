// Bu controller, chat ekranının anlık durumunu (mesaj listesi, yüklenme durumu) yönetir
// ve kullanıcının mesajlarını RAG destekli AI servisine ileterek ekranı günceller.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/ai_services.dart';

// Tek bir mesajın yapısını tutan model
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

// Ekranın o anki durumunu (State) tutan model
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;

  ChatState({
    required this.messages,
    required this.isLoading,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Controller'ı dışarıya açan Provider
final chatControllerProvider = StateNotifierProvider<ChatController, ChatState>((ref) {
  final aiService = ref.watch(aiServiceProvider);
  return ChatController(aiService);
});

class ChatController extends StateNotifier<ChatState> {
  final AIService _aiService;

  ChatController(this._aiService) : super(ChatState(messages: [], isLoading: false)) {
    // Modelin ilk açılışta hazır olması için tetikliyoruz
    _initModel();
  }

  Future<void> _initModel() async {
    await _aiService.initModel();
  }

  // Kullanıcı mesaj gönderdiğinde veya çiplere tıkladığında çalışan fonksiyon
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    // Kullanıcının mesajını ekrana hemen ekle ve yükleniyor durumuna geç
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
    );

    // Yapay zekadan RAG destekli cevabı bekle
    final aiResponseText = await _aiService.answerQuestion(text);

    final aiMessage = ChatMessage(
      text: aiResponseText,
      isUser: false,
      timestamp: DateTime.now(),
    );

    // Cevap geldiğinde yükleniyor durumunu kapat ve cevabı ekrana bas
    state = state.copyWith(
      messages: [...state.messages, aiMessage],
      isLoading: false,
    );
  }
}