import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:upgrade/api.dart';
import 'package:upgrade/offline/offline_store.dart';

/// Gets a 3D model onto the phone once; every later open (and offline) uses the saved file.
class ModelCache {
  static final Map<String, Future<String>> _pending = {};
  static final Map<String, String> _ready = {}; // url -> local path, already on the phone

  static String resolve(String u) =>
      u.startsWith('http://') || u.startsWith('https://') ? u : Api.imageUrl + u;

  /// Path right now if the model is already on the phone, otherwise null (no waiting, no I/O).
  static String? readyPath(String raw) {
    final url = resolve(raw);
    return _ready[url] ?? OfflineStore.localPath(url);
  }

  /// Downloads every model in [urls] up front (3 at a time) so cards open instantly.
  /// Never throws: a model that fails here is simply retried when its card opens.
  static Future<void> prefetch(Iterable<String> urls, {void Function(int done, int total)? onProgress}) async {
    final todo = urls.toSet().where((u) => readyPath(u) == null).toList();
    var done = 0;
    onProgress?.call(0, todo.length);
    var next = 0;
    Future<void> worker() async {
      while (next < todo.length) {
        final u = todo[next++];
        try { await file(u); } catch (_) {}
        onProgress?.call(++done, todo.length);
      }
    }
    await Future.wait(List.generate(todo.length < 3 ? todo.length : 3, (_) => worker()));
  }

  /// Local path of the model file, downloading it first if needed.
  static Future<String> file(String raw) {
    final url = resolve(raw);
    final offline = OfflineStore.localPath(url); // downloaded with the subject
    if (offline != null) return Future.value(offline);
    final have = _ready[url];
    if (have != null) return Future.value(have);
    return _pending.putIfAbsent(url, () async {
      try {
        final dir = Directory('${(await getApplicationSupportDirectory()).path}/models');
        await dir.create(recursive: true);
        var name = url.split('?').first.split('/').last.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
        if (!name.toLowerCase().endsWith('.glb') && !name.toLowerCase().endsWith('.gltf')) name += '.glb';
        final f = File('${dir.path}/$name');
        if (await f.exists() && await f.length() > 0) return _ready[url] = f.path;
        final tmp = '${f.path}.part';
        await Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 120),
        )).download(url, tmp);
        await File(tmp).rename(f.path);
        return _ready[url] = f.path;
      } finally {
        _pending.remove(url); // a failed download can be retried
      }
    });
  }
}
