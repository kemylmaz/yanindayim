import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/victim/chat/chat_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://adiatsbwjkhsuicchhpl.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkaWF0c2J3amtoc3VpY2NoaHBsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg4OTY3NTcsImV4cCI6MjA5NDQ3Mjc1N30.QFgpp2znmpxOLbXPTn62Fxyz4c0ZHOILO0Ol9deqr7M',
  );

  await StorageService.init();
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: MyApp()));
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
