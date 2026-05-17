// Çevrimdışı asistan ekranı. Bilgi bankasından (RAG) gelen bağlamla yanıt verir;
// mikrofonla Türkçe konuşma -> metne dökme entegrasyonu var.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/speech_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import 'chat_controller.dart';

final isListeningProvider = StateProvider<bool>((ref) => false);

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  static const _quickQuestions = <_QuickQuestion>[
    _QuickQuestion(
      icon: Icons.warning_amber_rounded,
      label: 'Enkaz altındayım',
      query: 'Enkaz altındayım ne yapmalıyım?',
    ),
    _QuickQuestion(
      icon: Icons.local_hospital_rounded,
      label: 'Kanama nasıl durdurulur',
      query: 'Yarada kanama nasıl durdurulur?',
    ),
    _QuickQuestion(
      icon: Icons.bolt_rounded,
      label: 'Artçı sarsıntı',
      query: 'Artçı sarsıntıdan korunmak için ne yapmalıyım?',
    ),
    _QuickQuestion(
      icon: Icons.water_drop_rounded,
      label: 'Su nasıl bulunur',
      query: 'Enkaz altında veya sonrasında su nasıl bulunur?',
    ),
    _QuickQuestion(
      icon: Icons.battery_alert_rounded,
      label: 'Pil tasarrufu',
      query: 'Telefonun pilini deprem sonrası nasıl tasarruflu kullanırım?',
    ),
    _QuickQuestion(
      icon: Icons.spa_rounded,
      label: 'Panik atak',
      query: 'Panik atak yaşıyorum ne yapmalıyım?',
    ),
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send(String text, ChatController controller) {
    if (text.trim().isEmpty) return;
    controller.sendMessage(text.trim());
    _textController.clear();
    _stopListeningIfActive();
    // Sonraki frame'de scroll alta
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _toggleListening(SpeechService speech) async {
    final isListening = ref.read(isListeningProvider);
    if (isListening) {
      await speech.stopListening();
      ref.read(isListeningProvider.notifier).state = false;
      return;
    }
    ref.read(isListeningProvider.notifier).state = true;
    await speech.startListening(
      onResult: (recognized) {
        if (!mounted) return;
        _textController.text = recognized;
        _textController.selection =
            TextSelection.collapsed(offset: recognized.length);
      },
    );
  }

  void _stopListeningIfActive() {
    if (ref.read(isListeningProvider)) {
      ref.read(speechServiceProvider).stopListening();
      ref.read(isListeningProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider);
    final chatController = ref.read(chatControllerProvider.notifier);
    final speechService = ref.watch(speechServiceProvider);
    final isListening = ref.watch(isListeningProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _BackgroundGradient(),
          SafeArea(
            child: Column(
              children: [
                _Header(
                  onBack: () => context.canPop()
                      ? context.pop()
                      : context.go('/victim'),
                  isListening: isListening,
                ),
                Expanded(
                  child: chatState.messages.isEmpty && !chatState.isLoading
                      ? _EmptyState(
                          onAsk: (q) => _send(q, chatController),
                          quickQuestions: _quickQuestions,
                        )
                      : _MessageList(
                          controller: _scrollController,
                          messages: chatState.messages,
                          isLoading: chatState.isLoading,
                        ),
                ),
                if (chatState.messages.isNotEmpty)
                  _QuickQuestionStrip(
                    questions: _quickQuestions,
                    onTap: (q) => _send(q.query, chatController),
                  ),
                _Composer(
                  controller: _textController,
                  isListening: isListening,
                  onMic: () => _toggleListening(speechService),
                  onSend: () => _send(_textController.text, chatController),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────── header ────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.isListening});

  final VoidCallback onBack;
  final bool isListening;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.primaryDeep,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.teal, AppColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.smart_toy_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Çevrimdışı Asistan',
                          style: AppTypography.headlineMedium.copyWith(
                            fontSize: 16,
                            color: AppColors.primaryDeep,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isListening
                                    ? AppColors.critical
                                    : AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isListening
                                  ? 'Sesinizi dinliyorum…'
                                  : 'İnternet gerekmez',
                              style: AppTypography.labelSmall.copyWith(
                                color: isListening
                                    ? AppColors.critical
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.wifi_off_rounded,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────── empty state ───────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAsk, required this.quickQuestions});

  final ValueChanged<String> onAsk;
  final List<_QuickQuestion> quickQuestions;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.teal, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
                duration: 400.ms,
                curve: Curves.easeOutCubic,
              ),
          const SizedBox(height: 18),
          Text(
            'İnternet gerekmez — yanındayım',
            textAlign: TextAlign.center,
            style: AppTypography.headlineLarge.copyWith(
              fontSize: 22,
              color: AppColors.primaryDeep,
              fontWeight: FontWeight.w800,
            ),
          ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 8),
          Text(
            'Cihazında yüklü bilgi bankasından sana panik yapmadan, '
            'kısa ve net bilgiler veririm. Aşağıdaki sorulardan birine bas '
            'ya da kendi sorunu yaz.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ).animate(delay: 150.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 22),
          ...List.generate(quickQuestions.length, (i) {
            final q = quickQuestions[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SuggestionCard(
                question: q,
                onTap: () => onAsk(q.query),
              ).animate(delay: (200 + i * 50).ms).fadeIn(duration: 350.ms),
            );
          }),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.question, required this.onTap});

  final _QuickQuestion question;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                question.icon,
                color: AppColors.primaryDeep,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                question.label,
                style: AppTypography.bodyLarge.copyWith(
                  fontSize: 15,
                  color: AppColors.primaryDeep,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────── message list ──────────────────────────────

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.controller,
    required this.messages,
    required this.isLoading,
  });

  final ScrollController controller;
  final List<ChatMessage> messages;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final itemCount = messages.length + (isLoading ? 1 : 0);
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (isLoading && index == messages.length) {
          return const _TypingBubble();
        }
        final msg = messages[index];
        return _MessageBubble(message: msg)
            .animate()
            .fadeIn(duration: 250.ms)
            .moveY(begin: 8, end: 0, duration: 250.ms);
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            gradient: isUser
                ? const LinearGradient(
                    colors: [AppColors.primarySoft, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isUser ? null : AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 18),
            ),
            border: isUser ? null : Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            message.text,
            style: AppTypography.bodyMedium.copyWith(
              color: isUser ? AppColors.textOnPrimary : AppColors.primaryDeep,
              height: 1.45,
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomLeft: const Radius.circular(4),
          ),
          border: Border.all(color: AppColors.border),
        ),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final phase = ((_c.value + i / 3) % 1.0);
                final scale = 0.6 + (1 - (phase - 0.5).abs() * 2).clamp(0, 1) * 0.6;
                return Padding(
                  padding: EdgeInsets.only(right: i == 2 ? 0 : 4),
                  child: Container(
                    width: 7 * scale,
                    height: 7 * scale,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

// ──────────────────────────────── quick question strip ──────────────────────

class _QuickQuestionStrip extends StatelessWidget {
  const _QuickQuestionStrip({required this.questions, required this.onTap});

  final List<_QuickQuestion> questions;
  final void Function(_QuickQuestion) onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: questions.length,
        separatorBuilder: (context, i) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final q = questions[i];
          return InkWell(
            onTap: () => onTap(q),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(q.icon, color: AppColors.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    q.label,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primaryDeep,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ──────────────────────────────── composer ──────────────────────────────────

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.isListening,
    required this.onMic,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isListening;
  final VoidCallback onMic;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        12 + MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Mikrofon
          GestureDetector(
            onTap: onMic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isListening ? AppColors.critical : AppColors.teal,
                boxShadow: [
                  BoxShadow(
                    color: (isListening ? AppColors.critical : AppColors.teal)
                        .withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                isListening ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Text field
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primaryDeep,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText:
                    isListening ? 'Konuş, yazıya döküyorum…' : 'Soruyu yaz…',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                filled: true,
                fillColor: AppColors.surfaceTint,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: 8),
          // Gönder
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primarySoft, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────── data ──────────────────────────────────────

class _QuickQuestion {
  const _QuickQuestion({
    required this.icon,
    required this.label,
    required this.query,
  });

  final IconData icon;
  final String label;
  final String query;
}

class _BackgroundGradient extends StatelessWidget {
  const _BackgroundGradient();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundTop,
              AppColors.background,
              AppColors.backgroundBottom,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}
