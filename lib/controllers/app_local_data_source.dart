import 'package:hive/hive.dart';
import 'package:upgrade/entity/card_entity.dart';
import 'package:upgrade/entity/deck_entity.dart';
import 'package:upgrade/entity/document_entity.dart';
import 'package:upgrade/hive_constants.dart';

abstract class AppLocalDataSource {
  Future<void> setDeckEntityToLocal(List<DeckEntity> data);

  Future<List<DeckEntity>> getDeckEntityFromLocal();

  Future<void> setMyDeckEntityToLocal(List<DeckEntity> data);

  Future<List<DeckEntity>> getMyDeckEntityFromLocal();

  Future<void> setDocumentEntityToLocal(List<DocumentEntity> data);

  Future<List<DocumentEntity>> getDocumentEntityFromLocal();

  Future<void> setCardEntityToLocal(List<CardEntity> data, int id);

  Future<List<CardEntity>> getCardEntityFromLocal(int id);
}

class AppLocalDataSourceImpl extends AppLocalDataSource {
  final deckBox = Hive.box<DeckEntity>(HiveConstants.deckBoxName);
  final myDeckBox = Hive.box<DeckEntity>(HiveConstants.myDeckBoxName);
  final documentBox = Hive.box<DocumentEntity>(HiveConstants.documentBoxName);
  final cardBox = Hive.box<CardEntity>(HiveConstants.cardBoxName);

  @override
  Future<List<DeckEntity>> getDeckEntityFromLocal() async {
    if (deckBox.values.isNotEmpty) {
      return deckBox.values.toList();
    }
    return [];
  }

  @override
  Future<void> setDeckEntityToLocal(List<DeckEntity> data) async {
    if (deckBox.isNotEmpty) {
      await deckBox.deleteAll(deckBox.keys);
    }
    await deckBox.addAll(data);
  }

  @override
  Future<List<DeckEntity>> getMyDeckEntityFromLocal() async {
    if (myDeckBox.values.isNotEmpty) {
      return myDeckBox.values.toList();
    }
    return [];
  }

  @override
  Future<void> setMyDeckEntityToLocal(List<DeckEntity> data) async {
    if (myDeckBox.isNotEmpty) {
      await myDeckBox.deleteAll(myDeckBox.keys);
    }
    await myDeckBox.addAll(data);
  }

  @override
  Future<List<DocumentEntity>> getDocumentEntityFromLocal() async {
    if (documentBox.values.isNotEmpty) {
      return documentBox.values.toList();
    }
    return [];
  }

  @override
  Future<void> setDocumentEntityToLocal(List<DocumentEntity> data) async {
    if (documentBox.isNotEmpty) {
      await documentBox.deleteAll(documentBox.keys);
    }
    await documentBox.addAll(data);
  }

  @override
  Future<List<CardEntity>> getCardEntityFromLocal(int id) async {
    if (cardBox.values.isNotEmpty) {
      return cardBox.values
          .map((e) => e)
          .where((element) => element.deckId == id)
          .toList();
    }
    return [];
  }

  @override
  Future<void> setCardEntityToLocal(List<CardEntity> data, int id) async {
    if (cardBox.isNotEmpty) {
      List keys = [];
      cardBox.toMap().forEach((key, value) {
        if (value.deckId == id) {
          keys.add(key);
        }
      });
      await cardBox.deleteAll(keys);
    }
    await cardBox.addAll(data);
  }
}
