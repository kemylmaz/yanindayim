import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/services/storage_service.dart';
import 'core/services/knowledge_service.dart';
import 'features/victim/chat/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Kemal'in eklediği Supabase ve Storage servisleri başlatılıyor
  await Supabase.initialize(
    url: 'https://adiatsbwjkhsuicchhpl.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkaWF0c2J3amtoc3VpY2NoaHBsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg4OTY3NTcsImV4cCI6MjA5NDQ3Mjc1N30.QFgpp2znmpxOLbXPTn62Fxyz4c0ZHOILO0Ol9deqr7M',
  );
  await StorageService.init();

  // 2. Ortak arayüz ayarları
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // 3. Senin AI Bilgi Bankası servisinin yüklenmesi
  final container = ProviderContainer();
  await container.read(knowledgeServiceProvider).loadKnowledge();

  // 4. Uygulamanın başlatılması
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(), 
    ),
  );
}

// NOT: Eğer Kemal 'app.dart' dosyasının içine MyApp sınıfını taşıdıysa 
// aşağıdaki class MyApp kısmını tamamen silebilirsiniz. Şimdilik hata vermemesi için bırakıyorum.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yanında',
      debugShowCheckedModeBanner: false,
      home: ChatScreen(), // Uygulama senin yazdığın AI ekranıyla açılıyor
    );
  }
}