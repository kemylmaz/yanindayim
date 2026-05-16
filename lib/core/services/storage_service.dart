import 'package:hive_flutter/hive_flutter.dart';

import '../models/user.dart';
import '../models/user_mode.dart';
import '../models/emergency_contact.dart';
import '../models/rescuer_credentials.dart';
import '../models/beacon.dart';
import '../models/knowledge_chunk.dart';

class StorageService {
  static const String userBoxName = 'userBox';
  static const String beaconBoxName = 'beaconBox';
  static const String knowledgeBoxName = 'knowledgeBox';

  static Future<void> init() async {
    // 1. Hive'ı cihaz diskinde Flutter için yapılandır
    await Hive.initFlutter();

    // 2. Adapter'ları (Type ID'leri) kaydet
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(UserModeAdapter());
    Hive.registerAdapter(EmergencyContactAdapter());
    Hive.registerAdapter(RescuerCredentialsAdapter());
    Hive.registerAdapter(BeaconAdapter());
    Hive.registerAdapter(KnowledgeChunkAdapter());

    // 3. İhtiyacımız olan kutuları (veri tablolarını) aç
    await Hive.openBox<User>(userBoxName);
    await Hive.openBox<Beacon>(beaconBoxName);
    await Hive.openBox<KnowledgeChunk>(knowledgeBoxName);
  }

  // Box'lara kolay erişim için getter metodlar
  static Box<User> get userBox => Hive.box<User>(userBoxName);
  static Box<Beacon> get beaconBox => Hive.box<Beacon>(beaconBoxName);
  static Box<KnowledgeChunk> get knowledgeBox => Hive.box<KnowledgeChunk>(knowledgeBoxName);
}
