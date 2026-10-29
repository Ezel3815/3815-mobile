import 'package:upgrade/failover.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:upgrade/api.dart';
import 'package:upgrade/main.dart' show sharedPref;
import 'ai_scan_strings.dart';

class AiStatus {
  final bool premium, canUse;
  final int remaining, limit;
  final DateTime? nextAvailableAt;
  AiStatus(Map j)
      : premium = j['premium'] == true,
        canUse = j['can_use'] == true,
        remaining = (j['remaining'] ?? 0) as int,
        limit = (j['limit'] ?? 0) as int,
        nextAvailableAt = j['next_available_at'] == null ? null : DateTime.parse(j['next_available_at']).toLocal();
}

class McqItem {
  final String question, explanation;
  final List<String> options;
  final int correct;
  McqItem(Map j)
      : question = j['question'],
        options = List<String>.from(j['options']),
        correct = j['correct'],
        explanation = j['explanation'] ?? '';
  Map<String, dynamic> toJson() => {'question': question, 'options': options, 'correct': correct, 'explanation': explanation};
}

class FlashItem {
  final String question, answer;
  FlashItem(Map j)
      : question = j['question'],
        answer = j['answer'];
  Map<String, dynamic> toJson() => {'question': question, 'answer': answer};
}

class ScanResult {
  final bool mcq;
  final List<FlashItem> cards;
  final List<McqItem> questions;
  final int? quizId, savedDeckId;
  ScanResult(Map j)
      : mcq = j['mode'] == 'mcq',
        cards = j['mode'] == 'mcq' ? [] : (j['items'] as List).map((e) => FlashItem(e)).toList(),
        questions = j['mode'] == 'mcq' ? (j['items'] as List).map((e) => McqItem(e)).toList() : [],
        quizId = j['quiz_id'],
        savedDeckId = j['saved_to_deck'];
}

/// Thrown when the free tries are used up (HTTP 402).
class QuotaExceeded implements Exception {
  final DateTime? nextAvailableAt;
  QuotaExceeded(this.nextAvailableAt);
}

class AiScanException implements Exception {
  final String message;
  AiScanException(this.message);
  @override
  String toString() => message;
}

class Plans {
  final double monthly, yearly;
  final int savingPercent;
  Plans(Map j)
      : monthly = (j['monthly']['price_usd'] as num).toDouble(),
        yearly = (j['yearly']['price_usd'] as num).toDouble(),
        savingPercent = (j['yearly']['saving_percent'] ?? 0) as int;
}

/// Talks to the backend's /ai/* endpoints with the same token the rest of the app uses.
class AiScanApi {
  final Dio _d = Dio(BaseOptions(
    baseUrl: Api.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 90),
    receiveTimeout: const Duration(seconds: 120),
    validateStatus: (_) => true, // handled in _ok
  ))..interceptors.add(ServerFailover());

  Options get _o => Options(headers: {'Accept': 'application/json', 'Authorization': sharedPref.getString('token') ?? ''});

  dynamic _ok(Response r) {
    final body = r.data;
    final code = r.statusCode ?? 0;
    if (code == 402) {
      final n = body is Map ? body['next_available_at'] : null;
      throw QuotaExceeded(n == null ? null : DateTime.parse(n).toLocal());
    }
    if (code >= 400 || code == 0) {
      String? m;
      if (body is Map) m = (body['message'] is String ? body['message'] : null) ?? (body['details'] is List ? (body['details'] as List).join('\n') : null);
      throw AiScanException(m ?? AiStr.genericError);
    }
    return body ?? {};
  }

  Future<T> _guard<T>(Future<T> Function() f) async {
    try {
      return await f();
    } on DioException catch (_) {
      throw AiScanException(AiStr.genericError);
    }
  }

  Future<AiStatus> status() => _guard(() async => AiStatus(_ok(await _d.get('/ai/status', options: _o))));
  Future<Plans> plans() => _guard(() async => Plans(_ok(await _d.get('/ai/plans', options: _o))));

  /// [mcq]: quiz (saved on the server when [title] is given) or flashcards (saved into [deckId] when given).
  Future<ScanResult> scan(List<File> images, {required bool mcq, int count = 10, int? deckId, String? title, String? deckTitle}) => _guard(() async {
        final form = FormData()
          ..fields.add(MapEntry('mode', mcq ? 'mcq' : 'flashcards'))
          ..fields.add(MapEntry('count', '$count'));
        if (deckId != null && !mcq) form.fields.add(MapEntry('deck_id', '$deckId'));
        if (title != null) form.fields.add(MapEntry('title', title));
        if (deckTitle != null && deckId == null && !mcq) form.fields.add(MapEntry('deck_title', deckTitle));
        for (final f in images) {
          form.files.add(MapEntry('images', await MultipartFile.fromFile(f.path, filename: f.path.split('/').last, contentType: DioMediaType.parse(_mime(f.path)))));
        }
        return ScanResult(_ok(await _d.post('/ai/scan', data: form, options: _o)));
      });

  Future<Map> startPayment(String plan) => _guard(() async => Map.from(_ok(await _d.post('/ai/payments', data: {'plan': plan}, options: _o))));

  Future<void> submitPayment(int id, String txId, {File? proof}) => _guard(() async {
        final form = FormData()..fields.add(MapEntry('tx_id', txId));
        if (proof != null) form.files.add(MapEntry('proof', await MultipartFile.fromFile(proof.path, filename: proof.path.split('/').last, contentType: DioMediaType.parse(_mime(proof.path)))));
        _ok(await _d.post('/ai/payments/$id/submit', data: form, options: _o));
      });

  /// "Keep" on reviewed flashcards: saved as normal cards into [deckId], or into a new deck called [deckTitle].
  Future<void> keepCards(List<FlashItem> cards, {int? deckId, String? deckTitle}) => _guard(() async {
        _ok(await _d.post('/ai/flashcards/keep', data: {'items': cards.map((e) => e.toJson()).toList(), if (deckId != null) 'deck_id': deckId, if (deckTitle != null) 'deck_title': deckTitle}, options: _o));
      });

  /// "Keep" on a finished quiz.
  Future<void> keepQuiz(List<McqItem> qs, String title) => _guard(() async {
        _ok(await _d.post('/ai/quizzes/keep', data: {'title': title, 'items': qs.map((e) => e.toJson()).toList()}, options: _o));
      });

  Future<void> submitQuiz(int quizId, List<int?> answers) => _guard(() async {
        _ok(await _d.post('/ai/quizzes/$quizId/submit', data: {'answers': answers}, options: _o));
      });

  static String _mime(String path) {
    final e = path.toLowerCase().split('.').last;
    return e == 'png' ? 'image/png' : e == 'webp' ? 'image/webp' : e == 'heic' ? 'image/heic' : 'image/jpeg';
  }
}
