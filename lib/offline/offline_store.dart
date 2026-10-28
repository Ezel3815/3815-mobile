import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:upgrade/api.dart';
import 'package:upgrade/controllers/api_controller.dart';
import 'package:upgrade/entity/card_entity.dart';
import 'package:upgrade/entity/deck_entity.dart';
import 'package:upgrade/di.dart';
import 'package:upgrade/main.dart' show sharedPref;
import 'package:upgrade/network_info.dart';

/// Downloaded study material: card text lives in the existing Hive cache (filled by
/// ApiController.fetchCards); this class makes sure the PICTURES and attached FILES are
/// saved on the phone for good, and remembers which subjects the user downloaded.
class OfflineStore {
  static const _regKey = 'offline_registry_v1';
  static late Directory _mediaDir;
  static late Directory _docsDir;
  static final Set<String> _files = {};
  static Map<String, dynamic> _reg = {};

  /// Bumps whenever a download is added/removed, so buttons can rebuild.
  static final ValueNotifier<int> changes = ValueNotifier(0);

  static Future<void> init() async {
    _docsDir = await getApplicationDocumentsDirectory();
    _mediaDir = Directory('${_docsDir.path}/offline_media');
    if (!await _mediaDir.exists()) await _mediaDir.create(recursive: true);
    _files
      ..clear()
      ..addAll(_mediaDir.listSync().whereType<File>().map((f) => f.path.split(Platform.pathSeparator).last));
    try {
      _reg = Map<String, dynamic>.from(jsonDecode(sharedPref.getString(_regKey) ?? '{}'));
    } catch (_) {
      _reg = {};
    }
  }

  // ---------- lookups ----------
  static String _name(String url) {
    // FNV-1a 64-bit: stable across runs and app updates (String.hashCode is not guaranteed to be)
    var h = BigInt.parse('cbf29ce484222325', radix: 16);
    final prime = BigInt.parse('100000001b3', radix: 16);
    final mask = (BigInt.one << 64) - BigInt.one;
    for (final c in url.codeUnits) {
      h = ((h ^ BigInt.from(c)) * prime) & mask;
    }
    final dot = url.split('?').first.lastIndexOf('.');
    final ext = dot > url.lastIndexOf('/') && url.length - dot <= 6 ? url.split('?').first.substring(dot) : '';
    return h.toRadixString(16) + ext;
  }

  /// Local file path for a picture that was downloaded for offline use, or null.
  static String? localPath(String resolvedUrl) {
    final n = _name(resolvedUrl);
    return _files.contains(n) ? '${_mediaDir.path}/$n' : null;
  }

  static bool isDownloaded(int subjectId) => _reg.containsKey('$subjectId');
  static Map<String, dynamic>? info(int subjectId) => _reg['$subjectId'] == null ? null : Map<String, dynamic>.from(_reg['$subjectId']);

  static String resolve(String image) => image.startsWith('http://') || image.startsWith('https://') ? image : Api.imageUrl + image;

  // ---------- download ----------
  static List<DeckEntity> _leaves(DeckEntity d) {
    if (d.type == 'CARDS_DECK') return [d];
    return d.children.expand(_leaves).toList();
  }

  /// Downloads every lesson of [subject]: card text (into Hive), pictures and attached files.
  /// Returns how many media files could not be downloaded (0 = complete).
  static Future<int> download(
    DeckEntity subject, {
    required void Function(double progress) onProgress,
    CancelToken? cancel,
  }) async {
    final leaves = _leaves(subject);
    if (leaves.isEmpty) throw Exception('empty');

    // 1) cards (0% - 15%)
    final images = <String>{};
    final docs = <String>{};
    var cardCount = 0;
    for (var i = 0; i < leaves.length; i++) {
      if (cancel?.isCancelled == true) throw DioException.requestCancelled(requestOptions: RequestOptions(), reason: 'cancel');
      final List<CardEntity>? cards = await ApiController.fetchCards(leaves[i].id);
      if (cards == null) throw Exception(ApiController.lastCardsError ?? 'error');
      cardCount += cards.length;
      for (final c in cards) {
        if (c.frontImageUrl.isNotEmpty) images.add(resolve(c.frontImageUrl));
        if (c.backImageUrl.isNotEmpty) images.add(resolve(c.backImageUrl));
        if (c.documentUrl.isNotEmpty) docs.add(c.documentUrl);
      }
      onProgress(.15 * (i + 1) / leaves.length);
    }

    // 2) pictures + files (15% - 100%), 4 at a time
    final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 30), receiveTimeout: const Duration(seconds: 90)));
    final jobs = <Future<bool> Function()>[];
    final myFiles = <String>[];
    for (final url in images) {
      final name = _name(url);
      myFiles.add(name);
      if (_files.contains(name)) continue;
      jobs.add(() async {
        final tmp = '${_mediaDir.path}/$name.part';
        try {
          await dio.download(url, tmp, cancelToken: cancel);
          await File(tmp).rename('${_mediaDir.path}/$name');
          _files.add(name);
          return true;
        } catch (_) {
          try { await File(tmp).delete(); } catch (_) {}
          if (cancel?.isCancelled == true) rethrow;
          return false;
        }
      });
    }
    for (final d in docs) {
      // same place and name the app's own "open attached file" uses, so it opens offline too
      final path = '${_docsDir.path}/${d.split("/").last}';
      if (File(path).existsSync()) continue;
      final url = d.startsWith('http') ? d : '${Api.imageUrl}/$d';
      jobs.add(() async {
        try {
          await dio.download(url, path, cancelToken: cancel);
          return true;
        } catch (_) {
          try { await File(path).delete(); } catch (_) {}
          if (cancel?.isCancelled == true) rethrow;
          return false;
        }
      });
    }
    var done = 0, failed = 0, next = 0;
    Future<void> worker() async {
      while (next < jobs.length) {
        final job = jobs[next++];
        if (!await job()) failed++;
        done++;
        onProgress(.15 + .85 * done / jobs.length);
      }
    }
    await Future.wait(List.generate(4, (_) => worker()));
    onProgress(1);

    var bytes = 0;
    for (final n in myFiles) {
      final f = File('${_mediaDir.path}/$n');
      if (f.existsSync()) bytes += f.lengthSync();
    }
    _reg['${subject.id}'] = {
      'title': subject.title,
      'cards': cardCount,
      'files': myFiles,
      'bytes': bytes,
      'failed': failed,
      'at': DateTime.now().toIso8601String(),
    };
    await sharedPref.setString(_regKey, jsonEncode(_reg));
    changes.value++;
    return failed;
  }

  static bool _syncing = false;
  static DateTime? _lastSync;

  /// Quietly re-checks every downloaded subject for new cards / pictures (at most every 20 minutes,
  /// only with a connection). Already saved pictures are skipped, so only what is new gets downloaded.
  static Future<void> syncAll(List<DeckEntity> decks) async {
    if (_syncing || _reg.isEmpty) return;
    final last = _lastSync;
    if (last != null && DateTime.now().difference(last) < const Duration(minutes: 20)) return;
    _syncing = true;
    try {
      if (!await instance<NetworkInfo>().isConnected) return;
      final byId = <int, DeckEntity>{};
      void walk(DeckEntity d) {
        byId[d.id] = d;
        for (final c in d.children) {
          walk(c);
        }
      }
      for (final d in decks) {
        walk(d);
      }
      for (final key in _reg.keys.toList()) {
        final s = byId[int.tryParse(key) ?? -1];
        if (s == null || s.locked) continue;
        try {
          await download(s, onProgress: (_) {});
        } catch (_) {}
      }
      _lastSync = DateTime.now();
    } finally {
      _syncing = false;
    }
  }

  /// Deletes the downloaded pictures of [subjectId] (unless another downloaded subject still uses them).
  static Future<void> remove(int subjectId) async {
    final mine = List<String>.from((_reg['$subjectId']?['files'] ?? const []) as List);
    _reg.remove('$subjectId');
    final stillUsed = <String>{for (final v in _reg.values) ...List<String>.from(v['files'] as List)};
    for (final n in mine) {
      if (stillUsed.contains(n)) continue;
      _files.remove(n);
      try { await File('${_mediaDir.path}/$n').delete(); } catch (_) {}
    }
    await sharedPref.setString(_regKey, jsonEncode(_reg));
    changes.value++;
  }
}
