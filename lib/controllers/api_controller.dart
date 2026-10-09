import 'package:upgrade/services/notification_service.dart';
import 'package:upgrade/entity/follow_person.dart';
import 'package:upgrade/entity/feed_entity.dart';
import 'package:upgrade/entity/quests_entity.dart';
import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:upgrade/controllers/app_local_data_source.dart';
import 'package:upgrade/controllers/error_handler.dart';
import 'package:upgrade/di.dart';
import 'package:upgrade/entity/card_entity.dart';
import 'package:upgrade/entity/deck_entity.dart';
import 'package:upgrade/entity/document_entity.dart';
import 'package:upgrade/entity/achievement.dart';
import 'package:upgrade/entity/activity_feed_item.dart';
import 'package:upgrade/entity/answer_result.dart';
import 'package:upgrade/entity/mosaic_entity.dart';
import 'package:upgrade/entity/daily_mission.dart';
import 'package:upgrade/entity/leaderboard_entry.dart';
import 'package:upgrade/entity/profile_entity.dart';
import 'package:upgrade/mapper/app_mapper.dart';
import 'package:upgrade/models/card_model.dart';
import 'package:upgrade/models/deck_model.dart';
import 'package:upgrade/models/document_model.dart';
import 'package:upgrade/models/user_model.dart';
import 'package:upgrade/network_info.dart';
import 'package:upgrade/services/push_service.dart';
import 'package:upgrade/widgets/app_snack_bar.dart';

import '../api.dart';
import '../main.dart';

class ApiController {
  static late Dio dio;
  static final AppLocalDataSource _appLocalDataSource =
      instance<AppLocalDataSource>();
  static final NetworkInfo _networkInfo = instance<NetworkInfo>();

  static initDio() {
    dio = Dio(
      BaseOptions(
        baseUrl: Api.baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        validateStatus: (status) {
          return status! >= 200 || status <= 500;
        },
      ),
    );
    if (!kReleaseMode) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
        ),
      );
    }
  }

     /// Returns null on success (or after showing an error), or
  /// 'username_taken' so the form can flag the username field itself.
  static Future<String?> register(String name, String username, String email,
      String password, BuildContext context) async {
    try {
      final response = await dio.post(
        Api.register,
        data: {
          'name': name,
          'username': username.trim().toLowerCase(),
          'email': email,
          'password': password,
        },
      );
      if (response.statusCode == 201) {
        Map<String, dynamic> json = response.data;
        Get.offNamed(AppRoutes.mainRoute);
        sharedPref.setString('token', json['token']);
        sharedPref.setString(
            "user", jsonEncode(UserModel.fromJson(json['user'])));
        PushService.instance.syncToken();
      } else {
        showSnackBarWidget(message: response.data['message'] ?? "");
      }
    } catch (e) {
      final body = e is DioException ? '${e.response?.data}'.toLowerCase() : '';
      if (body.contains('username') && body.contains('taken')) {
        return 'username_taken';
      }
      if (e is DioException && (e.response?.statusCode ?? 0) >= 500) {
        return 'server_error';
      }
      if(ErrorHandler.handle(e).failure.code != -6) {
        showSnackBarWidget(message: ErrorHandler
            .handle(e)
            .failure
            .message ?? "");
      }
    }
    return null;
  }
  static Future<void> activate(
      String code, String email, BuildContext context) async {
    try {
      final response = await dio.put(
        Api.activate,
        data: {
          'code': code,
          'email': email,
        },
      );

      if (response.statusCode == 200) {
        Get.offAllNamed(AppRoutes.loginRoute);
      } else {
        showSnackBarWidget(message: response.data['message'] ?? "");
      }
    } catch (e) {
      if(ErrorHandler.handle(e).failure.code != -6) {
        showSnackBarWidget(message: ErrorHandler
            .handle(e)
            .failure
            .message ?? "");
      }
    }
  }

  static Future<void> login(
      String email, String password, BuildContext context) async {
    try {
      final response = await dio.post(
        Api.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      Map<String, dynamic> json = response.data;
      if (response.statusCode == 201) {
        if (json['user']['status'] == "PENDING") {
          Get.toNamed(AppRoutes.activateCodeRoute);
          return;
        }
        Get.offNamed(AppRoutes.mainRoute);
        sharedPref.setString('token', json['token']);
        sharedPref.setString(
            "user", jsonEncode(UserModel.fromJson(json['user'])));
        PushService.instance.syncToken();
      } else {
        showSnackBarWidget(message: json['message'] ?? "");
      }
    } catch (e) {
      if(ErrorHandler.handle(e).failure.code != -6) {
        showSnackBarWidget(message: ErrorHandler
            .handle(e)
            .failure
            .message ?? "");
      }
    }
  }

  static Future<void> requestResetPassword(
      String email, BuildContext context) async {
    try {
      final response = await dio.put(
        Api.requestResetPassword,
        data: {
          'email': email,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.offAllNamed(AppRoutes.loginRoute);
      } else {
        showSnackBarWidget(message: response.data['message'] ?? "");
      }
    } catch (e) {
      if(ErrorHandler.handle(e).failure.code != -6) {
        showSnackBarWidget(message: ErrorHandler
            .handle(e)
            .failure
            .message ?? "");
      }
    }
  }

  static Future<void> resetPassword(
      String email, String code, String password, BuildContext context) async {
    try {
      await dio.put(
        Api.resetPassword,
        data: {
          'email': email,
          'code': code,
          'password': password,
        },
      );

      Get.offAllNamed(AppRoutes.loginRoute);
    } catch (e) {
      if(ErrorHandler.handle(e).failure.code != -6) {
        showSnackBarWidget(message: ErrorHandler
            .handle(e)
            .failure
            .message ?? "");
      }
    }
  }

  static Future<CardEntity?> addcard(
    int? id,
    String type,
    Map<String, dynamic> data, {
    String? documentName,
    String? documenttitle,
    required String backImageName,
    required String frontImageName,
  }) async {
    try {
      Map<String, dynamic> requestBody = {
        'type': type,
        'data': data,
      };
      if (backImageName.isNotEmpty) {
        requestBody['back_image_name'] = backImageName;
      }

      if (frontImageName.isNotEmpty) {
        requestBody['front_image_name'] = frontImageName;
      }

      if (documentName != null) {
        requestBody['document_name'] = documentName;
      }

      if (documenttitle != null) {
        requestBody['document_title'] = documenttitle;
      }

      final response = await dio.post(
        '${Api.addCard}/$id',
        data: requestBody,
        options: GetOptions.getOptions(),
      );

      Map<String, dynamic> json = response.data;
      if (response.statusCode == 201) {
        return CardModel.fromJson(json).toDomain();
      } else {
        Get.back();
        showSnackBarWidget(message: json['message'] ?? "");
      }
    } catch (e) {
      Get.back();
      if(ErrorHandler.handle(e).failure.code != -6) {
        showSnackBarWidget(message: ErrorHandler
            .handle(e)
            .failure
            .message ?? "");
      }
    }
    return null;
  }

  static Future<CardEntity?> editcard(
    int id,
    int deckid,
    String type,
    Map<String, dynamic> data, {
    String? documentName,
    String? documenttitle,
    String? backImageName,
    String? frontImageName,
  }) async {
    try {
      Map<String, dynamic> requestBody = {
        'type': type,
        'data': data,
      };
      if (backImageName != null) {
        requestBody['back_image_name'] = backImageName;
      }

      if (frontImageName != null) {
        requestBody['front_image_name'] = frontImageName;
      }

      if (documentName != null) {
        requestBody['document_name'] = documentName;
      }

      if (documenttitle != null) {
        requestBody['document_title'] = documenttitle;
      }

      final response = await dio.put(
        '${Api.addCard}/$deckid/$id',
        data: requestBody,
        options: GetOptions.getOptions(),
      );
      Map<String, dynamic> json = response.data;
      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.back();
        return CardModel.fromJson(json).toDomain();
      } else {
        Get.back();
        showSnackBarWidget(message: json['message'] ?? "");
      }
    } catch (e) {
      Get.back();
      if(ErrorHandler.handle(e).failure.code != -6) {
        showSnackBarWidget(message: ErrorHandler
            .handle(e)
            .failure
            .message ?? "");
      }
    }
    return null;
  }

  static Future<String?> uploadImage(String path) async {
    try {
      final file = await MultipartFile.fromFile(path);

      final formData = FormData.fromMap(
        {
          "file": file,
        },
        ListFormat.multiCompatible,
      );

      final response = await dio.post(
        Api.uploadImage,
        data: formData,
        options: GetOptions.getOptions(),
      );

      Map<String, dynamic> json = response.data;

      if (response.statusCode == 201) {
        return json['name'];
      } else {
        showSnackBarWidget(message: json['message'] ?? "");
      }
    } catch (e) {
      log(e.toString());
      if(ErrorHandler.handle(e).failure.code != -6) {
      showSnackBarWidget(message: ErrorHandler.handle(e).failure.message ?? "");
      }
      return null;
    }
    return null;
  }

  static Future<String?> uploadFile(String path) async {
    try {
      final file = await MultipartFile.fromFile(path);

      final formData = FormData.fromMap(
        {
          "file": file,
        },
        ListFormat.multiCompatible,
      );

      final response = await dio.post(
        Api.uploadDocument,
        data: formData,
        options: GetOptions.getOptions(),
      );

      Map<String, dynamic> json = response.data;

      if (response.statusCode == 201) {
        return json['name'];
      } else {
        showSnackBarWidget(message: json['message'] ?? "");
      }
    } catch (e) {
      log(e.toString());
      if(ErrorHandler.handle(e).failure.code != -6) {
        showSnackBarWidget(message: ErrorHandler
            .handle(e)
            .failure
            .message ?? "");
      }
      return null;
    }
    return null;
  }

  /// True when the last getDecks()/getMyDecks() call failed, so callers can
  /// tell a failed request apart from a genuinely empty list.
  static bool lastDecksFailed = false;
  static bool lastMyDecksFailed = false;

  static Future<List<DeckEntity>> getDecks() async {
    lastDecksFailed = false;
    if (await _networkInfo.isConnected) {
      try {
        final response = await dio.get(
          Api.getDecks,
          options: GetOptions.getOptions(),
        );

        List<dynamic> json = response.data;

        if (response.statusCode == 200 || response.statusCode == 201) {
          List<DeckModel> list = [];
          for (var value in json) {
            try {
              list.add(DeckModel.fromJson(value));
            } catch (e) {
              // One bad deck/card must not wipe the entire tree.
              log(e.toString());
            }
          }

          final data = list.map((e) => e.toDomain()).toList();
          await _appLocalDataSource.setDeckEntityToLocal(data);

          return data;
        } else {
          lastDecksFailed = true;
          showSnackBarWidget(message: response.data['message'] ?? "");
        }

        return [];
      } catch (e) {
        lastDecksFailed = true;
        if(ErrorHandler.handle(e).failure.code != -6) {
        showSnackBarWidget(
            message: ErrorHandler.handle(e).failure.message ?? "");
        }
        log(e.toString());
        return [];
      }
    } else {
      final data = await _appLocalDataSource.getDeckEntityFromLocal();
      if (data.isNotEmpty) {
        return data;
      } else {
        // showSnackBarWidget(
        //     message:
        //         DataSource.noInternetConnection.getFailure().message ?? "");
      }
    }
    lastDecksFailed = true; // offline and nothing cached
    return [];
  }

  static Future<List<DeckEntity>> getMyDecks() async {
    lastMyDecksFailed = false;
    if (await _networkInfo.isConnected) {
      try {
        final response = await dio.get(
          Api.getMyDecks,
          options: GetOptions.getOptions(),
        );

        List<dynamic> json = response.data;

        if (response.statusCode == 200 || response.statusCode == 201) {
          List<DeckModel> list = [];
          for (var value in json) {
            try {
              list.add(DeckModel.fromJson(value));
            } catch (e) {
              // One bad deck/card must not wipe the entire tree.
              log(e.toString());
            }
          }
          final data = list.map((e) => e.toDomain()).toList();
          await _appLocalDataSource.setMyDeckEntityToLocal(data);
          return data;
        } else {
          lastMyDecksFailed = true;
          showSnackBarWidget(message: response.data['message'] ?? "");
        }

        return [];
      } catch (e) {
        lastMyDecksFailed = true;
        if(ErrorHandler.handle(e).failure.code != -6) {
        showSnackBarWidget(
            message: ErrorHandler.handle(e).failure.message ?? "");
        }
        log(e.toString());
        return [];
      }
    } else {
      final data = await _appLocalDataSource.getMyDeckEntityFromLocal();
      if (data.isNotEmpty) {
        return data;
      } else {
        // showSnackBarWidget(
        //     message:
        //         DataSource.noInternetConnection.getFailure().message ?? "");
      }
    }
    lastMyDecksFailed = true; // offline and nothing cached
    return [];
  }

  static Future<bool> enterCode(String code) async {
    try {
      final response = await dio.post(
        Api.enterCode,
        data: {
          "code": code,
        },
        options: GetOptions.getOptions(),
      );
      if(response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        showSnackBarWidget(message: response.data['message'] ?? "");
      }
      return false;
    } catch (e) {
      if(ErrorHandler.handle(e).failure.code != -6) {
        showSnackBarWidget(message: ErrorHandler
            .handle(e)
            .failure
            .message ?? "");
      }
      log(e.toString());
      return false;
    }
  }

  static Future<DeckEntity?> createDeck(String name) async {
    try {
      final response = await dio.post(
        Api.createDeck,
        options: GetOptions.getOptions(),
        data: {
          "title": name,
        },
      );

      final Map<String, dynamic> json = response.data;

      return DeckModel.fromJson(json).toDomain();
    } catch (e) {
      if(ErrorHandler.handle(e).failure.code != -6) {
        showSnackBarWidget(message: ErrorHandler
            .handle(e)
            .failure
            .message ?? "");
      }
    }
    return null;
  }

  static Future<DeckEntity?> editDeck(String name, int id) async {
    try {
      final response = await dio.put(
        Api.editDeck(id),
        options: GetOptions.getOptions(),
        data: {
          "title": name,
        },
      );

      final Map<String, dynamic> json = response.data;

      return DeckModel.fromJson(json).toDomain();
    } catch (e) {
      if(ErrorHandler.handle(e).failure.code != -6) {
        showSnackBarWidget(message: ErrorHandler
            .handle(e)
            .failure
            .message ?? "");
      }
    }
    return null;
  }

  static Future<void> deleteDeck(int id) async {
    try {
      await dio.delete(
        Api.deleteDeck(id),
        options: GetOptions.getOptions(),
      );

      return;
    } catch (e) {
      if(ErrorHandler.handle(e).failure.code != -6) {
        showSnackBarWidget(message: ErrorHandler
            .handle(e)
            .failure
            .message ?? "");
      }
    }
    return;
  }

  static Future<bool> deleteCard(int deckId, int id) async {
    try {
     final response =  await dio.delete(
        Api.deleteCard(deckId, id),
        options: GetOptions.getOptions(),
      );

     if(response.statusCode == 200 || response.statusCode == 201) {
       return true;
     } else {
       showSnackBarWidget(message: response.data?['message'] ?? 'Error ${response.data}');
       return false;
     }
    } catch (e,stacktrace) {
      print(e.toString());
      print(stacktrace.toString());
      if(ErrorHandler.handle(e).failure.code != -6) {
        showSnackBarWidget(message: ErrorHandler
            .handle(e)
            .failure
            .message ?? "");
      }
    }
    return false;
  }

  /// Reason the last [fetchCards] call failed (shown to the user so a real
  /// error is never mistaken for "this deck has no cards").
  static String? lastCardsError;

  /// Like [getCards] but distinguishes failure (null) from a deck that is
  /// really empty ([]).
  static Future<List<CardEntity>?> fetchCards(int id) async {
    lastCardsError = null;
    try {
      final response = await dio.get(
        Api.getCards(id),
        options: GetOptions.getOptions(),
      );
      final List<dynamic> json = response.data;
      final data = json.map((e) => CardModel.fromJson(e).toDomain()).toList();
      await _appLocalDataSource.setCardEntityToLocal(data, id);
      return data;
    } catch (e) {
      lastCardsError = e is DioException
          ? (ErrorHandler.handle(e).failure.message ?? 'خطأ في الاتصال')
          : e.toString();
      log('fetchCards($id) failed: $e');
      final local = await _appLocalDataSource.getCardEntityFromLocal(id);
      return local.isNotEmpty ? local : null;
    }
  }

  static Future<List<CardEntity>> getCards(int id) async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await dio.get(
          Api.getCards(id),
          options: GetOptions.getOptions(),
        );

        final List<dynamic> json = response.data;

        final List<CardModel> list = [];

        for (var element in json) {
          list.add(CardModel.fromJson(element));
        }

        final data = list.map((e) => e.toDomain()).toList();
        await _appLocalDataSource.setCardEntityToLocal(data, id);

        return data;
      } catch (e,stackTrace) {
        log(e.toString());
        log(stackTrace.toString());
        if(ErrorHandler.handle(e).failure.code != -6) {
          showSnackBarWidget(
              message: ErrorHandler
                  .handle(e)
                  .failure
                  .message ?? "");
        }
      }
    } else {
      final data = await _appLocalDataSource.getCardEntityFromLocal(id);
      if (data.isNotEmpty) {
        return data;
      } else {
        // showSnackBarWidget(
        //     message:
        //         DataSource.noInternetConnection.getFailure().message ?? "");
      }
    }
    return [];
  }

  static Future<List<DocumentEntity>> getDocument() async {
    if (await _networkInfo.isConnected) {
      try {
        final response = await dio.get(
          Api.getDocument,
          options: GetOptions.getOptions(),
        );

        final List<dynamic> json = response.data;

        final List<DocumentModel> list = [];

        for (var element in json) {
          list.add(DocumentModel.fromJson(element));
        }

        final data = list.map((e) => e.toDomain()).toList();
        await _appLocalDataSource.setDocumentEntityToLocal(data);

        return data;
      } catch (e) {
        if(ErrorHandler.handle(e).failure.code != -6) {
          showSnackBarWidget(
              message: ErrorHandler
                  .handle(e)
                  .failure
                  .message ?? "");
        }
      }
    } else {
      final data = await _appLocalDataSource.getDocumentEntityFromLocal();
      if (data.isNotEmpty) {
        return data;
      } else {
        // showSnackBarWidget(
        //     message:
        //         DataSource.noInternetConnection.getFailure().message ?? "");
      }
    }
    return [];
  }

  static Future<List<ActivityFeedItem>> getActivityFeed() async {
    try {
      final response = await dio.get(
        Api.activityFeed,
        options: GetOptions.getOptions(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return (response.data as List)
            .map((e) => ActivityFeedItem.fromJson(e))
            .toList();
      }
    } catch (e) {
      if (ErrorHandler.handle(e).failure.code != -6) {
        log(e.toString());
      }
    }
    return [];
  }

  static Future<AnswerResult?> answerCard(
      {required int cardID, required String answer}) async {
    try {
      final response = await dio.put(
        Api.answerCard(cardID),
        data: {
          "answer": answer,
        },
        options: GetOptions.getOptions(),
      );
      if (response.data is Map<String, dynamic>) {
        return AnswerResult.fromJson(response.data);
      }
    } catch (e) {
      if(ErrorHandler.handle(e).failure.code != -6) {
        showSnackBarWidget(message: ErrorHandler.handle(e).failure.message ?? "");
      }
    }
    return null;
  }

  static Future<int?> getUserIdByUsername(String username) async {
    try {
      final response = await dio.get(
        Api.userByUsername(username),
        options: GetOptions.getOptions(),
      );
      return response.data['id'] as int?;
    } catch (e) {
      if (ErrorHandler.handle(e).failure.code != -6) {
        showSnackBarWidget(
            message: ErrorHandler.handle(e).failure.message ?? "");
      }
    }
    return null;
  }

  /// True when the username is free (or the check itself failed —
  /// the server still rejects duplicates on register).
  static Future<bool?> isUsernameAvailable(String username) async {
    try {
      final response = await dio.get(Api.usernameAvailable(username));
      final v = response.data['available'];
      return v is bool ? v : null;
    } catch (_) {
      return null; // unknown (server unreachable / route missing)
    }
  }

  static Future<ProfileEntity?> getProfile(int id) async {
    try {
      final response = await dio.get(
        Api.getProfile(id),
        options: GetOptions.getOptions(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ProfileEntity.fromJson(response.data);
      } else {
        showSnackBarWidget(message: response.data['message'] ?? "");
      }
    } catch (e) {
      if (ErrorHandler.handle(e).failure.code != -6) {
        showSnackBarWidget(
            message: ErrorHandler.handle(e).failure.message ?? "");
      }
    }
    return null;
  }

  /// kind: 'followers' or 'following'. Null when the request failed.
  static Future<List<FollowPerson>?> getFollowList(int id, String kind) async {
    try {
      final response = await dio.get(
        kind == 'followers' ? Api.followers(id) : Api.following(id),
        options: GetOptions.getOptions(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return (response.data as List)
            .map((e) => FollowPerson.fromJson(e))
            .toList();
      }
    } catch (e) {
      log(e.toString());
    }
    return null;
  }

  static Future<bool> followUser(int id) async {
    try {
      final response = await dio.post(
        Api.followUser(id),
        options: GetOptions.getOptions(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        showSnackBarWidget(message: response.data['message'] ?? "");
      }
    } catch (e) {
      if (ErrorHandler.handle(e).failure.code != -6) {
        showSnackBarWidget(
            message: ErrorHandler.handle(e).failure.message ?? "");
      }
    }
    return false;
  }

  static Future<bool> unfollowUser(int id) async {
    try {
      final response = await dio.delete(
        Api.unfollowUser(id),
        options: GetOptions.getOptions(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        showSnackBarWidget(message: response.data['message'] ?? "");
      }
    } catch (e) {
      if (ErrorHandler.handle(e).failure.code != -6) {
        showSnackBarWidget(
            message: ErrorHandler.handle(e).failure.message ?? "");
      }
    }
    return false;
  }

  /// Registers this device's push token with the backend (or clears it
  /// on logout). Silent by design — a failed sync here should never
  /// interrupt the user; NotificationService retries on next app open.
  /// Admin: the whole cards library as a JSON string (null = failed / not admin).
  static Future<String?> exportCardsBackup({bool includePersonal = false}) async {
    try {
      final response = await dio.get(
        Api.backupCards,
        queryParameters: {'all': includePersonal ? 1 : 0},
        options: GetOptions.getOptions().copyWith(
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 180),
        ),
      );
      if (response.statusCode == 200 && response.data is String) {
        return response.data as String;
      }
    } catch (e) {
      log(e.toString());
    }
    return null;
  }

  /// Admin: restores a backup file's JSON text. Never deletes anything.
  static Future<Map<String, dynamic>?> restoreCardsBackup(
    String json, {
    bool overwrite = false,
  }) async {
    try {
      final response = await dio.post(
        Api.backupRestore,
        queryParameters: {'overwrite': overwrite ? 1 : 0},
        data: jsonDecode(json),
        options: GetOptions.getOptions().copyWith(
          sendTimeout: const Duration(seconds: 180),
          receiveTimeout: const Duration(seconds: 180),
        ),
      );
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data is Map) {
        return Map<String, dynamic>.from(response.data);
      }
    } catch (e) {
      log(e.toString());
    }
    return null;
  }

  /// Asks the server to send a real push to this account after [delaySeconds]
  /// and reports what it found (Firebase configured? token saved? result).
  static Future<Map<String, dynamic>?> sendPushTest({int delaySeconds = 12}) async {
    try {
      final response = await dio.post(
        Api.pushTest,
        data: {'delay_seconds': delaySeconds},
        options: GetOptions.getOptions(),
      );
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data is Map) {
        return Map<String, dynamic>.from(response.data);
      }
    } catch (_) {}
    return null;
  }

  /// Server-authoritative study state for the reminder engine (null = offline).
  static Future<Map<String, dynamic>?> getNotificationState() async {
    try {
      final response = await dio.get(
        Api.notificationState,
        options: GetOptions.getOptions(),
      );
      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data);
      }
    } catch (_) {}
    return null;
  }

  /// Uploads notification lifecycle records (idempotent on the server).
  static Future<bool> postNotificationEvents(List<Map<String, dynamic>> events) async {
    try {
      final response = await dio.post(
        Api.notificationEvents,
        data: {'events': events},
        options: GetOptions.getOptions(),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> registerFcmToken(String? token) async {
    try {
      final response = await dio.put(
        Api.fcmToken,
        data: {'token': token ?? ''},
        options: GetOptions.getOptions(),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> updateProfile({
    String? username,
    String? avatarHair,
    String? avatarHairColor,
    String? avatarSkinColor,
    String? avatarClothingColor,
    bool? avatarGlasses,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (username != null) data['username'] = username;
      if (avatarHair != null) data['avatar_hair'] = avatarHair;
      if (avatarHairColor != null) data['avatar_hair_color'] = avatarHairColor;
      if (avatarSkinColor != null) data['avatar_skin_color'] = avatarSkinColor;
      if (avatarClothingColor != null) {
        data['avatar_clothing_color'] = avatarClothingColor;
      }
      if (avatarGlasses != null) data['avatar_glasses'] = avatarGlasses;

      final response = await dio.put(
        Api.updateProfile,
        data: data,
        options: GetOptions.getOptions(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        showSnackBarWidget(message: response.data['message'] ?? "");
      }
    } catch (e) {
      if (ErrorHandler.handle(e).failure.code != -6) {
        showSnackBarWidget(
            message: ErrorHandler.handle(e).failure.message ?? "");
      }
    }
    return false;
  }

    static Future<List<Achievement>> getAchievements() async {
    try {
      final response = await dio.get(
        Api.achievements,
        options: GetOptions.getOptions(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return (response.data as List)
            .map((e) => Achievement.fromJson(e))
            .toList();
      }
    } catch (e) {
      if (ErrorHandler.handle(e).failure.code != -6) {
        log(e.toString());
      }
    }
    return [];
  }

  static Future<List<FeedPost>?> getFeed() async {
    try {
      final response = await dio.get(
        Api.feed,
        options: GetOptions.getOptions(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return (response.data as List).map((e) => FeedPost.fromJson(e)).toList();
      }
    } catch (e) {
      log(e.toString());
    }
    return null;
  }

  /// Toggles "celebrate". Returns {celebrated, count} or null on failure.
  static Future<Map<String, dynamic>?> celebratePost(int id) async {
    try {
      final response = await dio.post(
        Api.feedCelebrate(id),
        options: GetOptions.getOptions(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      if (ErrorHandler.handle(e).failure.code != -6) {
        showSnackBarWidget(
            message: ErrorHandler.handle(e).failure.message ?? "");
      }
    }
    return null;
  }

  static Future<List<FeedComment>?> getFeedComments(int id) async {
    try {
      final response = await dio.get(
        Api.feedComments(id),
        options: GetOptions.getOptions(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return (response.data as List)
            .map((e) => FeedComment.fromJson(e))
            .toList();
      }
    } catch (e) {
      log(e.toString());
    }
    return null;
  }

  static Future<FeedComment?> addFeedComment(int id, String text) async {
    try {
      final response = await dio.post(
        Api.feedComments(id),
        data: {'text': text},
        options: GetOptions.getOptions(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return FeedComment.fromJson(response.data);
      }
    } catch (e) {
      if (ErrorHandler.handle(e).failure.code != -6) {
        showSnackBarWidget(
            message: ErrorHandler.handle(e).failure.message ?? "");
      }
    }
    return null;
  }

  /// Mutual friends the user can pick as friends-quest partner (null = failed).
  static Future<List<QuestFriend>?> getQuestFriends() async {
    try {
      final response = await dio.get(
        Api.questFriends,
        options: GetOptions.getOptions(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return (response.data as List)
            .map((e) => QuestFriend.fromJson(e))
            .toList();
      }
    } catch (e) {
      log(e.toString());
    }
    return null;
  }

  static Future<bool> setQuestPartner(int friendId) async {
    try {
      final response = await dio.put(
        Api.questPartner,
        data: {'friend_id': friendId},
        options: GetOptions.getOptions(),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (ErrorHandler.handle(e).failure.code != -6) {
        showSnackBarWidget(
            message: ErrorHandler.handle(e).failure.message ?? "");
      }
    }
    return false;
  }

  /// Nudges a friend (feed post + push). Returns {sent, reason?} or null.
  static Future<Map<String, dynamic>?> remindFriend(int id) async {
    try {
      final response = await dio.post(
        Api.remind(id),
        options: GetOptions.getOptions(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      if (ErrorHandler.handle(e).failure.code != -6) {
        showSnackBarWidget(
            message: ErrorHandler.handle(e).failure.message ?? "");
      }
    }
    return null;
  }

  /// Opens a mosaic weekly chest (ids like "mosaic_chest_1"). Reuses the
  /// quest-chest endpoint server-side, but the response also carries the
  /// awarded mosaic pieces, so it's parsed separately from claimQuestChest().
  static Future<MosaicAward?> claimMosaicChest(String id) async {
    try {
      final response = await dio.post(
        Api.claimQuest,
        data: {'id': id},
        options: GetOptions.getOptions(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return MosaicAward.tryParse(response.data['mosaic']);
      }
    } catch (e) {
      showSnackBarWidget(
          message: ErrorHandler.handle(e).failure.message ?? "");
    }
    return null;
  }

  /// Asks the server to re-run its idempotent post-answer evaluation (heals a
  /// piece whose answer-time evaluation was slow/failed) and returns the fresh
  /// state. Silent on failure: callers fall back to the read-only getMosaic().
  static Future<MosaicState?> syncMosaic() async {
    try {
      final response = await dio.post(
        Api.mosaicSync,
        options: GetOptions.getOptions(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return MosaicState.fromJson(response.data);
      }
    } catch (e) {
      log(e.toString());
    }
    return null;
  }

  /// Read-only: never awards anything, so refreshing/reopening is always safe.
  static Future<MosaicState?> getMosaic() async {
    try {
      final response = await dio.get(
        Api.mosaic,
        options: GetOptions.getOptions(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return MosaicState.fromJson(response.data);
      }
    } catch (e) {
      if (ErrorHandler.handle(e).failure.code != -6) {
        log(e.toString());
      }
    }
    return null;
  }

  /// Acks that the reveal animation played for these pieces, so it doesn't
  /// replay on next open. Best-effort — losing this ack just replays once.
  static Future<void> ackMosaicReveal(List<int> pieceIds) async {
    try {
      await dio.post(
        Api.mosaicReveal,
        data: {'pieceIds': pieceIds},
        options: GetOptions.getOptions(),
      );
    } catch (e) {
      log(e.toString());
    }
  }

  static Future<bool> updateTimezone(String timezone) async {
    try {
      final response = await dio.put(
        Api.updateTimezone,
        data: {'timezone': timezone},
        options: GetOptions.getOptions(),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      log(e.toString());
      return false;
    }
  }

  static Future<QuestsData?> getQuests() async {
    try {
      final response = await dio.get(
        Api.quests,
        options: GetOptions.getOptions(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return QuestsData.fromJson(response.data);
      }
    } catch (e) {
      if (ErrorHandler.handle(e).failure.code != -6) {
        log(e.toString());
      }
    }
    return null;
  }

  /// Opens a chest. Returns the XP gained, or null if it couldn't be opened.
  static Future<int?> claimQuestChest(String id) async {
    try {
      final response = await dio.post(
        Api.claimQuest,
        data: {'id': id},
        options: GetOptions.getOptions(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final xp = response.data['xp'];
        return xp is num ? xp.toInt() : 0;
      }
    } catch (e) {
      if (ErrorHandler.handle(e).failure.code != -6) {
        showSnackBarWidget(
            message: ErrorHandler.handle(e).failure.message ?? "");
      }
    }
    return null;
  }

    static Future<List<DailyMission>> getDailyMissions() async {
    try {
      final response = await dio.get(
        Api.dailyMissions,
        options: GetOptions.getOptions(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return (response.data['missions'] as List)
            .map((e) => DailyMission.fromJson(e))
            .toList();
      }
    } catch (e) {
      if (ErrorHandler.handle(e).failure.code != -6) {
        log(e.toString());
      }
    }
    return [];
  }

    static Future<List<LeaderboardEntry>> getLeaderboard() async {
    try {
      final response = await dio.get(
        Api.leaderboard,
        options: GetOptions.getOptions(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return (response.data as List)
            .map((e) => LeaderboardEntry.fromJson(e))
            .toList();
      }
    } catch (e) {
      if (ErrorHandler.handle(e).failure.code != -6) {
        log(e.toString());
      }
    }
    return [];
  }

    static Future<List<ProfileEntity>> searchUsers(String query) async {
    try {
      final response = await dio.get(
        Api.searchUsers,
        queryParameters: {'q': query},
        options: GetOptions.getOptions(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return (response.data as List)
            .map((e) => ProfileEntity.fromJson(e))
            .toList();
      }
    } catch (e) {
      if (ErrorHandler.handle(e).failure.code != -6) {
        showSnackBarWidget(message: ErrorHandler.handle(e).failure.message ?? "");
      }
    }
    return [];
  }
  static logout() async {
    // Best-effort: clear the push token server-side before dropping the
    // auth token that makes the request possible. If it fails (offline),
    // it's harmless — the token gets overwritten next login anyway.
    await registerFcmToken(null);
    await NotificationService.instance.clearForLogout();
    await sharedPref.remove("token");
    Get.offAllNamed(AppRoutes.loginRoute);
  }
}

class GetOptions {
  static Options options = Options();

  static Options getOptions() {
    final token = sharedPref.getString("token") ?? "";
    if (token.isNotEmpty) {
      options.headers = {
        'Accept': 'application/json',
        'Authorization': token,
      };
    } else {
      options.headers = {
        'Accept': 'application/json',
      }; // default for non-auth
    }
    return options;
  }
}
