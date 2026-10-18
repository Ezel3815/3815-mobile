import 'package:upgrade/main.dart';

/// Remembers, per deck, the card a student stopped at, so reopening the deck
/// continues there instead of card 1. Stored on the device by card ID (not by
/// position), so it still works if cards are added, removed or reordered.
class ResumePosition {
  ResumePosition._();
  static String _key(int deckId) => 'resume_card_$deckId';

  static Future<void> save(int deckId, int cardId) =>
      sharedPref.setInt(_key(deckId), cardId);

  /// Finished the deck: next time starts from the first card again.
  static Future<void> clear(int deckId) => sharedPref.remove(_key(deckId));

  /// Index to start from in [cardIds] (0 when nothing is saved or the saved
  /// card no longer exists in this deck).
  static int indexFor(int deckId, List<int> cardIds) {
    final saved = sharedPref.getInt(_key(deckId));
    if (saved == null) return 0;
    final i = cardIds.indexOf(saved);
    return i < 0 ? 0 : i;
  }
}
