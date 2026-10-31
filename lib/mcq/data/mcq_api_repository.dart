import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:upgrade/api.dart';
import 'package:upgrade/main.dart' show sharedPref;
import 'package:upgrade/mcq/data/mcq_repository.dart';
import 'package:upgrade/mcq/models/mcq_models.dart';
import 'package:upgrade/server_failover.dart';

class McqLoadException implements Exception {
  final String message;
  McqLoadException(this.message);
  @override
  String toString() => 'McqLoadException: $message';
}

/// Loads the published question bank from the backend (GET /mcq/catalog) with
/// the same token and server-failover the rest of the app uses.
///
/// Uses HTTP ETags: the last good response is kept on the device and only
/// re-downloaded when the content changed (304 otherwise). If the server
/// cannot be reached, the saved copy is used so the student can still study.
/// Every record still goes through [McqCatalog.build] validation.
class ApiMcqRepository implements McqRepository {
  ApiMcqRepository();

  static const _bodyKey = 'mcq.catalog.body.v1';
  static const _etagKey = 'mcq.catalog.etag.v1';
  // SharedPreferences is not meant for huge blobs; above this we skip caching.
  static const _maxCacheChars = 2 * 1024 * 1024;

  final Dio _d = Dio(BaseOptions(
    baseUrl: Api.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    validateStatus: (_) => true,
  ))
    ..interceptors.add(ServerFailover());

  @override
  Future<McqCatalog> load() async {
    final cachedBody = sharedPref.getString(_bodyKey);
    final cachedEtag = sharedPref.getString(_etagKey);
    final haveCache = cachedBody != null && cachedEtag != null;

    try {
      final r = await _d.get(
        '/mcq/catalog',
        options: Options(headers: {
          'Accept': 'application/json',
          'Authorization': sharedPref.getString('token') ?? '',
          if (haveCache) 'If-None-Match': cachedEtag,
        }),
      );
      final code = r.statusCode ?? 0;

      if (code == 304 && haveCache) {
        return _parse(jsonDecode(cachedBody) as Map);
      }
      if (code == 200 && r.data is Map) {
        final data = r.data as Map;
        final etag = r.headers.value('etag');
        if (etag != null) {
          final encoded = jsonEncode(data);
          if (encoded.length <= _maxCacheChars) {
            await sharedPref.setString(_bodyKey, encoded);
            await sharedPref.setString(_etagKey, etag);
          } else {
            await sharedPref.remove(_bodyKey);
            await sharedPref.remove(_etagKey);
          }
        }
        return _parse(data);
      }
      if (haveCache) {
        debugPrint('MCQ: server answered $code, using the saved copy');
        return _parse(jsonDecode(cachedBody) as Map);
      }
      throw McqLoadException('server answered $code');
    } on DioException catch (e) {
      if (haveCache) {
        debugPrint('MCQ: network error (${e.type}), using the saved copy');
        return _parse(jsonDecode(cachedBody) as Map);
      }
      throw McqLoadException('network error: ${e.type}');
    }
  }

  McqCatalog _parse(Map j) {
    List list(String k) => (j[k] is List) ? j[k] as List : const [];
    try {
      return McqCatalog.build(
        subjects: [
          for (final s in list('subjects'))
            McqSubject(
              id: s['id'] as String,
              name: s['name'] as String,
              nameEn: s['name_en'] as String?,
            )
        ],
        collections: [
          for (final c in list('collections'))
            McqCollection(
              id: c['id'] as String,
              subjectId: c['subject_id'] as String,
              title: c['title'] as String,
              titleEn: c['title_en'] as String?,
              order: (c['order'] as num?)?.toInt() ?? 0,
            )
        ],
        rawQuestions: [
          for (final q in list('questions')) Map<String, dynamic>.from(q as Map)
        ],
      );
    } catch (e) {
      throw McqLoadException('unexpected response shape ($e)');
    }
  }
}
