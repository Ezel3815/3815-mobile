import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/resources.dart';

class AppButton extends StatelessWidget {
  final double? width;
  final Color? backgroundColor;
  final void Function()? onTap;
  final EdgeInsetsGeometry? padding;
  final String title;
  final Widget? child;
  final AlignmentGeometry? alignment;
  final TextStyle? style;
  final double? elevation;
  final double? radius;

  const AppButton({
    required this.title,
    this.width,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.alignment,
    this.child,
    this.style,
    this.elevation,
    this.radius,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ButtonStyle(
        padding: WidgetStatePropertyAll(
            padding ?? const EdgeInsets.symmetric(horizontal: 30, vertical: 4)),
        fixedSize: WidgetStatePropertyAll(
            width != null ? Size.fromWidth(width!) : null),
        shadowColor: WidgetStatePropertyAll(AppColor.greenColor),
        alignment: alignment ?? AlignmentDirectional.center,
        elevation: WidgetStatePropertyAll(elevation ?? 10),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius ?? 30),
          ),
        ),
        backgroundColor:
            WidgetStatePropertyAll(backgroundColor ?? AppColor.greenColor),
      ),
      child: child ??
          Text(
            title,
            style: style ?? context.textTheme.bodyLarge!.copyWith(
              color: Colors.white,
            ),
          ),
    );
  }
}
