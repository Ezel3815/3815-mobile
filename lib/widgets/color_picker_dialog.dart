import 'package:upgrade/resources.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/strings.dart';

class ColorPickerDialog extends StatefulWidget {
  final Color tempColor;

  const ColorPickerDialog({super.key, required this.tempColor});

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late Color tempColor;

  @override
  void initState() {
    tempColor = widget.tempColor;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColor.card,
      surfaceTintColor: Colors.white,
      title: Text(AppStrings.chooseColor),
      content: SingleChildScrollView(
        child: ColorPicker(
          color: tempColor,
          enableShadesSelection: false,
          enableOpacity: false,
          width: 44,
          height: 44,
          borderRadius: 22,
          // Was growing a "recently used" row of circles every time a new
          // color was picked (up to 8), which read as a visual glitch since
          // nothing in the UI explains what that row is. Off for a fixed,
          // predictable palette.
          showRecentColors: false,
          borderColor: Colors.black,
          hasBorder: true,
          onColorChanged: (Color color) {
            tempColor = color;
          },
          pickerTypeLabels: <ColorPickerType, String>{
            ColorPickerType.primary: AppStrings.primaryColorLabel,
            ColorPickerType.accent: AppStrings.accentColorLabel,
          },
          heading: Text(
            AppStrings.selectColor,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          subheading: Text(
            AppStrings.selectColorShade,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(AppStrings.ok),
          onPressed: () {
            Get.back(result: tempColor);
          },
        ),
      ],
    );
  }
}
