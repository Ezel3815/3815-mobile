import 'package:dio/dio.dart';

/// Switches to the next server when the current one is down or suspended.
/// Every app launch starts from the first server in the list.
class ServerFailover extends Interceptor {
  static const servers = <String>[
    'https://soalix-backend.onrender.com',
    'https://three815-backend.onrender.com', // Render 2
    'https://mozaik-backend-e981d.containers.snapdeploy.app',
  ];
  static int _active = 0;
  static const _down = {502, 503, 504};

  static void _apply(RequestOptions o, int to) {
    for (final s in servers) {
      if (o.path.startsWith(s)) {
        o.path = servers[to] + o.path.substring(s.length);
        break;
      }
    }
    for (final s in servers) {
      if (o.baseUrl.startsWith(s)) {
        o.baseUrl = servers[to] + o.baseUrl.substring(s.length);
        break;
      }
    }
  }

  Future<Response<dynamic>?> _tryOthers(RequestOptions o) async {
    final probe = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 90),
      receiveTimeout: const Duration(seconds: 120),
      validateStatus: (_) => true,
    ));
    for (var k = 1; k < servers.length; k++) {
      final to = (_active + k) % servers.length;
      try {
        final req = o.copyWith(data: o.data is FormData ? (o.data as FormData).clone() : o.data);
        _apply(req, to);
        final r = await probe.fetch<dynamic>(req);
        if (!_down.contains(r.statusCode)) {
          _active = to;
          return r;
        }
      } catch (_) {}
    }
    return null;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _apply(options, _active);
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    if (servers.length < 2 || !_down.contains(response.statusCode)) return handler.next(response);
    final alt = await _tryOthers(response.requestOptions);
    handler.next(alt ?? response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final t = err.type;
    final o = err.requestOptions;
    final noReply = t == DioExceptionType.connectionError || t == DioExceptionType.connectionTimeout;
    final slowGet = o.method == 'GET' && (t == DioExceptionType.receiveTimeout || t == DioExceptionType.sendTimeout);
    if (servers.length < 2 || !(noReply || slowGet)) return handler.next(err);
    final alt = await _tryOthers(o);
    if (alt != null) {
      handler.resolve(alt);
    } else {
      handler.next(err);
    }
  }
}
