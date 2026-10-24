import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:path_provider/path_provider.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:upgrade/resources.dart';

import 'app_button.dart';
import 'app_snack_bar.dart';
import 'success_dialog.dart';

class DownloadDialog extends StatefulWidget {
  final String file;

  const DownloadDialog({super.key, required this.file});

  @override
  State<DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<DownloadDialog> {
  bool isError = false;
  CancelToken token = CancelToken();
  double progress = 0.0;

  @override
  void initState() {
    downloadALlFiles();
    super.initState();
  }

  downloadALlFiles() async {
    isError = false;
    token = CancelToken();
    setState(() {});
    if (!isError) {
      await downloadFile(widget.file);
    }
    if (progress.toInt() == 1) {
      Get.back();
      Get.dialog(const SuccessDownloadDialog());
    }
  }

  downloadFile(String url) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = url.split("/").last;

      final filePath = "${dir.path}/$fileName";

      final dio = Dio();
      if (!kReleaseMode) {
        dio.interceptors.add(PrettyDioLogger(
            requestHeader: true, requestBody: true, responseHeader: true));
      }

      if (await File(filePath).exists() && await isFileValid(url)) {
        progress = 1;
        setState(() {});
        return;
      }

      await dio.download(
        url,
        filePath,
        cancelToken: token,
        onReceiveProgress: (count, total) {
          progress = count / total;
          setState(() {});
        },
      );

      progress = 1;
      setState(() {});
      isError = false;
    } catch (e) {
      isError = true;
      token.cancel();
      setState(() {});
      log(e.toString());
      if (e is DioException) {
        if (e.type != DioExceptionType.cancel) {
          showSnackBarWidget(message: "There was an error downloading files!");
        }
      }
    }
  }

  checkIfFileExiest(String url) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = url.split("/").last;

    final filePath = "${dir.path}/$fileName";

    if (await File(filePath).exists()) {
      return true;
    }
    return false;
  }

  Future<bool> isFileValid(String url) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = url.split("/").last;
    final filePath = "${dir.path}/$fileName";
    final file = File(filePath);
    if (await file.exists()) {
      final dio = Dio();
      final response = await dio.head(url);
      final expectedFileSize =
          response.headers.value(HttpHeaders.contentLengthHeader);

      if (expectedFileSize != null &&
          await file.length() == int.parse(expectedFileSize)) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: AppColor.card,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusDirectional.circular(10),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 30),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Loading ...",
                style: Get.textTheme.labelLarge!.copyWith(
                  fontSize: 18,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  Text(
                    "${(progress * 100).toStringAsFixed(2)} %",
                    style: Get.textTheme.labelMedium!.copyWith(
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: LinearPercentIndicator(
                      percent: progress,
                      barRadius: const Radius.circular(10),
                      lineHeight: 8,
                      progressColor: AppColor.greenColor,
                    ),
                  ),
                ],
              ),
              // 20.verticalSpace(),
              // Row(
              //   children: [
              //     Text(
              //       "${downloadedFiles.length}/${files.length}",
              //       style: Get.textTheme.labelMedium!.copyWith(
              //         fontSize: AppSize.s14(context),
              //       ),
              //     ),
              //     8.horizontalSpace(),
              //     Expanded(
              //       child: LinearPercentIndicator(
              //         percent: downloadedFiles.length / files.length,
              //         barRadius: const Radius.circular(10),
              //         lineHeight: 8,
              //         progressColor: ColorManager.green,
              //       ),
              //     ),
              //   ],
              // ),
              const SizedBox(
                height: 20,
              ),
              Text(
                "Note: When you delete the application or delete the cache, all downloaded items are deleted.",
                style: Get.textTheme.labelMedium!.copyWith(
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                "Note: When you press the back button, the download of files will stop.",
                style: Get.textTheme.labelMedium!.copyWith(
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              AppButton(
                title: isError ? "Try Again" : "Cancel",
                width: width,
                backgroundColor: Colors.red,
                onTap: () async {
                  if (isError) {
                    await downloadALlFiles();
                  } else {
                    token.cancel();
                  }
                },
              ),
              const SizedBox(
                height: 10,
              ),
              AppButton(
                title: "Back",
                style: Get.textTheme.labelMedium,
                width: width,
                backgroundColor: Colors.grey[300],
                onTap: () {
                  Get.closeAllSnackbars();
                  token.cancel();
                  Get.back();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
