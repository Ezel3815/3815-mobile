import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:upgrade/controllers/document_controller.dart';
import 'package:upgrade/di.dart';
import 'package:upgrade/network_info.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/screens/app_drawer.dart';
import 'package:upgrade/strings.dart';
import 'package:upgrade/widgets/app_snack_bar.dart';
import 'package:upgrade/widgets/download_dialog.dart';
import 'package:upgrade/widgets/tablet_bounded.dart';

class DocumentScreen extends GetView<DocumentController> {
  const DocumentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: AppColor.scaffoldBackgroundColor,
            image: DecorationImage(
              image: AssetImage("lib/assests/images/background_6.jpg"),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Scaffold(
          key: controller.scaffoldKey,
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: TabletBounded(
              child: Column(
              children: [
                const SizedBox(
                  height: 10,
                ),
                Row(
                  children: [
                    const SizedBox(
                      width: 10,
                    ),
                    InkWell(
                      onTap: () {
                        controller.scaffoldKey.currentState?.openDrawer();
                      },
                      child: const Icon(
                        Icons.dehaze,
                        size: 30,
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(
                          height: 30,
                          width: 100,
                          'lib/assests/images/logodeck.png',
                        ),
                        Text(
                          AppStrings.pdfFiles,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColor.ink.withOpacity(.4),
                          ),
                        )
                      ],
                    ),
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                Row(
                  children: [
                    const SizedBox(
                      width: 20,
                    ),
                    Expanded(
                      child: TextFormField(
                        onChanged: (value) {
                          controller.searchList = controller.docs
                              .where((item) => item.title
                                  .toLowerCase()
                                  .contains(value.toLowerCase()))
                              .toList();
                        },
                        onTapOutside: (event) =>
                            FocusScope.of(context).unfocus(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: AppColor.ink, width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: AppColor.ink, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: AppColor.ink, width: 2),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    // Icon(
                    //   Icons.filter_alt,
                    //   color: AppColor.ink,
                    //   size: 35,
                    // ),
                    // const SizedBox(
                    //   width: 20,
                    // ),
                  ],
                ),
                const SizedBox(
                  height: 20,
                ),
                Obx(
                  () => Expanded(
                    child: controller.loading
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : controller.searchList.isNotEmpty
                            ? ListView.builder(
                                itemCount: controller.searchList.length,
                                padding: const EdgeInsets.only(bottom: 20),
                                itemBuilder: (context, index) {
                                  return Column(
                                    children: [
                                      InkWell(
                                        onTap: () async {
                                          if (await isFileValid(controller
                                              .searchList[index].name)) {
                                            final dir =
                                                await getApplicationDocumentsDirectory();
                                            final fileName = controller
                                                .searchList[index].name
                                                .split("/")
                                                .last;
                                            final filePath =
                                                "${dir.path}/$fileName";
                                            OpenFilex.open(filePath);
                                          } else {
                                            Get.dialog(DownloadDialog(
                                                file: controller
                                                    .searchList[index].name));
                                          }
                                        },
                                        child: Row(
                                          children: [
                                            const SizedBox(
                                              width: 20,
                                            ),
                                            SvgPicture.asset(
                                              "lib/assests/svgs/pdf.svg",
                                              width: 40,
                                              colorFilter: ColorFilter.mode(
                                                Colors.black.withOpacity(.75),
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 8,
                                            ),
                                            Flexible(
                                              child: Text(
                                                controller
                                                    .searchList[index].title,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColor.ink,
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                      Divider(
                                        height: 20,
                                        color: AppColor.ink,
                                        thickness: 2,
                                      ),
                                    ],
                                  );
                                },
                              )
                            : ListView.builder(
                                itemCount: controller.docs.length,
                                padding: const EdgeInsets.only(bottom: 20),
                                itemBuilder: (context, index) {
                                  return Column(
                                    children: [
                                      InkWell(
                                        onTap: () async {
                                          if (await isFileValid(
                                              controller.docs[index].name)) {
                                            final dir =
                                                await getApplicationDocumentsDirectory();
                                            final fileName = controller
                                                .docs[index].name
                                                .split("/")
                                                .last;
                                            final filePath =
                                                "${dir.path}/$fileName";
                                            OpenFilex.open(filePath);
                                          } else {
                                            Get.dialog(DownloadDialog(
                                                file: controller
                                                    .docs[index].name));
                                          }
                                        },
                                        child: Row(
                                          children: [
                                            const SizedBox(
                                              width: 20,
                                            ),
                                            SvgPicture.asset(
                                              "lib/assests/svgs/pdf.svg",
                                              width: 40,
                                              colorFilter: ColorFilter.mode(
                                                Colors.black.withOpacity(.75),
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 8,
                                            ),
                                            Flexible(
                                              child: Text(
                                                controller.docs[index].title,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColor.ink,
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                      Divider(
                                        height: 20,
                                        color: AppColor.ink,
                                        thickness: 2,
                                      ),
                                    ],
                                  );
                                },
                              ),
                  ),
                )
              ],
              ),
            ),
          ),
          drawer: const AppDrawer(),
          endDrawerEnableOpenDragGesture: false,
        ),
      ],
    );
  }
}

Future<bool> isFileValid(String url) async {
  final dir = await getApplicationDocumentsDirectory();
  final fileName = url.split("/").last;
  final filePath = "${dir.path}/$fileName";
  final file = File(filePath);
  if (await file.exists()) {
    try {
      final dio = Dio();
      final response = await dio.head(url);
      final expectedFileSize =
          response.headers.value(HttpHeaders.contentLengthHeader);

      if (expectedFileSize != null &&
          await file.length() == int.parse(expectedFileSize)) {
        if (Get.isDialogOpen == true) {
          Get.back();
        }
        return true;
      }
    } catch (e) {
      return true;
    }
  }
  if (Get.isDialogOpen == true) {
    Get.back();
  }
  return false;
}
