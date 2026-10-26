import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart' show IconData;

// Material-icons shim. Keeps the old call style
//   PhosphorIcons.house(PhosphorIconsStyle.bold)
// so no screen needs to change, but every icon now comes from Flutter's
// built-in Material font (uses-material-design: true) — no extra icon
// font or package needed.

enum PhosphorIconsStyle { thin, light, regular, bold, fill, duotone }

class _Icon {
  final IconData outlined;
  final IconData filled;
  const _Icon(this.outlined, this.filled);

  IconData call([PhosphorIconsStyle style = PhosphorIconsStyle.regular]) {
    switch (style) {
      case PhosphorIconsStyle.bold:
      case PhosphorIconsStyle.fill:
        return filled;
      case PhosphorIconsStyle.thin:
      case PhosphorIconsStyle.light:
      case PhosphorIconsStyle.regular:
      case PhosphorIconsStyle.duotone:
        return outlined;
    }
  }
}

class PhosphorIcons {
  static const pencilSimpleLine = _Icon(Icons.edit_outlined, Icons.edit);
  static const magnifyingGlass = _Icon(Icons.search, Icons.search);
  static const gearSix = _Icon(Icons.settings_outlined, Icons.settings);
  static const userCircle =
      _Icon(Icons.account_circle_outlined, Icons.account_circle);
  static const camera = _Icon(Icons.photo_camera_outlined, Icons.photo_camera);
  static const flame = _Icon(
      Icons.local_fire_department_outlined, Icons.local_fire_department);
  static const usersThree = _Icon(Icons.groups_outlined, Icons.groups);
  static const shareNetwork = _Icon(Icons.share_outlined, Icons.share);
  static const house = _Icon(Icons.home_outlined, Icons.home);
  static const cloudArrowUp =
      _Icon(Icons.cloud_upload_outlined, Icons.cloud_upload);
  static const keyboard = _Icon(Icons.keyboard_outlined, Icons.keyboard);
  static const bell =
      _Icon(Icons.notifications_none, Icons.notifications);
  static const thumbsUp = _Icon(Icons.thumb_up_outlined, Icons.thumb_up);
  static const question = _Icon(Icons.help_outline, Icons.help);
  static const signOut = _Icon(Icons.logout, Icons.logout);
}
