// Bu ekran, kullanıcının çevrimdışı yapay zeka asistanıyla mesajlaşmasını sağlar.
// Ses tanıma servisiyle (Speech-to-Text) entegre çalışarak sesli komutları metne çevirir.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/speech_service.dart';
import 'chat_controller.dart';

// Mikrofonun anlık olarak dinleme yapıp yapmadığını tutan basit bir UI State Provider
final isListeningProvider = StateProvider<bool>((ref) => false);

class ChatScreen extends ConsumerWidget {
  ChatScreen({super.key});

  final TextEditingController _textController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatControllerProvider);
    final chatController = ref.read(chatControllerProvider.notifier);

    // Ses servisimiz ve mikrofonun durumunu dinliyoruz
    final speechService = ref.watch(speechServiceProvider);
    final isListening = ref.watch(isListeningProvider);

    final quickQuestions = [
      "Toplanma alanı nerede?",
      "İlk yardım",
      "Yıkıntı altındayım",
      "Çocuğum nerede?",
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4EDE0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F3D2E),
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              "Çevrimdışı Asistan",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Çevrimdışı Durum Bandı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: const Color(0xFF4CAF7A).withValues(alpha: 0.2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.circle,
                  color: isListening ? Colors.red : const Color(0xFF4CAF7A),
                  size: 12,
                ),
                const SizedBox(width: 8),
                Text(
                  isListening
                      ? "🎙️ Şu an sesiniz dinleniyor, konuşun..."
                      : "İnternet olmadan yanındayım — çevrimdışı asistan",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isListening ? Colors.red.shade800 : Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // Mesaj Listesi
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount:
                  chatState.messages.length + (chatState.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == chatState.messages.length && chatState.isLoading) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        "Yapay zeka düşünüyor...",
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  );
                }

                final message = chatState.messages[index];
                final isUser = message.isUser;

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF0F3D2E) : Colors.white,
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: isUser ? const Radius.circular(0) : null,
                        bottomLeft: !isUser ? const Radius.circular(0) : null,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: isUser ? Colors.white : const Color(0xFF2A2A2A),
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Hızlı Sorular (Chips)
          if (!chatState.isLoading)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: quickQuestions
                    .map(
                      (q) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(q),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF0F3D2E)),
                          onPressed: () {
                            chatController.sendMessage(q);
                          },
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

          // Alt Metin ve Ses Giriş Alanı
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: isListening
                          ? "Konuşmanız metne dökülüyor..."
                          : "Soru sor veya seslen...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF4EDE0),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: (val) {
                      chatController.sendMessage(val);
                      _textController.clear();
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // JÜRİYİ ETKİLEYECEK GERÇEK SES BUTONU
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isListening
                      ? Colors.red
                      : const Color(0xFF4CAF7A),
                  child: IconButton(
                    icon: Icon(
                      isListening ? Icons.stop : Icons.mic,
                      color: Colors.white,
                    ),
                    onPressed: () async {
                      if (isListening) {
                        // Eğer zaten dinliyorsa durdur
                        await speechService.stopListening();
                        ref.read(isListeningProvider.notifier).state = false;
                      } else {
                        // Dinlemiyorsa dinlemeyi başlat
                        ref.read(isListeningProvider.notifier).state = true;
                        await speechService.startListening(
                          onResult: (recognizedText) {
                            // Sesten gelen kelimeleri anlık olarak yazı alanına dolduruyoruz
                            _textController.text = recognizedText;
                          },
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF0F3D2E),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      chatController.sendMessage(_textController.text);
                      _textController.clear();
                      // Ses açık kaldıysa güvenli kapatma
                      if (ref.read(isListeningProvider)) {
                        speechService.stopListening();
                        ref.read(isListeningProvider.notifier).state = false;
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
