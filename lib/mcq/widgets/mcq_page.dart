import 'package:flutter/material.dart';
import 'package:upgrade/mcq/widgets/mcq_widgets.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/widgets/tablet_bounded.dart';

/// Shell for every pushed MCQ screen: themed background, safe area, and the
/// app's existing tablet width cap.
class McqPage extends StatelessWidget {
  final Widget child;
  const McqPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.scaffoldBackgroundColor,
      body: McqBackdrop(
        child: SafeArea(child: TabletBounded(child: child)),
      ),
    );
  }
}
