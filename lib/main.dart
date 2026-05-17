import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/services/knowledge_service.dart';
import 'core/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Supabase init — hata olursa app yine açılsın (offline demo için kritik).
  try {
    await Supabase.initialize(
      url: 'https://adiatsbwjkhsuicchhpl.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkaWF0c2J3amtoc3VpY2NoaHBsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg4OTY3NTcsImV4cCI6MjA5NDQ3Mjc1N30.QFgpp2znmpxOLbXPTn62Fxyz4c0ZHOILO0Ol9deqr7M',
    );
    debugPrint('✅ Supabase init OK');
  } catch (e) {
    debugPrint('⚠️ Supabase init başarısız: $e');
  }

  // 2. Hive (lokal depolama).
  try {
    await StorageService.init();
    debugPrint('✅ StorageService init OK');
  } catch (e) {
    debugPrint('⚠️ StorageService init başarısız: $e');
  }

  // 3. Status bar ayarları.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // 4. ProviderContainer hazırla. Knowledge base yüklemesi blokla değil
  //    arka planda devam etsin — runApp anında çağrılsın.
  final container = ProviderContainer();
  unawaited(_loadKnowledgeInBackground(container));

  // 5. Uygulamayı başlat.
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const YanindaApp(),
    ),
  );
}

Future<void> _loadKnowledgeInBackground(ProviderContainer container) async {
  try {
    await container.read(knowledgeServiceProvider).loadKnowledge();
    debugPrint('✅ KnowledgeService load OK');
  } catch (e) {
    debugPrint('⚠️ KnowledgeService load başarısız: $e');
  }
}
