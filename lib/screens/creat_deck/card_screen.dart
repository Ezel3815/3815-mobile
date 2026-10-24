import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/controllers/card_controller.dart';
import 'package:upgrade/main.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/screens/app_drawer.dart';
import 'package:upgrade/widgets/card_widget.dart';
import 'package:upgrade/widgets/edit_deck_dialog.dart';

class CardScreen extends GetView<CardController> {
  const CardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    // Phones keep the single list. Tablets get 2 (or 3) cards side by side
    // so the screen is used instead of one thin strip of cards.
    final int columns = screenWidth >= 1000 ? 3 : (screenWidth >= 600 ? 2 : 1);

    return Scaffold(
      drawer: const AppDrawer(),
      key: controller.scaffoldKey,
      drawerEnableOpenDragGesture: false,
      floatingActionButton: !controller.deck.editable
          ? null
          : FloatingActionButton(
              backgroundColor: AppColor.greenColor,
              elevation: 3,
              onPressed: () {
                Get.toNamed(
                  AppRoutes.addCardRoute,
                  arguments: {
                    "id": controller.deck.id,
                    "isEdit": false,
                  },
                );
              },
              child: const Icon(
                Icons.add,
                size: 28,
                color: Colors.white,
              ),
            ),
      body: Container(
        width: double.infinity,
        height: screenHeight,
        color: AppColor.scaffoldBackgroundColor,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Get.back(),
                      child: Icon(
                        Icons.arrow_back,
                        size: 26,
                        color: AppColor.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(
                          height: 28,
                          width: 100,
                          fit: BoxFit.contain,
                          alignment: Alignment.centerLeft,
                          'lib/assests/images/logodeck.png',
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Cards",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColor.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (controller.deck.editable)
                      InkWell(
                        onTap: () {
                          controller.editDeckController.text =
                              controller.deck.title;
                          Get.dialog(const EditDeckDialog());
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColor.surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.chevron_right,
                            size: 22,
                            color: AppColor.textPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Obx(
                () => Expanded(
                  child: controller.loading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppColor.greenColor,
                          ),
                        )
                      : controller.cards.isEmpty
                          ? Center(
                              child: Text(
                                "No cards yet",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: AppColor.textSecondary,
                                ),
                              ),
                            )
                          : Obx(
                              () {
                                // One tappable card (same as before).
                                Widget cardAt(int index) => InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () {
                                        Get.toNamed(
                                          AppRoutes.cardViewRoute,
                                          arguments: {
                                            "cards": controller.cards,
                                            "isView": false,
                                            'initalIndex': index,
                                          },
                                        );
                                      },
                                      child: CardWidget(
                                        model: controller.cards[index],
                                        isEdit: controller.deck.editable,
                                      ),
                                    );

                                final count = controller.cards.length;

                                if (columns == 1) {
                                  return ListView.separated(
                                    padding: const EdgeInsets.only(bottom: 20),
                                    itemBuilder: (context, index) =>
                                        cardAt(index),
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 10),
                                    itemCount: count,
                                  );
                                }

                                // Tablet: rows of 2 or 3 cards.
                                final rows = (count + columns - 1) ~/ columns;
                                return ListView.separated(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 0, 20, 90),
                                  itemCount: rows,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, row) {
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        for (int c = 0; c < columns; c++) ...[
                                          if (c > 0) const SizedBox(width: 10),
                                          Expanded(
                                            child: (row * columns + c) < count
                                                ? cardAt(row * columns + c)
                                                : const SizedBox.shrink(),
                                          ),
                                        ],
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
