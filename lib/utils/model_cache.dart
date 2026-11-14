import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:upgrade/api.dart';
import 'package:upgrade/offline/offline_store.dart';

/// Gets a 3D model onto the phone once; every later open (and offline) uses the saved file.
class ModelCache {
  static final Map<String, Future<String>> _pending = {};

  static String resolve(String u) =>
      u.startsWith('http://') || u.startsWith('https://') ? u : Api.imageUrl + u;

  /// Local path of the model file, downloading it first if needed.
  static Future<String> file(String raw) {
    final url = resolve(raw);
    final offline = OfflineStore.localPath(url); // downloaded with the subject
    if (offline != null) return Future.value(offline);
    return _pending.putIfAbsent(url, () async {
      try {
        final dir = Directory('${(await getApplicationSupportDirectory()).path}/models');
        await dir.create(recursive: true);
        var name = url.split('?').first.split('/').last.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
        if (!name.toLowerCase().endsWith('.glb') && !name.toLowerCase().endsWith('.gltf')) name += '.glb';
        final f = File('${dir.path}/$name');
        if (await f.exists() && await f.length() > 0) return f.path;
        final tmp = '${f.path}.part';
        await Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 120),
        )).download(url, tmp);
        await File(tmp).rename(f.path);
        return f.path;
      } finally {
        _pending.remove(url); // a failed download can be retried
      }
    });
  }
}
