import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Tile'ları yerel diske önbelleğe alan basit TileProvider.
///
/// İlk açılışta ağdan indirir, sonra offline çalışır. Hackathon demosu için
/// kullanıcı haritayı bir kez çevrimiçi açtıktan sonra çevrimdışı erişebilir.
class CachedTileProvider extends TileProvider {
  CachedTileProvider({this.userAgent = 'com.appjam.yaninda'});

  final String userAgent;
  Directory? _cacheDir;

  Future<Directory> _ensureCacheDir() async {
    if (_cacheDir != null) return _cacheDir!;
    final base = await getApplicationCacheDirectory();
    final dir = Directory('${base.path}/map_tiles');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cacheDir = dir;
    return dir;
  }

  String _keyFor(TileCoordinates coords) =>
      '${coords.z}_${coords.x}_${coords.y}.png';

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);
    return _CachedTileImage(
      url: url,
      key: _keyFor(coordinates),
      cacheDir: _ensureCacheDir(),
      userAgent: userAgent,
    );
  }
}

class _CachedTileImage extends ImageProvider<_CachedTileImage> {
  const _CachedTileImage({
    required this.url,
    required this.key,
    required this.cacheDir,
    required this.userAgent,
  });

  final String url;
  final String key;
  final Future<Directory> cacheDir;
  final String userAgent;

  @override
  Future<_CachedTileImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _CachedTileImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadCodec(decode),
      scale: 1.0,
      debugLabel: url,
    );
  }

  Future<Codec> _loadCodec(ImageDecoderCallback decode) async {
    final dir = await cacheDir;
    final file = File('${dir.path}/$key');

    Uint8List bytes;
    if (await file.exists()) {
      bytes = await file.readAsBytes();
    } else {
      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {'User-Agent': userAgent},
        );
        if (response.statusCode != 200) {
          throw Exception('Tile fetch failed: ${response.statusCode}');
        }
        bytes = response.bodyBytes;
        unawaited(file.writeAsBytes(bytes, flush: false));
      } catch (e) {
        // Offline ve cache'de yok — boş tile döndürmek yerine hata fırlatıp
        // flutter_map'in errorImage'ını göstermesine izin ver.
        rethrow;
      }
    }

    return decode(await ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _CachedTileImage && other.url == url;
  }

  @override
  int get hashCode => url.hashCode;
}
