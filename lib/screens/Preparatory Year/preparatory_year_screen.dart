import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/controllers/preparatory_year_controller.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/screens/app_drawer.dart';
import 'package:upgrade/widgets/deck_widget.dart';
import 'package:upgrade/widgets/lesson_path_widget.dart';
import 'package:upgrade/widgets/tablet_bounded.dart';

class PreparatoryYear extends StatelessWidget {
  final String id;
  const PreparatoryYear({super.key, required this.id}); // was: const PreparatoryYear({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PreparatoryYearController>(
      tag: id, // was: tag: Get.arguments['id'].toString(),
      builder: (controller) {
        // If every child at this level is a leaf CARDS_DECK, we're at
        // chapter depth — render the guided lesson path. Otherwise this
        // is a folder level (Year / Semester / Subject) — keep the
        // existing plain list navigation.
        final isChapterLevel = controller.decks.isNotEmpty &&
            controller.decks.every((d) => d.type == "CARDS_DECK");

        return Scaffold(
          key: controller.scaffoldKey,
          drawer: const AppDrawer(),
          backgroundColor: AppColor.scaffoldBackgroundColor,
          body: SafeArea(
            child: TabletBounded(
              child: Column(
              children: [
                const SizedBox(height: 10),
                Row(
                  children: [
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () => Get.back(),
                      child: Icon(
                        Icons.arrow_back,
                        size: 26,
                        color: AppColor.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Image.asset(
                      height: 28,
                      width: 100,
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                      'lib/assests/images/logodeck.png',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: controller.decks.isEmpty
                      ? Center(
                          child: Text(
                            "No Data Found",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColor.textPrimary,
                            ),
                          ),
                        )
                      : isChapterLevel
                          ? LessonPathWidget(chapters: controller.decks)
                          : ListView.separated(
                              padding: const EdgeInsets.only(bottom: 20),
                              itemBuilder: (context, index) =>
                                  DeckWidget(model: controller.decks[index]),
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 10),
                              itemCount: controller.decks.length,
                            ),
                ),
              ],
              ),
            ),
          ),
        );
      },
    );
  }
}
