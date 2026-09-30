import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:upgrade/entity/answer_result.dart';
import 'package:upgrade/resources.dart';

/// Fires right after a card is answered, using exactly what the backend
/// says actually happened (level up, streak saved, achievement
/// unlocked) — never guessed or simulated client-side.
void showCelebration(AnswerResult result) {
  if (!result.hasCelebration) return;

  if (result.leveledUp || result.newAchievements.isNotEmpty) {
    Get.dialog(_CelebrationDialog(result: result), barrierDismissible: true);
    return;
  }
  // Streak is no longer a snackbar: it has its own standalone window
  // (StreakRewardScreen), opened from the session result screen.
}

class _CelebrationDialog extends StatelessWidget {
  final AnswerResult result;
  const _CelebrationDialog({required this.result});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: AppColor.surfaceColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (result.leveledUp) ...[
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: AppColor.lightGreenColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    "${result.newLevel}",
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: AppColor.darkGreenColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Level Up!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColor.textPrimary,
                ),
              ),
              Text(
                "You reached Level ${result.newLevel}",
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColor.textSecondary,
                ),
              ),
              if (result.newAchievements.isNotEmpty)
                const SizedBox(height: 20),
            ],
            if (result.newAchievements.isNotEmpty) ...[
              if (!result.leveledUp) ...[
                const Icon(
                  Icons.emoji_events_rounded,
                  size: 56,
                  color: AppColor.warningColor,
                ),
                const SizedBox(height: 12),
                Text(
                  result.newAchievements.length == 1
                      ? "Achievement Unlocked!"
                      : "${result.newAchievements.length} Achievements Unlocked!",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
              ] else
                const Divider(height: 1),
              if (result.leveledUp) const SizedBox(height: 12),
              ...result.newAchievements.map(
                (title) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.emoji_events_rounded,
                        size: 18,
                        color: AppColor.warningColor,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColor.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.greenColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Continue",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
