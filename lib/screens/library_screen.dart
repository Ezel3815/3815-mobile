import 'package:upgrade/widgets/app_snack_bar.dart';
import 'package:upgrade/utils/chapter_navigation.dart';
import 'package:upgrade/utils/subject_icon.dart';
import 'package:upgrade/strings.dart';
import 'package:upgrade/screens/ai_scan/ai_scan.dart';
import 'package:upgrade/screens/ai_scan/ai_scan_strings.dart';
import 'package:upgrade/controllers/years_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:upgrade/controllers/library_controller.dart';
import 'package:upgrade/entity/card_entity.dart';
import 'package:upgrade/entity/deck_entity.dart';
import 'package:upgrade/main.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/screens/app_drawer.dart';
import 'package:upgrade/widgets/mozaik_mark_icon.dart';
import 'package:upgrade/widgets/tablet_bounded.dart';

/// A small set of accent colors used only to visually distinguish deck
/// cards in the library grid (not tied to any real "subject category"
/// data, since that doesn't exist in the backend yet). Cycled by index.
final List<Color> _deckAccentColors = [
  AppColor.greenColor,
  AppColor.infoColor,
  AppColor.warningColor,
  Color(0xFF7C6FA8), // muted plum, for visual variety only
  AppColor.freshGreenColor,
];

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LibraryController());
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: AppColor.scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      drawerEnableOpenDragGesture: false,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColor.greenColor,
        onPressed: () => AiScan.showAddMenu(
          context: context,
          onManual: () => Get.toNamed(AppRoutes.createDeckRoute),
          onDeckChanged: () => Get.find<YearsController>().getAllDeck(),
          manualLabel: AiStr.newDeck,
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: SafeArea(
        child: TabletBounded(
          child: Column(
          children: [
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => scaffoldKey.currentState?.openDrawer(),
                    child:  Icon(
                      Icons.dehaze,
                      size: 26,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    AppStrings.navLibrary,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColor.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColor.surfaceColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.edge(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      PhosphorIcons.magnifyingGlass(PhosphorIconsStyle.bold),
                      size: 18,
                      color: AppColor.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => controller.query.value = v,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          hintText: AppStrings.searchSubjectHint,
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: AppColor.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 34,
              child: Obx(
                () => ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _YearChip(
                      label: AppStrings.allYears,
                      selected: controller.selectedYearId.value == null,
                      onTap: () => controller.selectedYearId.value = null,
                    ),
                    for (final year in controller.availableYears) ...[
                      const SizedBox(width: 8),
                      _YearChip(
                        label: year.title,
                        selected: controller.selectedYearId.value == year.id,
                        onTap: () => controller.selectedYearId.value = year.id,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: Obx(
                () => ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _FilterPill(
                      label: AppStrings.all,
                      selected: controller.filter.value == LibraryFilter.all,
                      onTap: () => controller.filter.value = LibraryFilter.all,
                    ),
                    const SizedBox(width: 8),
                    _FilterPill(
                      label: AppStrings.myCards,
                      selected: controller.filter.value == LibraryFilter.mine,
                      onTap: () =>
                          controller.filter.value = LibraryFilter.mine,
                    ),
                    const SizedBox(width: 8),
                    _FilterPill(
                      label: AppStrings.createdByMe,
                      selected:
                          controller.filter.value == LibraryFilter.created,
                      onTap: () =>
                          controller.filter.value = LibraryFilter.created,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Obx(() {
                final subjects = controller.filteredSubjects;
                if (subjects.isEmpty) {
                  return Center(
                    child: Text(
                      AppStrings.noSubjects,
                      style: TextStyle(color: AppColor.textSecondary),
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isTabletWidth(context) ? 3 : 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.92,
                  ),
                  itemCount: subjects.length,
                  itemBuilder: (context, index) => _SubjectCard(
                    subject: subjects[index],
                    accentColor:
                        _deckAccentColors[index % _deckAccentColors.length],
                  ),
                );
              }),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class _YearChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _YearChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColor.darkGreenColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppColor.darkGreenColor
                : AppColor.edge(0.12),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color:
                selected ? AppColor.darkGreenColor : AppColor.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColor.greenColor : AppColor.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? null
              : Border.all(color: AppColor.edge(0.06)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColor.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Every card inside a deck, however deeply it is nested.
List<CardEntity> _allCardsIn(DeckEntity deck) {
  if (deck.type == "CARDS_DECK") return deck.cards;
  return deck.children.expand(_allCardsIn).toList();
}

class _SubjectCard extends StatelessWidget {
  final DeckEntity subject;
  final Color accentColor;
  const _SubjectCard({required this.subject, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    // Subjects are folders (PACKAGE_DECK) — their cards live on their
    // chapter children, not on the subject node itself.
    final isCardsDeck = subject.type == "CARDS_DECK";
    final allCards = _allCardsIn(subject);
    final total = allCards.length;
    final answered =
        allCards.where((c) => c.answer.isNotEmpty && c.answer != "NONE").length;
    final progress = total == 0 ? 0.0 : answered / total;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        if (subject.locked) {
          showSnackBarWidget(
              message: AppStrings.subjectLockedHint);
          return;
        }
        if (isCardsDeck) {
          openChapter(subject);
          return;
        }
        Get.toNamed(
          AppRoutes.preparatoryYearRoute,
          arguments: {
            "id": subject.id,
            "decks": subject.children,
          },
          preventDuplicates: false,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColor.surfaceColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColor.edge(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppColor.night
                    ? Image.asset(
                        nocturneMedicalIcon(subject.title) ??
                            'lib/assests/nocturne/icons/icon-flashcard-tile.png',
                        width: 72,
                        height: 72,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Center(
                            child: MozaikMarkIcon(color: accentColor, size: 40),
                          ),
                        ),
                      )
                    : Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(
                          child: MozaikMarkIcon(color: accentColor, size: 40),
                        ),
                      ),
                subject.locked
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColor.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                             Icon(Icons.lock,
                                size: 12, color: AppColor.textSecondary),
                            const SizedBox(width: 3),
                            Text(AppStrings.locked,
                                style:  TextStyle(
                                    fontSize: 10,
                                    color: AppColor.textSecondary)),
                          ],
                        ),
                      )
                    : Icon(
                        Icons.chevron_right_rounded,
                        color: AppColor.textSecondary,
                        size: 20,
                      ),
              ],
            ),
            const Spacer(),
            Text(
              subject.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:  TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColor.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.cardsCount(total),
              style:  TextStyle(
                fontSize: 11,
                color: AppColor.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: AppColor.scaffoldBackgroundColor,
                valueColor: AlwaysStoppedAnimation(accentColor),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${(progress * 100).round()}%",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
