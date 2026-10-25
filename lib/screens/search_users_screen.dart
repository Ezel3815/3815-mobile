import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/controllers/search_users_controller.dart';
import 'package:upgrade/main.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/widgets/app_image.dart';

class SearchUsersScreen extends StatelessWidget {
  const SearchUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SearchUsersController());
    return Scaffold(
      backgroundColor: AppColor.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColor.scaffoldBackgroundColor,
        elevation: 0,
        title: TextField(
          autofocus: true,
          onChanged: controller.search,
          decoration: const InputDecoration(
            hintText: "Search by name or username",
            border: InputBorder.none,
          ),
        ),
      ),
      body: Obx(
        () {
          final results = controller.results;
          final searching = controller.loading.value;

          if (results.isEmpty) {
            if (searching) {
              return  Center(
                child: CircularProgressIndicator(color: AppColor.greenColor),
              );
            }
            return Center(
              child: Text(
                controller.query.value.isEmpty
                    ? "Search for people to follow"
                    : "No users found",
                style:  TextStyle(color: AppColor.textSecondary),
              ),
            );
          }
          return Column(
            children: [
              // Thin bar while a newer search is running, so the list does
              // not disappear on every letter typed.
              if (searching)
                 LinearProgressIndicator(
                  minHeight: 2,
                  color: AppColor.greenColor,
                  backgroundColor: Colors.transparent,
                ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final user = results[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Get.toNamed(
                            AppRoutes.viewProfileRoute,
                            arguments: user.id,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColor.surfaceColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColor.edge(0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                ClipOval(
                                  child: (user.avatarPhotoName != null &&
                                          user.avatarPhotoName!.isNotEmpty)
                                      ? AppImage(
                                          image: user.avatarPhotoName!,
                                          width: 44,
                                          height: 44,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          width: 44,
                                          height: 44,
                                          color: AppColor.lightGreenColor,
                                          child:  Icon(Icons.person,
                                              color: AppColor.greenColor),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style:  TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColor.textPrimary,
                                        ),
                                      ),
                                      if (user.username != null)
                                        Text(
                                          "@${user.username}",
                                          style:  TextStyle(
                                            fontSize: 12,
                                            color: AppColor.textSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (user.isFollowing)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppColor.lightGreenColor
                                          .withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child:  Text(
                                      "Following",
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColor.darkGreenColor,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
