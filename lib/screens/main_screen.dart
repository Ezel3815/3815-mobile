import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/controllers/main_controller.dart';
import 'package:upgrade/mcq/mcq_strings.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/strings.dart';
import 'app_drawer.dart';

class MainScreen extends GetView<MainController> {
  const MainScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => PopScope(
        canPop: controller.page == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) controller.onChangePage(0);
        },
        child: Scaffold(
        key: controller.scaffoldKey,
        body: controller.pages[controller.page],
        drawerEnableOpenDragGesture: false,
        drawer: const AppDrawer(),
        bottomNavigationBar: AppColor.night
            ? _NightNavBar(
                index: controller.page, onTap: controller.onChangePage)
            : Container(
          color: AppColor.surfaceColor,
          child: SafeArea(
          top: false,
          child: CurvedNavigationBar(
          color: AppColor.surfaceColor,
          backgroundColor: AppColor.scaffoldBackgroundColor,
          buttonBackgroundColor: AppColor.greenColor,
          height: 56,
          items: [
            for (final p in MainController.navOrder)
              _lightIcon(p, controller.page),
          ],
          index: MainController.navOrder.indexOf(controller.page),
          onTap: (pos) =>
              controller.onChangePage(MainController.navOrder[pos]),
        ),
        ),
        ),
      ),
      ),
    );
  }


  /// Icon for page [p] in the light curved bar.
  Widget _lightIcon(int p, int current) {
    final on = current == p;
    final idle = AppColor.textSecondary;
    switch (p) {
      case 0:
        return Icon(on ? Icons.home_rounded : Icons.home_outlined,
            color: on ? Colors.white : idle, size: 26);
      case 1:
        return Icon(on ? Icons.style_rounded : Icons.style_outlined,
            color: on ? Colors.white : idle, size: 26);
      case 2:
        return Icon(
            on ? Icons.emoji_events_rounded : Icons.emoji_events_outlined,
            color: on ? Colors.white : const Color(0xFFC27F00), // gold
            size: 28);
      case 3:
        return Icon(on ? Icons.person_rounded : Icons.person_outline_rounded,
            color: on ? Colors.white : idle, size: 26);
      case 5:
        return Icon(on ? Icons.quiz_rounded : Icons.quiz_outlined,
            color: on ? Colors.white : idle, size: 26);
      default:
        return Icon(
            on ? Icons.notifications_rounded : Icons.notifications_none_rounded,
            color: on ? Colors.white : idle, size: 26);
    }
  }
}


/// Nocturne bottom bar: flat, labeled tabs with a violet glow on the active
/// one (matches the design board). Light mode keeps the curved bar.
class _NightNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _NightNavBar({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const base = 'lib/assests/nocturne/icons/icon-';
    // (page index, icon asset or null for the MCQ glyph, label), in bar order.
    final items = <(int, String?, String)>[
      (0, '${base}home.png', AppStrings.navHome),
      (1, '${base}library.png', AppStrings.navLibrary),
      (5, null, McqStrings.tab),
      (2, '${base}trophy.png', AppStrings.leaderboard),
      (3, '${base}profile.png', AppStrings.navProfile),
      (4, '${base}bell.png', AppStrings.navMore),
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppColor.elevatedColor,
        border: Border(top: BorderSide(color: AppColor.glowBorder)),
        boxShadow: const [
          BoxShadow(color: Color(0x0D7358FF), blurRadius: 10, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onTap(items[i].$1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedScale(
                          scale: index == items[i].$1 ? 1.12 : 1.0,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutBack,
                          child: DecoratedBox(
                            // glow only on the active destination
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: index == items[i].$1
                                  ? const [BoxShadow(color: Color(0x667358FF), blurRadius: 14)]
                                  : const [],
                            ),
                            child: AnimatedOpacity(
                              opacity: index == items[i].$1 ? 1.0 : .5,
                              duration: const Duration(milliseconds: 220),
                              child: items[i].$2 == null
                                  ? const Icon(Icons.quiz_rounded,
                                      size: 26, color: Color(0xFFA98CFF))
                                  : Image.asset(items[i].$2!,
                                      width: 26, height: 26),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          items[i].$3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: index == items[i].$1 ? FontWeight.w700 : FontWeight.w500,
                            color: index == items[i].$1
                                ? const Color(0xFFA98CFF)
                                : const Color(0xFF777594),
                          ),
                        ),
                      ],
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
