import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/controllers/main_controller.dart';
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
            Icon(
              controller.page == 0 ? Icons.home_rounded : Icons.home_outlined,
              color: controller.page == 0
                  ? Colors.white
                  : AppColor.textSecondary,
              size: 26,
            ),
            Icon(
              controller.page == 1 ? Icons.style_rounded : Icons.style_outlined,
              color: controller.page == 1
                  ? Colors.white
                  : AppColor.textSecondary,
              size: 26,
            ),
            Icon(
              controller.page == 2
                  ? Icons.emoji_events_rounded
                  : Icons.emoji_events_outlined,
              color: controller.page == 2
                  ? Colors.white
                  : const Color(0xFFC27F00), // gold: stands out from the rest
              size: 28,
            ),
            Icon(
              controller.page == 3
                  ? Icons.person_rounded
                  : Icons.person_outline_rounded,
              color: controller.page == 3
                  ? Colors.white
                  : AppColor.textSecondary,
              size: 26,
            ),
            Icon(
              controller.page == 4
                  ? Icons.notifications_rounded
                  : Icons.notifications_none_rounded,
              color: controller.page == 4
                  ? Colors.white
                  : AppColor.textSecondary,
              size: 26,
            ),
          ],
          index: controller.page,
          onTap: controller.onChangePage,
        ),
        ),
        ),
      ),
      ),
    );
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
    final items = <(String, String)>[
      ('${base}home.png', AppStrings.navHome),
      ('${base}library.png', AppStrings.navLibrary),
      ('${base}trophy.png', AppStrings.leaderboard),
      ('${base}profile.png', AppStrings.navProfile),
      ('${base}bell.png', AppStrings.navMore),
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
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedScale(
                          scale: index == i ? 1.12 : 1.0,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutBack,
                          child: DecoratedBox(
                            // glow only on the active destination
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: index == i
                                  ? const [BoxShadow(color: Color(0x667358FF), blurRadius: 14)]
                                  : const [],
                            ),
                            child: AnimatedOpacity(
                              opacity: index == i ? 1.0 : .5,
                              duration: const Duration(milliseconds: 220),
                              child: Image.asset(items[i].$1,
                                  width: 26, height: 26),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          items[i].$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: index == i ? FontWeight.w700 : FontWeight.w500,
                            color: index == i
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
