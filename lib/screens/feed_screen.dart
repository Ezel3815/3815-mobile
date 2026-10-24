import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:upgrade/controllers/api_controller.dart';
import 'package:upgrade/controllers/feed_controller.dart';
import 'package:upgrade/controllers/main_controller.dart';
import 'package:upgrade/entity/feed_entity.dart';
import 'package:upgrade/main.dart';
import 'package:upgrade/resources.dart';
import 'package:upgrade/screens/app_drawer.dart';
import 'package:upgrade/widgets/app_image.dart';

// Premium redesign: a barely-visible hairline plus a soft shadow reads as
// "elevated surface" — the old 2px solid outline read as a wireframe.
const Color _cardBorder = Color(0xFFEAEFE0);
const List<BoxShadow> _cardShadow = [
  BoxShadow(color: Color(0x14243D2E), blurRadius: 22, offset: Offset(0, 8)),
];

/// On tablets the feed stays a comfortable reading column instead of
/// stretching edge to edge.
const double _feedMaxWidth = 680;

/// Posts that are addressed to ONE person only ("X followed you",
/// "X reminds you to study"): no celebrate button, no comments.
bool _isTargeted(String type) =>
    type == 'followed' || type == 'reminder' || type == 'challenge_invite';

/// Duolingo-style social feed: your activity + the people you follow.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  late final FeedController c = Get.find<FeedController>();

  @override
  void initState() {
    super.initState();
    c.load().then((_) => c.markSeen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: AppColor.scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      drawerEnableOpenDragGesture: false,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _feedMaxWidth),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => scaffoldKey.currentState?.openDrawer(),
                        child: Icon(Icons.dehaze,
                            size: 26, color: AppColor.textPrimary),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'الأخبار',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColor.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: Obx(_body)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (c.posts.isEmpty) {
      if (c.loading.value) {
        return Center(
          child: CircularProgressIndicator(color: AppColor.greenColor),
        );
      }
      if (c.failed.value) {
        return _Message(
          icon: Icons.cloud_off_rounded,
          title: 'تعذّر تحميل الأخبار',
          actionLabel: 'إعادة المحاولة',
          onAction: c.load,
        );
      }
      // Empty state is also pull-to-refresh, so a new friend's activity
      // can be picked up without leaving the screen.
      return RefreshIndicator(
        color: AppColor.greenColor,
        onRefresh: c.load,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: constraints.maxHeight,
              child: _Message(
                icon: Icons.notifications_none_rounded,
                title: 'لا توجد أخبار بعد',
                subtitle:
                    'أنهِ فصلاً أو افتح إنجازاً، وتابع أصدقاءك لترى نشاطهم هنا',
                actionLabel: 'ابحث عن أصدقاء',
                onAction: () => Get.toNamed(AppRoutes.searchUsersRoute),
              ),
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColor.greenColor,
      onRefresh: c.load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
        itemCount: c.posts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, i) => _PostCard(post: c.posts[i], controller: c),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  const _Message({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColor.disabledColor),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColor.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: AppColor.textSecondary, height: 1.4),
              ),
            ],
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColor.greenColor,
                side: BorderSide(color: AppColor.greenColor),
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Post card ─────────────────────────

class _PostCard extends StatelessWidget {
  final FeedPost post;
  final FeedController controller;
  const _PostCard({required this.post, required this.controller});

  void _openProfile() =>
      Get.toNamed(AppRoutes.viewProfileRoute, arguments: post.userId);

  void _openComments() {
    Get.bottomSheet(
      _CommentsSheet(post: post, controller: controller),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  /// The text shown for the post. A reminder is built here (the server
  /// only says "a reminder from <user>"), everything else comes from the
  /// post itself.
  String get _message {
    if (post.type == 'reminder') {
      return 'ذكّرك ${post.userName} بالمذاكرة اليوم 📚';
    }
    if (post.type == 'challenge_invite') {
      return 'دعاك ${post.userName} لتحدي الأصدقاء هذا الأسبوع 🏆';
    }
    return post.message;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cardBorder, width: 1),
        boxShadow: _cardShadow,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: _openProfile,
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              children: [
                                _FeedAvatar(
                                    name: post.userName,
                                    photo: post.userPhoto,
                                    size: 46),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        post.mine ? 'أنت' : post.userName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: AppColor.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        post.timeAgo,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: AppColor.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _message,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColor.textPrimary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _PostBadge(type: post.type),
                  ],
                ),
                const SizedBox(height: 16),
                _actionRow(),
              ],
            ),
          ),
          if (!_isTargeted(post.type)) ...[
            Divider(height: 1, thickness: 1, color: _cardBorder),
            InkWell(
              onTap: _openComments,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(22)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        post.comments > 0
                            ? 'عرض ${post.comments} ${post.comments == 1 ? 'تعليق' : 'تعليقات'}'
                            : 'أضف تعليقاً...',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: post.comments > 0
                              ? AppColor.greenColor
                              : AppColor.disabledColor,
                          fontWeight: post.comments > 0
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(Icons.chat_bubble_outline_rounded,
                        size: 17,
                        color: AppColor.disabledColor.withOpacity(0.7)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// One merged pill: icon + label + count together, instead of a separate
  /// outlined button next to a detached bordered circle — fewer competing
  /// shapes reads calmer and more deliberate.
  Widget _actionRow() {
    final celebrated = post.celebrated;
    if (post.type == 'reminder') {
      // "X reminds you to study": jump straight to the learning path.
      return _Pill(
        onTap: () => Get.find<MainController>().onChangePage(0),
        icon: Icons.play_arrow_rounded,
        label: 'ابدأ المذاكرة الآن',
        filled: true,
        fullWidth: true,
      );
    }
    if (post.type == 'challenge_invite') {
      // "X invited you to the friends challenge": open the Quests tab.
      return _Pill(
        onTap: () => Get.find<MainController>().onChangePage(2),
        icon: Icons.emoji_events_rounded,
        label: 'افتح التحدي',
        filled: true,
        fullWidth: true,
      );
    }
    if (post.type == 'followed') {
      // "X followed you": open their profile (where you can follow back).
      return _Pill(
        onTap: _openProfile,
        icon: Icons.person_rounded,
        label: 'عرض الملف الشخصي',
        filled: false,
        fullWidth: true,
      );
    }
    if (post.mine) {
      return Row(
        children: [
          Expanded(
            child: _Pill(
              onTap: () => Share.share(
                  '${post.message}\nتابعني على MOZAIK: https://soalix-backend.onrender.com'),
              icon: Icons.ios_share_rounded,
              label: 'مشاركة',
              filled: false,
            ),
          ),
          if (post.celebrations > 0) ...[
            const SizedBox(width: 10),
            _CelebrationCount(count: post.celebrations),
          ],
        ],
      );
    }
    return _Pill(
      onTap: () => controller.toggleCelebrate(post),
      icon: null,
      emoji: '🎉',
      label: celebrated
          ? (post.celebrations > 0
              ? 'احتفلت · ${post.celebrations}'
              : 'احتفلت')
          : (post.celebrations > 0
              ? 'احتفل · ${post.celebrations}'
              : 'احتفل'),
      filled: celebrated,
      fullWidth: true,
    );
  }
}

/// A single flat pill — the one recurring control shape for this card,
/// used for both "celebrate" and "share" so the card reads as one
/// consistent system rather than a mix of button styles.
class _Pill extends StatelessWidget {
  final VoidCallback onTap;
  final IconData? icon;
  final String? emoji;
  final String label;
  final bool filled;
  final bool fullWidth;
  const _Pill({
    required this.onTap,
    this.icon,
    this.emoji,
    required this.label,
    required this.filled,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : AppColor.textPrimary;
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 46,
      child: Material(
        color: filled
            ? AppColor.greenColor
            : AppColor.lightGreenColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (emoji != null) ...[
                  Text(emoji!, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                ],
                if (icon != null) ...[
                  Icon(icon, size: 17, color: fg),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800, color: fg),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small celebration-count readout for the owner's own post — a quiet
/// number, not another bordered shape competing with the share pill.
class _CelebrationCount extends StatelessWidget {
  final int count;
  const _CelebrationCount({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColor.lightGreenColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 15)),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColor.darkGreenColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Illustration for a post, by event type.
class _PostBadge extends StatelessWidget {
  final String type;
  const _PostBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    late final List<Color> colors;
    late final IconData icon;
    switch (type) {
      case 'followed':
        colors = const [Color(0xFF6CC3D5), Color(0xFF3C9DB8)];
        icon = Icons.person_add_alt_1_rounded;
        break;
      case 'challenge_invite':
        colors = const [Color(0xFFFFD25A), Color(0xFFF0A020)];
        icon = Icons.groups_rounded;
        break;
      case 'reminder':
        colors = const [Color(0xFFFF9C7A), Color(0xFFE8663D)];
        icon = Icons.notifications_active_rounded;
        break;
      case 'achievement_unlocked':
        colors = const [Color(0xFFFFD25A), Color(0xFFF0A020)];
        icon = Icons.emoji_events_rounded;
        break;
      case 'level_up':
        colors = const [Color(0xFFA89BD1), Color(0xFF7C6FA8)];
        icon = Icons.auto_awesome_rounded;
        break;
      default: // chapter_completed & others
        colors = [AppColor.freshGreenColor, AppColor.greenColor];
        icon = Icons.menu_book_rounded;
    }
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.last.withOpacity(0.28),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, size: 26, color: Colors.white),
    );
  }
}

class _FeedAvatar extends StatelessWidget {
  final String name;
  final String? photo;
  final double size;
  const _FeedAvatar({required this.name, this.photo, required this.size});

  @override
  Widget build(BuildContext context) {
    final p = photo;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColor.lightGreenColor,
      ),
      child: ClipOval(
        child: (p != null && p.isNotEmpty)
            ? AppImage(image: p, width: size, height: size, fit: BoxFit.cover)
            : Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.w800,
                    color: AppColor.darkGreenColor,
                  ),
                ),
              ),
      ),
    );
  }
}

// ───────────────────────── Comments sheet ─────────────────────────

class _CommentsSheet extends StatefulWidget {
  final FeedPost post;
  final FeedController controller;
  const _CommentsSheet({required this.post, required this.controller});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  // A request that hangs (e.g. the free server waking up) must never leave
  // the sheet spinning forever — after this it shows an error instead.
  static const Duration _timeout = Duration(seconds: 25);

  final TextEditingController input = TextEditingController();
  final ScrollController scroll = ScrollController();
  List<FeedComment>? comments;
  bool failed = false;
  bool sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    List<FeedComment>? data;
    try {
      data = await ApiController.getFeedComments(widget.post.id)
          .timeout(_timeout);
    } catch (_) {
      data = null;
    }
    if (!mounted) return;
    setState(() {
      comments = data;
      failed = data == null;
    });
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scroll.hasClients) return;
      scroll.animateTo(
        scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = input.text.trim();
    if (text.isEmpty || sending) return;
    setState(() => sending = true);

    FeedComment? created;
    try {
      created = await ApiController.addFeedComment(widget.post.id, text)
          .timeout(_timeout);
    } catch (_) {
      created = null;
    }
    if (!mounted) return;

    setState(() {
      sending = false;
      if (created != null) {
        comments = [...(comments ?? []), created];
        input.clear();
        widget.post.comments += 1;
      }
    });

    if (created != null) {
      widget.controller.posts.refresh();
      _scrollToEnd();
    } else {
      // Keep the typed text so nothing is lost, and say what happened.
      Get.snackbar(
        'تعذّر إرسال التعليق',
        'تحقق من الاتصال وحاول مرة أخرى',
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(12),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    // Some phones already SHRINK the whole app window when the keyboard opens
    // (Android "adjustResize") and ALSO report the keyboard as a view inset.
    // Using both counted the keyboard twice: the sheet was squeezed and then
    // lifted a second keyboard-height up, leaving a gap above the keyboard.
    // If the window is already smaller than the screen by the keyboard's
    // height, don't lift the sheet again.
    final view = View.of(context);
    final dpr = view.devicePixelRatio;
    final windowHeight = view.physicalSize.height / dpr;
    final screenHeight = view.display.size.height / dpr;
    final keyboard = media.viewInsets.bottom;
    final windowAlreadyShrunk =
        keyboard > 0 && windowHeight + keyboard <= screenHeight + 4;
    final lift = windowAlreadyShrunk ? 0.0 : keyboard;

    // Height is worked out from the space that is really left, so the sheet
    // never gets taller than the screen when the keyboard is open.
    final available = media.size.height - lift - media.padding.top;
    // min(...) keeps the height CONTINUOUS while the keyboard slides up.
    final sheetHeight = math.min(media.size.height * 0.68, available * 0.96);

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _feedMaxWidth),
        child: Padding(
          padding: EdgeInsets.only(bottom: lift),
          child: Container(
            height: sheetHeight,
            decoration: BoxDecoration(
              color: AppColor.scaffoldBackgroundColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _cardBorder,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'التعليقات',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColor.textPrimary,
                    ),
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: _cardBorder),
                Expanded(child: _list()),
                const Divider(height: 1, thickness: 1, color: _cardBorder),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: input,
                            maxLength: 300,
                            minLines: 1,
                            maxLines: 3,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: 'أضف تعليقاً...',
                              filled: true,
                              fillColor: AppColor.surfaceColor,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(
                                    color: _cardBorder, width: 1.4),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                    color: AppColor.greenColor, width: 2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _send,
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColor.greenColor,
                              shape: BoxShape.circle,
                            ),
                            child: sending
                                ? const Padding(
                                    padding: EdgeInsets.all(14),
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white),
                                  )
                                : const Icon(Icons.send_rounded,
                                    size: 20, color: Colors.white),
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
      ),
    );
  }

  Widget _list() {
    if (failed) {
      return Center(
        child: TextButton(
          onPressed: () {
            setState(() {
              failed = false;
              comments = null;
            });
            _load();
          },
          child: const Text('تعذّر تحميل التعليقات، إعادة المحاولة'),
        ),
      );
    }
    final list = comments;
    if (list == null) {
      return Center(
        child: CircularProgressIndicator(color: AppColor.greenColor),
      );
    }
    if (list.isEmpty) {
      return Center(
        child: Text(
          'كن أول من يعلّق',
          style: TextStyle(fontSize: 14, color: AppColor.textSecondary),
        ),
      );
    }
    return ListView.separated(
      controller: scroll,
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) {
        final cm = list[i];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FeedAvatar(name: cm.userName, photo: cm.userPhoto, size: 38),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          cm.userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColor.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        cm.timeAgo,
                        style: TextStyle(
                            fontSize: 11.5, color: AppColor.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    cm.text,
                    style: TextStyle(
                        fontSize: 14.5,
                        color: AppColor.textPrimary,
                        height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
