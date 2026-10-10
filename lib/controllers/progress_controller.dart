import 'package:upgrade/widgets/app_snack_bar.dart';
import 'package:upgrade/entity/quests_entity.dart';
import 'package:get/get.dart';
import 'package:upgrade/controllers/api_controller.dart';
import 'package:upgrade/controllers/years_controller.dart';
import 'package:upgrade/entity/achievement.dart';
import 'package:upgrade/entity/leaderboard_entry.dart';
import 'package:upgrade/entity/card_entity.dart';
import 'package:upgrade/entity/deck_entity.dart';

class SubjectProgress {
  final String title;
  final int totalCards;
  final int masteredCards; // answered GOOD or EASY

  SubjectProgress({
    required this.title,
    required this.totalCards,
    required this.masteredCards,
  });

  double get mastery => totalCards == 0 ? 0 : masteredCards / totalCards;
}

enum ProgressTab { statistics, leaderboard, achievements, mossad }

class ProgressController extends GetxController {
  final yearsController = Get.find<YearsController>();
  // The first tab (enum name kept as `achievements`) is now "المهام" (quests).
  final Rx<ProgressTab> tab = ProgressTab.achievements.obs;

  final RxList<LeaderboardEntry> leaderboard = <LeaderboardEntry>[].obs;
  final RxBool leaderboardLoading = false.obs;

  /// "Mossad" — the open competition between all preparatory-year students.
  final Rxn<MossadData> mossad = Rxn<MossadData>();
  final RxBool mossadLoading = false.obs;

  Future<void> loadMossad() async {
    mossadLoading.value = true;
    final data = await ApiController.getMossad();
    if (data != null) mossad.value = data; // keep the old ranking on failure
    mossadLoading.value = false;
  }

  Future<void> loadLeaderboard() async {
    leaderboardLoading.value = true;
    leaderboard.assignAll(await ApiController.getLeaderboard());
    leaderboardLoading.value = false;
  }

  final Rxn<QuestsData> quests = Rxn<QuestsData>();
  final RxBool questsLoading = false.obs;
  final RxBool questsFailed = false.obs;
  final RxString claimingId = ''.obs;
  final RxBool remindBusy = false.obs;

  /// Nudge the friends-quest partner (feed post + push notification).
  Future<void> remindPartner(QuestPerson p) async {
    if (remindBusy.value) return;
    remindBusy.value = true;
    final r = await ApiController.remindFriend(p.id);
    remindBusy.value = false;
    if (r == null) return; // ApiController already showed the error
    if (r['sent'] == true) {
      showSnackBarWidget(message: 'تم إرسال التذكير إلى ${p.name} 👋');
    } else if (r['reason'] == 'already_studied') {
      showSnackBarWidget(message: '${p.name} درس اليوم بالفعل 🎉');
    } else {
      showSnackBarWidget(message: 'أرسلت تذكيراً إلى ${p.name} اليوم بالفعل');
    }
    loadQuests();
  }

  /// Picks who the friends quest is played with, then refreshes the quests.
  Future<bool> choosePartner(int friendId) async {
    final ok = await ApiController.setQuestPartner(friendId);
    if (ok) await loadQuests();
    return ok;
  }

  Future<void> loadQuests() async {
    if (quests.value == null) questsLoading.value = true;
    final data = await ApiController.getQuests();
    questsFailed.value = data == null && quests.value == null;
    if (data != null) quests.value = data;
    questsLoading.value = false;
  }

  /// Opens a ready chest, then refreshes quests + Home/leaderboard XP.
  Future<int?> claimChest(String id) async {
    if (claimingId.value.isNotEmpty) return null;
    claimingId.value = id;
    final xp = await ApiController.claimQuestChest(id);
    claimingId.value = '';
    if (xp != null) {
      await loadQuests();
      loadLeaderboard();
      loadMossad();
    }
    return xp;
  }

  final RxList<Achievement> achievements = <Achievement>[].obs;
  final RxBool achievementsLoading = false.obs;

  Future<void> loadAchievements() async {
    achievementsLoading.value = true;
    achievements.assignAll(await ApiController.getAchievements());
    achievementsLoading.value = false;
  }

  @override
  void onInit() {
    loadLeaderboard();
    loadMossad();
    loadAchievements();
    loadQuests();
    super.onInit();
  }

  List<CardEntity> _allCards(List<DeckEntity> decks) {
    final result = <CardEntity>[];
    for (final d in decks) {
      if (d.type == "CARDS_DECK") {
        result.addAll(d.cards);
      } else {
        result.addAll(_allCards(d.children));
      }
    }
    return result;
  }

  /// A "subject" is a PACKAGE_DECK whose direct children are all leaf
  /// CARDS_DECK (i.e. one level above chapters) — same convention used
  /// for the guided lesson path on Home.
  List<SubjectProgress> get subjectBreakdown {
    List<SubjectProgress> collect(List<DeckEntity> decks) {
      final result = <SubjectProgress>[];
      for (final d in decks) {
        if (d.type != "PACKAGE_DECK") continue;
        final isSubjectLevel = d.children.isNotEmpty &&
            d.children.every((c) => c.type == "CARDS_DECK");
        if (isSubjectLevel) {
          final cards = d.children.expand((c) => c.cards).toList();
          final mastered = cards
              .where((c) => c.answer == "GOOD" || c.answer == "EASY")
              .length;
          result.add(SubjectProgress(
            title: d.title,
            totalCards: cards.length,
            masteredCards: mastered,
          ));
        } else {
          result.addAll(collect(d.children));
        }
      }
      return result;
    }

    return collect(yearsController.decks);
  }

  int get totalCardsReviewed {
    final cards = _allCards(yearsController.decks);
    return cards
        .where((c) => c.answer.isNotEmpty && c.answer != "NONE")
        .length;
  }

  int get masteryPercent {
    final cards = _allCards(yearsController.decks);
    final reviewed =
        cards.where((c) => c.answer.isNotEmpty && c.answer != "NONE").toList();
    if (reviewed.isEmpty) return 0;
    final mastered =
        reviewed.where((c) => c.answer == "GOOD" || c.answer == "EASY").length;
    return ((mastered / reviewed.length) * 100).round();
  }

  int get streak => yearsController.profile.value?.currentStreak ?? 0;
}
