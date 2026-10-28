import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:upgrade/offline/offline_store.dart';
import 'package:upgrade/services/streak_widget_service.dart';
import 'package:get/get.dart';
import 'package:upgrade/controllers/api_controller.dart';
import 'package:upgrade/entity/activity_feed_item.dart';
import 'package:upgrade/entity/daily_mission.dart';
import 'package:upgrade/entity/deck_entity.dart';
import 'package:upgrade/entity/profile_entity.dart';
import 'package:upgrade/main.dart';
import 'package:upgrade/models/user_model.dart';
import 'package:upgrade/services/notification_service.dart';

class YearsController extends GetxController with WidgetsBindingObserver {
  final RxBool _loading = false.obs;

  // Must be reactive (RxList), not a plain List — Obx widgets elsewhere
  // (progress card, learning path list) read this directly, and GetX
  // throws "improper use of GetX" if there's no observable inside an
  // Obx scope. RxList behaves like a normal List everywhere else it's
  // read (Progress, Library, etc. all keep working unchanged).
  final RxList<DeckEntity> decks = <DeckEntity>[].obs;

  final Rx<ProfileEntity?> profile = Rx<ProfileEntity?>(null);
  final RxList<ActivityFeedItem> activityFeed = <ActivityFeedItem>[].obs;
  final RxList<DailyMission> missions = <DailyMission>[].obs;

  bool get loading => _loading.value;

  set loading(value) => _loading.value = value;

  /// A "subject" is a PACKAGE_DECK whose direct children are all leaf
  /// CARDS_DECK (chapters) — same convention used by Library/Progress.
  List<DeckEntity> _collectSubjects(List<DeckEntity> nodes) {
    final result = <DeckEntity>[];
    for (final node in nodes) {
      if (node.type != "PACKAGE_DECK") continue;
      // Any package holding chapters directly is a subject (even if it
      // also holds sub-packages); keep looking inside sub-packages too.
      if (node.children.any((c) => c.type == "CARDS_DECK")) {
        result.add(node);
      }
      result.addAll(_collectSubjects(
          node.children.where((c) => c.type == "PACKAGE_DECK").toList()));
    }
    return result;
  }

  bool _isSubjectComplete(DeckEntity subject) {
    final cards = subject.children.expand((c) => c.cards).toList();
    if (cards.isEmpty) return false;
    return cards.every((c) => c.answer.isNotEmpty && c.answer != "NONE");
  }

  /// The subject Home should show front-and-center: the first one with
  /// unfinished chapters. Falls back to the first subject at all if
  /// every subject is complete (or none has any cards yet), and to
  /// null only when there are no subjects in the tree at all.
  DeckEntity? get currentSubject {
    final subjects = _collectSubjects(decks);
    if (subjects.isEmpty) return null;
    // Prefer the subject the user last studied.
    final lastId = sharedPref.getInt('last_subject_id');
    if (lastId != null) {
      for (final s in subjects) {
        if (s.id == lastId) return s;
      }
    }
    return subjects.firstWhere(
      (s) => !_isSubjectComplete(s),
      orElse: () => subjects.first,
    );
  }

  /// Remember which subject a studied chapter belongs to, so Home follows
  /// what the user is actually studying.
  void rememberSubjectForDeck(int deckId) {
    for (final s in _collectSubjects(decks)) {
      if (s.children.any((c) => c.id == deckId)) {
        if (sharedPref.getInt('last_subject_id') != s.id) {
          sharedPref.setInt('last_subject_id', s.id);
          decks.refresh();
        }
        return;
      }
    }
  }

  DateTime? _lastRefresh;
  Timer? _refreshTimer;

  /// [silent]: a background refresh — no error messages, the student keeps studying.
  Future<void> getAllDeck({bool silent = false}) async {
    // Open at once from what the phone already has (the last successful load);
    // the server answer then replaces it in the background.
    if (decks.isEmpty) {
      final cached = await ApiController.cachedDecks();
      if (cached.isNotEmpty) decks.assignAll(cached);
    }
    // Only show the full-screen spinner when there is nothing saved at all (first install).
    final isFirstLoad = decks.isEmpty;
    if (isFirstLoad) loading = true;

    ApiController.quiet = silent;
    final List<List<DeckEntity>> results;
    try {
      results = await Future.wait([
        ApiController.getDecks(),
        ApiController.getMyDecks(),
      ]);
    } finally {
      ApiController.quiet = false;
    }
    _lastRefresh = DateTime.now();

    // A failed request returns [] — don't let that wipe decks already shown.
    final failed = ApiController.lastDecksFailed || ApiController.lastMyDecksFailed;
    if (!(failed && decks.isNotEmpty)) {
      decks.assignAll([...results[0], ...results[1]]);
      // New cards the teachers uploaded: refresh the downloaded subjects too (in the background).
      OfflineStore.syncAll(decks);
    }
    loading = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final last = _lastRefresh;
    if (last == null || DateTime.now().difference(last) > const Duration(seconds: 60)) {
      getAllDeck(silent: true);
    }
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  int? _getMyId() {
    final userJson = sharedPref.getString("user");
    if (userJson == null) return null;
    return UserModel.fromJson(jsonDecode(userJson)).id;
  }

  Future<void> getMyProfile() async {
    final id = _getMyId();
    if (id == null) return;
    profile.value = await ApiController.getProfile(id);
  }

  Future<void> getActivityFeed() async {
    activityFeed.assignAll(await ApiController.getActivityFeed());
  }

  Future<void> getDailyMissions() async {
    missions.assignAll(await ApiController.getDailyMissions());
  }

  @override
  void onInit() async {
    WidgetsBinding.instance.addObserver(this);
    // While the app stays open, pick up new cards every few minutes.
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) => getAllDeck(silent: true));
    await Future.wait([
      getAllDeck(),
      getMyProfile(),
      getActivityFeed(),
      getDailyMissions(),
    ]);
    StreakWidgetService.instance.sync(streak: profile.value?.currentStreak);
    // Fire-and-forget: don't block Home from loading on this.
    NotificationService.instance
        .requestPermission()
        .then((_) => NotificationService.instance.onAppOpened());
    super.onInit();
  }
}
