import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/services/knowledge_service.dart';
import 'features/victim/chat/chat_screen.dart';

void main() async {
  // <--- async ekledik
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Bir tane ProviderContainer oluşturup uygulamadan önce veriyi yüklüyoruz
  final container = ProviderContainer();
  await container.read(knowledgeServiceProvider).loadKnowledge();

  runApp(
    UncontrolledProviderScope(
      // <--- Burayı Uncontrolled yaptıgımızda container'ı içine verebiliyoruz
      container: container,
      child: const MyApp(),
    ),
  );
}

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
